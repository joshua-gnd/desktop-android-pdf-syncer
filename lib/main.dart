import 'package:flutter/material.dart';
import 'package:desktop_android_pdf_syncer/services/auth_service.dart';
import 'package:desktop_android_pdf_syncer/screens/login_screen.dart';
import 'package:desktop_android_pdf_syncer/screens/home_screen.dart';

void main() {
  // 1. Ensure Flutter engine bindings are completely ready
  WidgetsFlutterBinding.ensureInitialized();
  
  // 2. Instantiate your single, global authorization service instance
  final authService = AuthService();

  // 3. Pass the engine context downward
  runApp(MyApp(authService: authService));
}

class MyApp extends StatelessWidget {
  final AuthService authService;
  
  const MyApp({super.key, required this.authService});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PDF Syncer',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      // ListenableBuilder catches 'notifyListeners()' events out of your service
      home: ListenableBuilder(
        listenable: authService,
        builder: (context, _) {
          
          // A. While checking background cache tokens, lock the UI down with a spinner
          if (authService.isInitializing) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          // B. Swap layout frameworks instantly based on state stream updates
          if (authService.isAuthenticated) {
            return const HomeScreen();
          } else {
            return const LoginScreen();
          }
        },
      ),
    );
  }
}
