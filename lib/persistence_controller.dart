import 'dart:async';
import 'dart:io';
import 'package:easy_wallet/model/subscription.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:icloud_storage/icloud_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:googleapis/drive/v3.dart' as drive;

import 'cloud/auth_client.dart';

class PersistenceController {
  static PersistenceController instance = PersistenceController._internal();

  PersistenceController._internal();

  Database? _database;
  String icloudContainerId = 'iCloud.io.github.coho04.easywallet';
  String relativePath = 'easywallet/subscriptions_backup.json';
  String localFileName = 'subscriptions_backup.json';

  final GoogleSignIn googleSignIn = GoogleSignIn(
    scopes: [
      'https://www.googleapis.com/auth/drive.appdata',
      'https://www.googleapis.com/auth/drive.file',
      'https://www.googleapis.com/auth/drive'
    ],
    signInOption: SignInOption.standard,
    clientId: defaultTargetPlatform == TargetPlatform.iOS
        ? '1080526043884-uvf1g98assgkb6et168nlt9bv226afro.apps.googleusercontent.com'
        : '1080526043884-b1ectocrn53qqil0dihs6sr86s0qndeo.apps.googleusercontent.com',
  );

  Future<Database> get database async {
    if (kIsWeb) {
      throw UnsupportedError("Database is not supported on the web");
    }
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'easywallet.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) {
        return db.execute(
          '''
          CREATE TABLE subscriptions(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT,
            amount REAL,
            date TEXT,
            isPaused INTEGER,
            isPinned INTEGER,
            notes TEXT,
            remembercycle TEXT,
            repeating INTEGER,
            repeatPattern TEXT,
            timestamp TEXT,
            url TEXT
          )
          ''',
        );
      },
    );
  }

  Future<void> saveSubscription(Subscription subscription) async {
    if (kIsWeb) {
      throw UnsupportedError("Database is not supported on the web");
    }
    final db = await database;
    if (subscription.id == null) {
      await db.insert('subscriptions', subscription.toJson(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    } else {
      await db.update(
        'subscriptions',
        subscription.toJson(),
        where: 'id = ?',
        whereArgs: [subscription.id],
      );
    }
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('syncWithICloud') ?? false) {
      await syncToICloud();
    }
    if (prefs.getBool('syncWithGoogleDrive') ?? false) {
      await syncToGoogleDrive();
    }
  }

  Future<void> deleteSubscription(Subscription subscription) async {
    if (kIsWeb) {
      throw UnsupportedError("Database is not supported on the web");
    }
    final db = await database;
    await db.delete(
      'subscriptions',
      where: 'id = ?',
      whereArgs: [subscription.id],
    );
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('syncWithICloud') ?? false) {
      await syncToICloud();
    }
    if (prefs.getBool('syncWithGoogleDrive') ?? false) {
      await syncToGoogleDrive();
    }
  }

  Future<List<Subscription>> getAllSubscriptions() async {
    if (kIsWeb) {
      throw UnsupportedError("Database is not supported on the web");
    }
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('subscriptions');
    return List.generate(maps.length, (i) {
      return Subscription.fromJson(maps[i]);
    });
  }

  Future<void> syncToICloud() async {
    try {
      final List<Subscription> subscriptions = await getAllSubscriptions();
      if (subscriptions.isEmpty) {
        debugPrint("[${DateTime.now()}] No data to sync to iCloud");
        return;
      }
      final String json =
          jsonEncode(subscriptions.map((s) => s.toJson()).toList());

      final directory = await getApplicationDocumentsDirectory();
      final File file = File('${directory.path}/$localFileName');
      await file.writeAsString(json);

      await ICloudStorage.upload(
        containerId: icloudContainerId,
        filePath: file.path,
        destinationRelativePath: relativePath,
        onProgress: (stream) {
          stream.listen(
            (progress) => debugPrint(
                '[${DateTime.now()}] Upload File Progress: $progress'),
            onDone: () => debugPrint('[${DateTime.now()}] Upload File Done'),
            onError: (err) =>
                debugPrint('[${DateTime.now()}] Upload File Error: $err'),
            cancelOnError: true,
          );
        },
      );
    } catch (e) {
      debugPrint("[${DateTime.now()}] Error syncing to iCloud: $e");
    }
  }

  Future<void> syncFromICloud() async {
    final directory = await getApplicationDocumentsDirectory();
    final localFilePath = join(directory.path, localFileName);
    try {
      await ICloudStorage.download(
        containerId: icloudContainerId,
        relativePath: relativePath,
        destinationFilePath: localFilePath,
        onProgress: (stream) {
          stream.listen(
            (progress) => debugPrint(
                '[${DateTime.now()}] Download File Progress: $progress'),
            onDone: () async {
              await verifyAndReadFile(localFilePath);
            },
            onError: (err) =>
                debugPrint('[${DateTime.now()}] Download File Error: $err'),
            cancelOnError: true,
          );
        },
      );
    } catch (e) {
      debugPrint("[${DateTime.now()}] Error syncing from iCloud: $e");
    }
  }

  Future<drive.File?> getOrCreateFile(
      String fileName, drive.DriveApi driveApi) async {
    final fileList = await driveApi.files.list(
      q: "name = '$fileName' and trashed = false",
      spaces: 'drive',
      $fields: 'files(id, name)',
    );

    if (fileList.files != null && fileList.files!.isNotEmpty) {
      return fileList.files!.first;
    } else {
      var fileMetadata = drive.File();
      fileMetadata.name = fileName;
      drive.File file = await driveApi.files.create(fileMetadata);
      return file;
    }
  }

  Future<void> syncToGoogleDrive() async {
    try {
      final GoogleSignInAccount? account = await googleSignIn.signInSilently();
      if (account == null) {
        debugPrint('Google Drive login failed');
        return;
      }

      final authHeaders = await account.authHeaders;
      final authenticateClient = AuthClient(authHeaders, http.Client());
      final driveApi = drive.DriveApi(authenticateClient);
      const fileName = 'subscriptions.json';
      final file = await getOrCreateFile(fileName, driveApi);

      if (file != null) {
        debugPrint('File ID: ${file.id}, File Name: ${file.name}');
        final List<Subscription> subscriptions = await getAllSubscriptions();
        if (subscriptions.isEmpty) {
          debugPrint("[${DateTime.now()}] No data to sync to Google Drive");
          return;
        }
        final String json =
            jsonEncode(subscriptions.map((s) => s.toJson()).toList());

        final directory = await getApplicationDocumentsDirectory();
        final localFilePath = File('${directory.path}/$localFileName');
        await localFilePath.writeAsString(json);

        drive.Media media =
            drive.Media(localFilePath.openRead(), localFilePath.lengthSync());
        final drive.File updatedFile = await driveApi.files.update(
          drive.File(),
          file.id!,
          uploadMedia: media,
        );
        debugPrint('File uploaded to Google Drive: ${updatedFile.name}, ID: ${updatedFile.id}');
      }
    } catch (e) {
      debugPrint("[${DateTime.now()}] Error syncing to Google Drive: $e");
    }
  }

  Future<void> syncFromGoogleDrive() async {
    try {
      final GoogleSignInAccount? account = await googleSignIn.signInSilently();
      if (account == null) {
        debugPrint('Google Drive login failed');
        return;
      }
      final authHeaders = await account.authHeaders;
      final authenticateClient = AuthClient(authHeaders, http.Client());
      final driveApi = drive.DriveApi(authenticateClient);

      const String fileName = 'subscriptions.json';
      final fileList = await driveApi.files.list(
        q: "name = '$fileName' and trashed = false",
        spaces: 'drive',
        $fields: 'files(id, name)',
      );

      if (fileList.files == null || fileList.files!.isEmpty) {
        debugPrint('No file found');
        return;
      }

      final file = fileList.files!.first;
      debugPrint('File found: ${file.name}, ID: ${file.id}');

      final media = await driveApi.files.get(file.id!,
          downloadOptions: drive.DownloadOptions.fullMedia) as drive.Media;
      final directory = await getApplicationDocumentsDirectory();
      final localFilePath = join(directory.path, fileName);
      debugPrint('File downloaded and saved to: $localFilePath');

      final fileStream = File(localFilePath).openWrite();
      await media.stream.pipe(fileStream);
      fileStream.close();
      await verifyAndReadFile(localFilePath);
      authenticateClient.close();
    } catch (e) {
      debugPrint('Error syncing from Google Drive: $e');
    }
  }

  Future<void> verifyAndReadFile(String localFilePath) async {
    try {
      final File file = File(localFilePath);
      if (!file.existsSync()) {
        debugPrint('File does not exist');
        return;
      }

      final int fileSize = await file.length();
      if (fileSize == 0) {
        debugPrint('File is empty');
        return;
      }

      final String json = await file.readAsString();
      if (json.isNotEmpty) {
        final List<dynamic> data = jsonDecode(json);
        final db = await database;
        debugPrint('Data read from file');
        for (var item in data) {
          await db.insert('subscriptions', Map<String, dynamic>.from(item),
              conflictAlgorithm: ConflictAlgorithm.replace);
        }
        debugPrint('Data read from file and saved to database');
        await file.delete();
      }
    } catch (e) {
      debugPrint("[${DateTime.now()}] Error reading file from iCloud: $e");
    }
  }
}
