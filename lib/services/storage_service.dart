import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:googleapis/drive/v3.dart' as drive;

class StorageService {
  // Singleton pattern for centralized file management
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  /// Gets the platform-specific safe documents directory path
  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  /// Creates a local File reference mapped to a specific filename
  Future<File> _getLocalFile(String fileName) async {
    final path = await _localPath;
    return File('$path/$fileName');
  }

  /// Downloads a file from Google Drive and saves it to local disk
  /// Returns the local File instance if successful, or null if it fails
  Future<File?> downloadDriveFile({
    required drive.DriveApi driveApi,
    required String fileId,
    required String fileName,
  }) async {
    try {
      debugPrint('Starting pipeline download for: $fileName (ID: $fileId)');

      // 1. Request the file from Drive using the media download media option
      final drive.Media response = await driveApi.files.get(
        fileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      // 2. Resolve the local system path destination
      final File localFile = await _getLocalFile(fileName);

      // 3. Pipe the incoming web byte stream directly into physical storage
      final IOSink fileSink = localFile.openWrite();
      await response.stream.pipe(fileSink);
      await fileSink.close();

      debugPrint('Successfully cached file locally at: ${localFile.path}');
      return localFile;
    } catch (e) {
      debugPrint('Pipeline storage failure during download: $e');
      return null;
    }
  }

  /// Helper to check if a specific PDF is already cached locally
  Future<bool> isFileCached(String fileName) async {
    final File file = await _getLocalFile(fileName);
    return await file.exists();
  }

  /// Helper to fetch the local file object directly if it exists
  Future<File> getCachedFile(String fileName) async {
    return await _getLocalFile(fileName);
  }
}