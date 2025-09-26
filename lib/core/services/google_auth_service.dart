import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';

class GoogleUser {
  final String id;
  final String email;
  final String displayName;
  final String photoUrl;

  GoogleUser({
    required this.id,
    required this.email,
    required this.displayName,
    required this.photoUrl,
  });

  factory GoogleUser.fromGoogleSignInAccount(GoogleSignInAccount account) {
    return GoogleUser(
      id: account.id,
      email: account.email,
      displayName: account.displayName ?? 'User',
      photoUrl: account.photoUrl ?? '',
    );
  }
}

class GoogleAuthService {
  static final GoogleAuthService _instance = GoogleAuthService._internal();
  factory GoogleAuthService() => _instance;
  GoogleAuthService._internal();

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'profile',
    ],
  );

  GoogleUser? _currentUser;
  GoogleUser? get currentUser => _currentUser;
  bool get isSignedIn => _currentUser != null;

  /// Initialize Google Sign In and check for existing signed in user
  Future<void> initialize() async {
    try {
      final account = await _googleSignIn.signInSilently();
      if (account != null) {
        _currentUser = GoogleUser.fromGoogleSignInAccount(account);
      }
    } catch (error) {
      debugPrint('Error initializing Google Auth: $error');
    }
  }

  /// Sign in with Google
  Future<GoogleUser?> signIn() async {
    try {
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      if (account != null) {
        _currentUser = GoogleUser.fromGoogleSignInAccount(account);
        return _currentUser;
      }
    } catch (error) {
      debugPrint('Error signing in with Google: $error');
    }
    return null;
  }

  /// Sign out from Google
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      _currentUser = null;
    } catch (error) {
      debugPrint('Error signing out from Google: $error');
    }
  }

  /// Disconnect Google account completely
  Future<void> disconnect() async {
    try {
      await _googleSignIn.disconnect();
      _currentUser = null;
    } catch (error) {
      debugPrint('Error disconnecting Google account: $error');
    }
  }
}