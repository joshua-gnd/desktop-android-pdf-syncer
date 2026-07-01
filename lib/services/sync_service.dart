import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:desktop_android_pdf_syncer/services/storage_service.dart';

class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final StorageService _storageService = StorageService();

  /// Uploads a locally modified PDF back to Google Drive, overwriting the remote version.
  /// Uses a multi-part media upload stream for memory efficiency.
  Future<bool> uploadLocalUpdate({
    required drive.DriveApi driveApi,
    required String fileId,
    required String fileName,
  }) async {
    try {
      debugPrint('Preparing upstream sync pipeline for: $fileName (ID: $fileId)');

      // 1. Fetch the physical file pointer from local storage
      final File localFile = await _storageService.getCachedFile(fileName);
      if (!await localFile.exists()) {
        debugPrint('Sync aborted: Local file does not exist on disk.');
        return false;
      }

      // 2. Prepare the metadata declaration
      final drive.File remoteMetadata = drive.File()
        ..name = fileName
        ..modifiedTime = DateTime.now().toUtc();

      // 3. Create the multi-part upload media stream from the local file
      final int fileLength = await localFile.length();
      final Stream<List<int>> fileByteStream = localFile.openRead();
      final drive.Media uploadMedia = drive.Media(fileByteStream, fileLength);

      debugPrint('Streaming bytes upstream (${(fileLength / 1024).toStringAsFixed(2)} KB)...');

      // 4. Execute the patch operation on Google Drive
      final drive.File updatedFile = await driveApi.files.update(
        remoteMetadata,
        fileId,
        uploadMedia: uploadMedia,
      );

      debugPrint('Upstream synchronization complete. Remote ID: ${updatedFile.id}');
      return true;
    } catch (e) {
      debugPrint('Upstream pipeline storage failure: $e');
      return false;
    }
  }

  /// Optional Helper: Scans a file on disk and checks if its modification time
  /// is newer than the remote metadata timestamp.
  Future<bool> isLocalNewer(String fileName, DateTime remoteModifiedTime) async {
    try {
      final File localFile = await _storageService.getCachedFile(fileName);
      if (!await localFile.exists()) return false;

      final DateTime localModifiedTime = await localFile.lastModified();
      return localModifiedTime.isAfter(remoteModifiedTime);
    } catch (e) {
      debugPrint('Error inspecting file timestamps: $e');
      return false;
    }
  }
}