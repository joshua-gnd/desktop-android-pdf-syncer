import 'dart:io';
import 'package:flutter/material.dart';
import 'package:desktop_android_pdf_syncer/services/auth_service.dart';
import 'package:desktop_android_pdf_syncer/services/storage_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _fileIdController = TextEditingController();
  bool _isDownloading = false;
  String _downloadStatus = '';

  @override
  void dispose() {
    _fileIdController.dispose();
    super.dispose();
  }

  void _triggerDownload() async {
    final authService = AuthService();
    final api = authService.driveApi;
    final fileId = _fileIdController.text.trim();

    if (api == null) {
      setState(() => _downloadStatus = 'Error: Drive API is not initialized.');
      return;
    }

    if (fileId.isEmpty) {
      setState(() => _downloadStatus = 'Please enter a valid Google Drive File ID.');
      return;
    }

    setState(() {
      _isDownloading = true;
      _downloadStatus = 'Streaming bytes from cloud storage...';
    });

    // Hardcode a default name for manual verification testing
    final File? cachedFile = await StorageService().downloadDriveFile(
      driveApi: api,
      fileId: fileId,
      fileName: 'synced_document.pdf',
    );

    setState(() {
      _isDownloading = false;
      if (cachedFile != null) {
        _downloadStatus = 'Success! File saved physically at:\n${cachedFile.path}';
      } else {
        _downloadStatus = 'Download failed. Ensure the File ID matches and your app has access.';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final user = authService.currentUser;
    final apiReady = authService.driveApi != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Pipeline Dashboard'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign Out',
            onPressed: () async => await authService.signOut(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome, ${user?.displayName ?? "User"}',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Authenticated as: ${user?.email ?? "Unknown"}',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey,
                  ),
            ),
            const Divider(height: 40, thickness: 1),
            
            // Phase 2 Pipeline Status Indicator
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: apiReady 
                    ? Colors.green.withValues(alpha: 0.1) 
                    : Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: apiReady ? Colors.green : Colors.red,
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    apiReady ? Icons.check_circle : Icons.error,
                    color: apiReady ? Colors.green : Colors.red,
                    size: 28,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      apiReady 
                          ? 'Drive API Client: Active & Authorized' 
                          : 'Drive API Client: Missing Scope Token',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: apiReady ? Colors.green : Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            // Step 4 Download Pipeline Test UI
            Text(
              'Test Download Engine Pipeline',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _fileIdController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Google Drive File ID',
                hintText: 'Enter a file ID created/opened by this app',
              ),
              enabled: apiReady && !_isDownloading,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.cloud_download),
                label: const Text('Download and Cache File'),
                onPressed: (apiReady && !_isDownloading) ? _triggerDownload : null,
              ),
            ),
            const SizedBox(height: 20),
            if (_downloadStatus.isNotEmpty)
              Text(
                _downloadStatus,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: _downloadStatus.startsWith('Success') ? Colors.green : Colors.black87,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
