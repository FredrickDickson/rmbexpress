import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/admin_service.dart';
import '../../core/services/supabase_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/router/app_router.dart';

/// AdminShell provides authentication and authorization wrapper for all admin screens
/// This ensures that only authenticated admin users can access admin functionality
class AdminShell extends StatefulWidget {
  final Widget child;

  const AdminShell({
    super.key,
    required this.child,
  });

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  final _supabaseService = SupabaseService();
  final _adminService = AdminService();
  
  bool _isLoading = true;
  bool _isAuthenticated = false;
  bool _isAuthorized = false;
  String? _errorMessage;
  Map<String, dynamic>? _adminProfile;

  @override
  void initState() {
    super.initState();
    _checkAuthAndAuthorization();
  }

  Future<void> _checkAuthAndAuthorization() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Step 1: Check if user is authenticated
      if (!_supabaseService.isAuthenticated) {
        setState(() {
          _isAuthenticated = false;
          _isAuthorized = false;
        });
        return;
      }

      setState(() {
        _isAuthenticated = true;
      });

      // Step 2: Check if user has admin role
      final isAdmin = await _adminService.isCurrentUserAdmin();
      if (!isAdmin) {
        setState(() {
          _isAuthorized = false;
        });
        return;
      }

      // Step 3: Get admin profile information
      final adminProfile = await _adminService.getCurrentAdminProfile();
      if (adminProfile == null) {
        setState(() {
          _isAuthorized = false;
          _errorMessage = 'Admin profile not found';
        });
        return;
      }

      setState(() {
        _isAuthorized = true;
        _adminProfile = adminProfile;
      });

    } catch (e) {
      setState(() {
        _isAuthenticated = false;
        _isAuthorized = false;
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
      return _buildRedirectingScreen('Redirecting to login...');
    }

    if (!_isAuthorized) {
      // User is authenticated but not an admin - redirect to dashboard
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.go(AppRouter.dashboard);
        }
      });
      return _buildAccessDeniedScreen();
    }

    // User is authenticated and authorized - show the admin content
    return AdminAuthProvider(
      adminProfile: _adminProfile!,
      child: widget.child,
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: AppTheme.primaryGreen,
            ),
            const SizedBox(height: 24),
            Text(
              'Verifying admin access...',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.symmetric(horizontal: 32),
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.errorColor.withOpacity(0.3)),
                ),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: AppTheme.errorColor),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRedirectingScreen(String message) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: AppTheme.primaryGreen,
            ),
            const SizedBox(height: 24),
            Text(
              message,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccessDeniedScreen() {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.security,
                size: 80,
                color: AppTheme.errorColor,
              ),
              const SizedBox(height: 24),
              Text(
                'Access Denied',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppTheme.errorColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'You do not have administrator privileges to access this area.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton(
                    onPressed: _checkAuthAndAuthorization,
                    child: const Text('Retry'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () => context.go(AppRouter.dashboard),
                    child: const Text('Go to Dashboard'),
                  ),
                ],
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.errorColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.errorColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: AppTheme.errorColor),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// AdminAuthProvider makes admin profile data available to child widgets
/// This allows admin screens to access current admin user information
class AdminAuthProvider extends InheritedWidget {
  final Map<String, dynamic> adminProfile;

  const AdminAuthProvider({
    super.key,
    required this.adminProfile,
    required super.child,
  });

  static AdminAuthProvider? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AdminAuthProvider>();
  }

  static AdminAuthProvider of(BuildContext context) {
    final provider = maybeOf(context);
    assert(provider != null, 'No AdminAuthProvider found in context');
    return provider!;
  }

  @override
  bool updateShouldNotify(AdminAuthProvider oldWidget) {
    return adminProfile != oldWidget.adminProfile;
  }
}