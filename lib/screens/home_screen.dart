import 'dart:io';
import 'package:flutter/material.dart';
import 'package:desktop_android_pdf_syncer/services/auth_service.dart';
import 'package:desktop_android_pdf_syncer/services/storage_service.dart';
import 'package:desktop_android_pdf_syncer/screens/pdf_viewer_screen.dart';
import 'package:desktop_android_pdf_syncer/services/sync_service.dart';
import 'package:googleapis/drive/v3.dart' as drive;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final StorageService _storageService = StorageService();

  List<drive.File> _remoteFiles = [];
  Map<String, bool> _cacheRegistry = {}; // Tracks: {fileName: true/false}
  final Map<String, bool> _syncingTracker =
      {}; // Tracks downing states per file ID

  bool _isLoadingList = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadSyncDashboard();
  }

  /// Master coordinator to synchronize UI view state with remote and local files
  Future<void> _loadSyncDashboard() async {
    final api = AuthService().driveApi;
    if (api == null) {
      setState(() => _errorMessage = 'Authentication client uninitialized.');
      return;
    }

    setState(() {
      _isLoadingList = true;
      _errorMessage = '';
    });

    // 1. Fetch remote changes from cloud discovery index
    final files = await _storageService.fetchDrivePdfFiles(driveApi: api);

    // 2. Scan physical system disk parameters sequentially to verify local presence
    final Map<String, bool> updatedCacheRegistry = {};
    for (var file in files) {
      if (file.name != null) {
        final isCached = await _storageService.isFileCached(file.name!);
        updatedCacheRegistry[file.name!] = isCached;
      }
    }

    setState(() {
      _remoteFiles = files;
      _cacheRegistry = updatedCacheRegistry;
      _isLoadingList = false;
    });
  }

  /// Triggers stream sync on an individual remote file entry
  Future<void> _syncFile(drive.File driveFile) async {
    final api = AuthService().driveApi;
    final fileId = driveFile.id;
    final fileName = driveFile.name;

    if (api == null || fileId == null || fileName == null) return;

    setState(() => _syncingTracker[fileId] = true);

    final File? localizedFile = await _storageService.downloadDriveFile(
      driveApi: api,
      fileId: fileId,
      fileName: fileName,
    );

    setState(() {
      _syncingTracker[fileId] = false;
      if (localizedFile != null) {
        _cacheRegistry[fileName] = true;
      }
    });

    if (localizedFile != null && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Successfully cached: $fileName')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final user = authService.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Workspace Discovery Sync'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Library Index',
            onPressed: _isLoadingList ? null : _loadSyncDashboard,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign Out',
            onPressed: () async => await authService.signOut(),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Global profile info banner component
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Connected Workspace',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(color: Colors.grey),
                ),
                Text(
                  user?.email ?? 'Unknown Profile Account',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Divider(),

          // Main dynamic listing structure
          Expanded(child: _buildDashboardContent()),
        ],
      ),
    );
  }

  Widget _buildDashboardContent() {
    if (_isLoadingList) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(_errorMessage, style: const TextStyle(color: Colors.red)),
        ),
      );
    }

    if (_remoteFiles.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_off, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                'No Accessible PDFs Found',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Under the restricted "drive.file" scope, this app can only detect files it created itself or files you opened explicitly inside it.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Scan Drive Again'),
                onPressed: _loadSyncDashboard,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      itemCount: _remoteFiles.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final file = _remoteFiles[index];
        final id = file.id ?? '';
        final name = file.name ?? 'Unnamed File';

        final isCached = _cacheRegistry[name] ?? false;
        final isSyncing = _syncingTracker[id] ?? false;

        return ListTile(
          leading: Icon(
            Icons.picture_as_pdf,
            color: isCached ? Colors.red : Colors.grey,
            size: 36,
          ),
          title: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            isCached
                ? 'Available offline (cached)'
                : 'Cloud Storage target only',
            style: TextStyle(
              color: isCached ? Colors.green : Colors.orange,
              fontSize: 12,
            ),
          ),
          trailing: _buildTrailingWidget(file, isCached, isSyncing),
        );
      },
    );
  }

  Widget _buildTrailingWidget(drive.File file, bool isCached, bool isSyncing) {
    if (isSyncing) {
      return const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2.5),
      );
    }

    if (isCached) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.cloud_upload, color: Colors.green),
            tooltip: 'Push Local Modifications Upstream',
            onPressed: () => _uploadChanges(file),
          ),
          IconButton(
            icon: const Icon(Icons.visibility, color: Colors.blue),
            tooltip: 'View Native Document',
            onPressed: () async {
              final String? name = file.name;
              if (name == null) return;

              final File cachedFile = await _storageService.getCachedFile(name);
              if (!mounted) return;

              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) =>
                      PdfViewerScreen(fileName: name, localFile: cachedFile),
                ),
              );
            },
          ),
        ],
      );
    }

    return IconButton(
      icon: const Icon(Icons.cloud_download, color: Colors.orange),
      tooltip: 'Sync and Store File Locally',
      onPressed: () => _syncFile(file),
    );
  }

  final SyncService _syncService = SyncService();

  /// Pushes local modifications back up to Google Drive
  Future<void> _uploadChanges(drive.File driveFile) async {
    final api = AuthService().driveApi;
    final fileId = driveFile.id;
    final fileName = driveFile.name;

    if (api == null || fileId == null || fileName == null) return;

    setState(() => _syncingTracker[fileId] = true);

    final bool success = await _syncService.uploadLocalUpdate(
      driveApi: api,
      fileId: fileId,
      fileName: fileName,
    );

    setState(() => _syncingTracker[fileId] = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Successfully synced upstream: $fileName'
                : 'Failed to push updates upstream.',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }
}
