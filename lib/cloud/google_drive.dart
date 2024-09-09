import 'dart:convert';
import 'dart:io';

import 'package:easy_wallet/cloud/auth_client.dart';
import 'package:easy_wallet/cloud/cloud.dart';
import 'package:easy_wallet/model/subscription.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:easy_wallet/model/category.dart' as category;

class GoogleDrive extends Cloud {
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

  GoogleDrive({required super.database});

  Future<void> syncTo(List<Subscription> subscriptions, List<category.Category> categories) async {
    final GoogleSignInAccount? account = await googleSignIn.signInSilently();
    if (account == null) {
      debugPrint('Google Drive login failed');
      return;
    }

    final authHeaders = await account.authHeaders;
    final authenticateClient = AuthClient(authHeaders, http.Client());
    final driveApi = drive.DriveApi(authenticateClient);
    const folderName = 'EasyWallet';

    String folderId = await getOrCreateFolder(driveApi, folderName);
    await uploadDataToDrive(
        driveApi, folderId, 'subscriptions.json', jsonEncode(subscriptions.map((s) => s.toJson()).toList()));
    await uploadDataToDrive(
        driveApi, folderId, 'categories.json', jsonEncode(categories.map((c) => c.toJson()).toList()));

    authenticateClient.close();
  }

  Future<String> getOrCreateFolder(drive.DriveApi driveApi, String folderName) async {
    final folderQuery = await driveApi.files.list(
      q: "name = '$folderName' and mimeType = 'application/vnd.google-apps.folder' and trashed = false",
      spaces: 'drive',
      $fields: 'files(id, name)',
    );

    if (folderQuery.files == null || folderQuery.files!.isEmpty) {
      var folderMetadata = drive.File()
        ..name = folderName
        ..mimeType = 'application/vnd.google-apps.folder';
      final folder = await driveApi.files.create(folderMetadata);
      return folder.id!;
    } else {
      return folderQuery.files!.first.id!;
    }
  }

  Future<void> uploadDataToDrive(drive.DriveApi driveApi, String folderId, String fileName, String jsonData) async {
    final fileQuery = await driveApi.files.list(
      q: "'$folderId' in parents and name = '$fileName' and trashed = false",
      spaces: 'drive',
      $fields: 'files(id, name)',
    );

    drive.File? file;
    if (fileQuery.files == null || fileQuery.files!.isEmpty) {
      var fileMetadata = drive.File()..name = fileName..parents = [folderId];
      file = await driveApi.files.create(fileMetadata);
    } else {
      file = fileQuery.files!.first;
    }

    final media = drive.Media(ByteStream.fromBytes(utf8.encode(jsonData)), utf8.encode(jsonData).length);
    await driveApi.files.update(drive.File(), file.id!, uploadMedia: media);
  }

  Future<void> syncFrom() async {
    try {
      final GoogleSignInAccount? account = await googleSignIn.signInSilently();
      if (account == null) {
        debugPrint('Google Drive login failed');
        return;
      }
      final authHeaders = await account.authHeaders;
      final authenticateClient = AuthClient(authHeaders, http.Client());
      final driveApi = drive.DriveApi(authenticateClient);

      const String folderName = 'EasyWallet';
      final folderQuery = await driveApi.files.list(
        q: "name = '$folderName' and mimeType = 'application/vnd.google-apps.folder' and trashed = false",
        spaces: 'drive',
        $fields: 'files(id, name)',
      );

      String folderId;
      if (folderQuery.files == null || folderQuery.files!.isEmpty) {
        var folderMetadata = drive.File()
          ..name = folderName
          ..mimeType = 'application/vnd.google-apps.folder';
        final folder = await driveApi.files.create(folderMetadata);
        folderId = folder.id!;
      } else {
        folderId = folderQuery.files!.first.id!;
      }
      await downloadAndProcessFile(driveApi, folderId, 'subscriptions.json');
      await downloadAndProcessFile(driveApi, folderId, 'categories.json');

      authenticateClient.close();
    } catch (e) {
      debugPrint('Error syncing from Google Drive: $e');
    }
  }

  Future<void> downloadAndProcessFile(drive.DriveApi driveApi, String folderId, String fileName) async {
    final fileQuery = await driveApi.files.list(
      q: "'$folderId' in parents and name = '$fileName' and trashed = false",
      spaces: 'drive',
      $fields: 'files(id, name)',
    );

    if (fileQuery.files == null || fileQuery.files!.isEmpty) {
      return;
    }

    final file = fileQuery.files!.first;
    final media = await driveApi.files.get(file.id!, downloadOptions: drive.DownloadOptions.fullMedia) as drive.Media;

    final directory = await getApplicationDocumentsDirectory();
    final localFilePath = join(directory.path, fileName);

    final fileStream = File(localFilePath).openWrite();
    await media.stream.pipe(fileStream);
    fileStream.close();

    await verifyAndReadFile(localFilePath, fileName);
  }
}
