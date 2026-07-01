import 'package:flutter/material.dart';
import 'package:desktop_android_pdf_syncer/services/auth_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. Reference your existing v7 global singleton state
    final authService = AuthService();
    final user = authService.currentUser;
    final apiReady = authService.driveApi != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Pipeline Dashboard'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          // Sign Out Action Button
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign Out',
            onPressed: () async {
              await authService.signOut();
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Greeting Header
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
            Text(
              'Backend Pipeline Verification',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                // Resolved deprecation warnings using modern .withValues syntax
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          apiReady 
                              ? 'Drive API Client: Active' 
                              : 'Drive API Client: Error',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: apiReady ? Colors.green : Colors.red,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          apiReady
                              ? 'Secure HTTP channel open. Ready to download files.'
                              : 'Failed to authorize drive.file scope tokens.',
                          style: TextStyle(
                            fontSize: 14,
                            color: apiReady ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Step 4 Placeholder Layout Area
            const Center(
              child: Text(
                'Ready for Step 4: Remote File Query Processing.',
                style: TextStyle(
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
