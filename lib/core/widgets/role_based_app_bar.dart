import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../router/app_router.dart';
import '../services/supabase_service.dart';
import 'role_based_widget.dart';

/// Role-based app bar that shows different options based on user role
class RoleBasedAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showBackButton;
  final bool showLogout;
  final bool automaticallyImplyLeading;

  const RoleBasedAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showBackButton = false,
    this.showLogout = true,
    this.automaticallyImplyLeading = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userRoleAsync = ref.watch(userRoleProvider);

    return AppBar(
      title: Text(title),
      backgroundColor: AppTheme.surfaceColor,
      foregroundColor: AppTheme.textPrimary,
      elevation: 1,
      automaticallyImplyLeading: automaticallyImplyLeading,
      actions: [
        // Role-based admin button
        RoleBasedWidget.adminOnly(
          child: IconButton(
            icon: const Icon(Icons.admin_panel_settings),
            tooltip: 'Admin Dashboard',
            onPressed: () => context.go(AppRouter.adminDashboard),
          ),
        ),
        
        // User profile button (for all authenticated users)
        IconButton(
          icon: const Icon(Icons.person),
          tooltip: 'Profile',
          onPressed: () => context.go(AppRouter.profile),
        ),
        
        // Role indicator
        userRoleAsync.when(
          data: (userRole) => _buildRoleIndicator(userRole),
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),
        
        // Logout button
        if (showLogout)
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () => _handleLogout(context),
          ),
        
        // Additional actions
        ...actions ?? [],
      ],
    );
  }

  Widget _buildRoleIndicator(UserRole? userRole) {
    if (userRole == null) return const SizedBox.shrink();

    String roleText;
    Color roleColor;
    IconData roleIcon;

    switch (userRole) {
      case UserRole.superAdmin:
        roleText = 'SUPER';
        roleColor = AppTheme.warningColor;
        roleIcon = Icons.star;
        break;
      case UserRole.admin:
        roleText = 'ADMIN';
        roleColor = AppTheme.primaryGreen;
        roleIcon = Icons.shield;
        break;
      case UserRole.user:
      default:
        return const SizedBox.shrink(); // Don't show indicator for regular users
    }

    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: roleColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: roleColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            roleIcon,
            size: 16,
            color: roleColor,
          ),
          const SizedBox(width: 4),
          Text(
            roleText,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: roleColor,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    final supabaseService = SupabaseService();
    try {
      await supabaseService.signOut();
      if (context.mounted) {
        context.go(AppRouter.login);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error signing out: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}