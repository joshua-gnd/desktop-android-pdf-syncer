import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/googleapis_auth.dart' as auth;
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';

class AuthService extends ChangeNotifier {
  // Revert back to the mandatory package instance singleton
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  // Track the scopes required for Google Drive interaction
  final List<String> _driveScopes = [drive.DriveApi.driveFileScope];

  GoogleSignInAccount? _currentUser;
  drive.DriveApi? _driveApi;
  bool _isInitializing = true;

  bool get isAuthenticated => _currentUser != null;
  bool get isInitializing => _isInitializing;
  GoogleSignInAccount? get currentUser => _currentUser;
  drive.DriveApi? get driveApi => _driveApi;

  AuthService() {
    _initializeAndCheckSignIn();
  }

  Future<void> _initializeAndCheckSignIn() async {
    try {
      // FIX: Pass the serverClientId directly inside the initialize method
      await _googleSignIn.initialize(
        serverClientId: 'YOUR_GOOGLE_CLOUD_WEB_CLIENT_://googleusercontent.com',
      );

      // 2. Set up the stream listener to capture structural auth state updates
      _googleSignIn.authenticationEvents.listen((event) async {
        if (event is GoogleSignInAuthenticationEventSignIn) {
          _currentUser = event.user;
          await _initializeDriveApi();
        } else if (event is GoogleSignInAuthenticationEventSignOut) {
          _currentUser = null;
          _driveApi = null;
        }
        notifyListeners(); // Repaints user interface wrappers
      });

      // 3. Check for locally cached credential storage sessions
      await _googleSignIn.attemptLightweightAuthentication();
      
    } catch (e) {
      debugPrint('Plugin initialization or background sign-in failed: $e');
    } finally {
      _isInitializing = false;
      notifyListeners();
    }
  }

  // Handle manual interaction via interactive sheets
  Future<bool> signIn() async {
    try {
      // Clean non-nullable variable assignment
      final GoogleSignInAccount account = await _googleSignIn.authenticate(
        scopeHint: _driveScopes,
      );
      
      _currentUser = account;
      await _initializeDriveApi();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Interactive authentication failed: $e');
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      debugPrint('Sign out failed: $e');
    }
  }

  // Generates the modern v7-compatible HTTP client for Google APIs
  Future<void> _initializeDriveApi() async {
    final GoogleSignInAccount? account = _currentUser;
    if (account == null) return;

    try {
      // 1. Fetch structural authorization (which returns a nullable type)
      final GoogleSignInClientAuthorization? authorization = 
          await account.authorizationClient.authorizationForScopes(_driveScopes);

      // 2. Safety block: convert to a guaranteed non-nullable handle
      if (authorization == null) {
        throw Exception("Authorization for scopes returned null.");
      }

      // 3. Extract the authenticated Client using the non-nullable reference
      final auth.AuthClient client = authorization.authClient(scopes: _driveScopes);

      // 4. Instantiate your primary DriveApi environment mapping
      _driveApi = drive.DriveApi(client);
    } catch (e) {
      debugPrint('Failed to authorize Drive API scopes: $e');
      _driveApi = null;
    }
  }
}
