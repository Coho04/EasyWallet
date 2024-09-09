import 'dart:convert';
import 'dart:io';

import 'package:easy_wallet/cloud/cloud.dart';
import 'package:easy_wallet/model/subscription.dart';
import 'package:easy_wallet/model/category.dart';
import 'package:flutter/cupertino.dart';
import 'package:icloud_storage/icloud_storage.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class ICloud extends Cloud {

  final String subscriptionRelativePath = 'subscriptions.json';
  final String categoryRelativePath = 'categories.json';

  ICloud({required super.database});

  Future<void> syncTo(List<Subscription> subscriptions, List<Category> categories) async {
    await _uploadData(subscriptions.map((s) => s.toJson()).toList(), subscriptionRelativePath);
    await _uploadData(categories.map((c) => c.toJson()).toList(), categoryRelativePath);
  }

  Future<void> syncFrom() async {
    await _downloadData(subscriptionRelativePath);
    await _downloadData(categoryRelativePath);
  }

  Future<void> _uploadData(List<Map<String, dynamic>> data, String relativePath) async {
    if (data.isEmpty) {
      debugPrint("[${DateTime.now()}] No data to sync to iCloud for $relativePath");
      return;
    }
    final String json = jsonEncode(data);
    final directory = await getApplicationDocumentsDirectory();
    final File file = File(join(directory.path, relativePath));

    await file.writeAsString(json);

    await ICloudStorage.upload(
      containerId: icloudContainerId,
      filePath: file.path,
      destinationRelativePath: relativePath,
      onProgress: (stream) {
        stream.listen(
              (progress) => debugPrint('[${DateTime.now()}] Upload File Progress: $progress'),
          onDone: () => debugPrint('[${DateTime.now()}] Upload File Done'),
          onError: (err) => debugPrint('[${DateTime.now()}] Upload File Error: $err'),
          cancelOnError: true,
        );
      },
    );
  }

  Future<void> _downloadData(String relativePath) async {
    final directory = await getApplicationDocumentsDirectory();
    final localFilePath = join(directory.path, relativePath);

    try {
      await ICloudStorage.download(
        containerId: icloudContainerId,
        relativePath: relativePath,
        destinationFilePath: localFilePath,
        onProgress: (stream) {
          stream.listen(
                (progress) => debugPrint('[${DateTime.now()}] Download File Progress: $progress'),
            onDone: () async {
              debugPrint('[${DateTime.now()}] Download File Done');
              await verifyAndReadFile(localFilePath, relativePath);
            },
            onError: (err) => debugPrint('[${DateTime.now()}] Download File Error: $err'),
            cancelOnError: true,
          );
        },
      );
    } catch (e) {
      debugPrint("[${DateTime.now()}] Error syncing from iCloud: $e");
    }
  }
}
