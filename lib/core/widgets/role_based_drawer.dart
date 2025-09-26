import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../router/app_router.dart';
import '../services/supabase_service.dart';
import 'role_based_widget.dart';

/// Role-based navigation drawer that shows different options based on user role
class RoleBasedDrawer extends ConsumerWidget {
  const RoleBasedDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userRoleAsync = ref.watch(userRoleProvider);

    return Drawer(
      child: Column(
        children: [
          // Drawer header with user info and role
          userRoleAsync.when(
            data: (userRole) => _buildDrawerHeader(context, userRole),
            loading: () => _buildLoadingHeader(),
            error: (_, __) => _buildErrorHeader(),
          ),
          
          // Navigation items
          Expanded(
            child: ListView(
              children: [
                // User navigation items (available to all authenticated users)
                _buildNavigationItem(
                  icon: Icons.dashboard,
                  title: 'Dashboard',
                  onTap: () => _navigateTo(context, AppRouter.dashboard),
                ),
                _buildNavigationItem(
                  icon: Icons.currency_exchange,
                  title: 'Buy RMB',
                  onTap: () => _navigateTo(context, AppRouter.buyRmb),
                ),
                _buildNavigationItem(
                  icon: Icons.account_balance_wallet,
                  title: 'Wallet',
                  onTap: () => _navigateTo(context, AppRouter.wallet),
                ),
                _buildNavigationItem(
                  icon: Icons.history,
                  title: 'Transaction History',
                  onTap: () => _navigateTo(context, AppRouter.transactions),
                ),
                _buildNavigationItem(
                  icon: Icons.person,
                  title: 'Profile',
                  onTap: () => _navigateTo(context, AppRouter.profile),
                ),
                
                // Admin section divider
                RoleBasedWidget.adminOnly(
                  child: const Divider(),
                ),
                
                // Admin navigation items
                RoleBasedWidget.adminOnly(
                  child: _buildSectionHeader('Admin Panel'),
                ),
                RoleBasedNavigationItem(
                  allowedRoles: const [UserRole.admin, UserRole.superAdmin],
                  child: _buildNavigationItem(
                    icon: Icons.admin_panel_settings,
                    title: 'Admin Dashboard',
                    onTap: () => _navigateTo(context, AppRouter.adminDashboard),
                  ),
                ),
                RoleBasedNavigationItem(
                  allowedRoles: const [UserRole.admin, UserRole.superAdmin],
                  child: _buildNavigationItem(
                    icon: Icons.people,
                    title: 'User Management',
                    onTap: () => _navigateTo(context, AppRouter.adminUsers),
                  ),
                ),
                RoleBasedNavigationItem(
                  allowedRoles: const [UserRole.admin, UserRole.superAdmin],
                  child: _buildNavigationItem(
                    icon: Icons.receipt_long,
                    title: 'Transaction Management',
                    onTap: () => _navigateTo(context, AppRouter.adminTransactions),
                  ),
                ),
                RoleBasedNavigationItem(
                  allowedRoles: const [UserRole.admin, UserRole.superAdmin],
                  child: _buildNavigationItem(
                    icon: Icons.settings,
                    title: 'System Configuration',
                    onTap: () => _navigateTo(context, AppRouter.adminConfig),
                  ),
                ),
                RoleBasedNavigationItem(
                  allowedRoles: const [UserRole.admin, UserRole.superAdmin],
                  child: _buildNavigationItem(
                    icon: Icons.analytics,
                    title: 'Reports & Analytics',
                    onTap: () => _navigateTo(context, AppRouter.adminReports),
                  ),
                ),
              ],
            ),
          ),
          
          // Logout button at bottom
          const Divider(),
          _buildNavigationItem(
            icon: Icons.logout,
            title: 'Logout',
            onTap: () => _handleLogout(context),
            isDestructive: true,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildDrawerHeader(BuildContext context, UserRole? userRole) {
    return DrawerHeader(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryGreen, AppTheme.darkGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white,
            child: Icon(
              Icons.person,
              size: 36,
              color: AppTheme.primaryGreen,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'BuyRMBOnline',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          _buildRoleBadge(userRole),
        ],
      ),
    );
  }

  Widget _buildRoleBadge(UserRole? userRole) {
    if (userRole == null) return const SizedBox.shrink();

    String roleText;
    IconData roleIcon;

    switch (userRole) {
      case UserRole.superAdmin:
        roleText = 'Super Administrator';
        roleIcon = Icons.star;
        break;
      case UserRole.admin:
        roleText = 'Administrator';
        roleIcon = Icons.shield;
        break;
      case UserRole.user:
      default:
        roleText = 'User';
        roleIcon = Icons.person;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            roleIcon,
            size: 14,
            color: Colors.white,
          ),
          const SizedBox(width: 4),
          Text(
            roleText,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingHeader() {
    return const DrawerHeader(
      decoration: BoxDecoration(color: AppTheme.primaryGreen),
      child: Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
    );
  }

  Widget _buildErrorHeader() {
    return const DrawerHeader(
      decoration: BoxDecoration(color: AppTheme.errorColor),
      child: Center(
        child: Text(
          'Error loading user data',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: AppTheme.textSecondary,
        ),
      ),
    );
  }

  Widget _buildNavigationItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final color = isDestructive ? AppTheme.errorColor : AppTheme.textPrimary;

    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: TextStyle(color: color),
      ),
      onTap: onTap,
      dense: true,
    );
  }

  void _navigateTo(BuildContext context, String route) {
    Navigator.of(context).pop(); // Close drawer
    context.go(route);
  }

  Future<void> _handleLogout(BuildContext context) async {
    Navigator.of(context).pop(); // Close drawer
    
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
}