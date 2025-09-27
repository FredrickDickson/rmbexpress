import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/supabase_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/router/app_router.dart';
import '../../widgets/bottom_navigation_shell.dart';

/// UserShell provides authentication wrapper for all user screens
/// This ensures that only authenticated users can access user functionality
class UserShell extends StatefulWidget {
  final Widget child;

  const UserShell({
    super.key,
    required this.child,
  });

  @override
  State<UserShell> createState() => _UserShellState();
}

class _UserShellState extends State<UserShell> {
  final _supabaseService = SupabaseService();
  
  bool _isLoading = true;
  bool _isAuthenticated = false;
  String? _errorMessage;
  Map<String, dynamic>? _userProfile;
  late final Stream<AuthState> _authStream;
  StreamSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _authStream = _supabaseService.authStateChanges;
    _checkAuthentication();
    _setupAuthListener();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  void _setupAuthListener() {
    _authSubscription = _authStream.listen((AuthState data) {
      if (mounted) {
        _checkAuthentication();
      }
    });
  }

  Future<void> _checkAuthentication() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Check if user is authenticated
      if (!_supabaseService.isAuthenticated) {
        setState(() {
          _isAuthenticated = false;
        });
        return;
      }

      setState(() {
        _isAuthenticated = true;
      });

      // Get user profile information
      final userProfile = await _supabaseService.getCurrentUserProfile();
      setState(() {
        _userProfile = userProfile;
      });

    } catch (e) {
      setState(() {
        _isAuthenticated = false;
        _errorMessage = 'Authentication error: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingScreen();
    }

    if (!_isAuthenticated) {
      // User is not authenticated - redirect to login
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.go(AppRouter.login);
        }
      });
      return _buildRedirectScreen();
    }

    // User is authenticated - show the requested content with bottom navigation
    return BottomNavigationShell(
      child: widget.child,
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
            ),
            SizedBox(height: 16),
            Text(
              'Authenticating...',
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRedirectScreen() {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.security,
              size: 64,
              color: AppTheme.primaryGreen,
            ),
            const SizedBox(height: 16),
            const Text(
              'Authentication Required',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Redirecting to login...',
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.textSecondary,
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.symmetric(horizontal: 32),
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.errorColor.withOpacity(0.3)),
                ),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(
                    color: AppTheme.errorColor,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}