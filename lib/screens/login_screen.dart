import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isSigningIn = false;

  void _triggerGoogleAuth() async {
    setState(() => _isSigningIn = true);
    
    // Connects directly to your custom v7 .signIn() method
    final success = await AuthService().signIn();
    
    if (mounted) {
      setState(() => _isSigningIn = false);
      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Authentication failed. Check your developer console logs.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _isSigningIn
            ? const CircularProgressIndicator()
            : ElevatedButton.icon(
                icon: const Icon(Icons.security),
                label: const Text('Sign in with Google Account'),
                onPressed: _triggerGoogleAuth,
              ),
      ),
    );
  }
}
