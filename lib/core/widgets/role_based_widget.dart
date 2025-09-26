import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/supabase_service.dart';

/// Enum for user roles in the system
enum UserRole {
  user,
  admin,
  superAdmin,
}

/// Provider for user role state management
final userRoleProvider = FutureProvider<UserRole?>((ref) async {
  final supabaseService = SupabaseService();
  final roleString = await supabaseService.getCurrentUserRole();
  
  switch (roleString) {
    case 'admin':
      return UserRole.admin;
    case 'super_admin':
      return UserRole.superAdmin;
    case 'user':
    default:
      return UserRole.user;
  }
});

/// Widget that conditionally shows content based on user roles
class RoleBasedWidget extends ConsumerWidget {
  final Widget? adminContent;
  final Widget? superAdminContent;
  final Widget? userContent;
  final Widget? fallback;
  final List<UserRole> allowedRoles;
  final Widget child;

  const RoleBasedWidget({
    super.key,
    this.adminContent,
    this.superAdminContent,
    this.userContent,
    this.fallback,
    this.allowedRoles = const [],
    required this.child,
  });

  /// Constructor for admin-only content
  const RoleBasedWidget.adminOnly({
    super.key,
    required this.child,
    this.fallback,
  }) : adminContent = null,
        superAdminContent = null,
        userContent = null,
        allowedRoles = const [UserRole.admin, UserRole.superAdmin];

  /// Constructor for super admin only content
  const RoleBasedWidget.superAdminOnly({
    super.key,
    required this.child,
    this.fallback,
  }) : adminContent = null,
        superAdminContent = null,
        userContent = null,
        allowedRoles = const [UserRole.superAdmin];

  /// Constructor for user-only content (excludes admins)
  const RoleBasedWidget.userOnly({
    super.key,
    required this.child,
    this.fallback,
  }) : adminContent = null,
        superAdminContent = null,
        userContent = null,
        allowedRoles = const [UserRole.user];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userRoleAsync = ref.watch(userRoleProvider);

    return userRoleAsync.when(
      data: (userRole) {
        // If specific role content is provided, show it
        if (userRole == UserRole.admin && adminContent != null) {
          return adminContent!;
        }
        if (userRole == UserRole.superAdmin && superAdminContent != null) {
          return superAdminContent!;
        }
        if (userRole == UserRole.user && userContent != null) {
          return userContent!;
        }

        // Check if user role is in allowed roles
        if (allowedRoles.isNotEmpty) {
          if (userRole != null && allowedRoles.contains(userRole)) {
            return child;
          } else {
            return fallback ?? const SizedBox.shrink();
          }
        }

        // Default behavior - show child for any authenticated user
        return child;
      },
      loading: () => const SizedBox.shrink(),
      error: (error, stack) => fallback ?? const SizedBox.shrink(),
    );
  }
}

/// Helper widget for role-based navigation items
class RoleBasedNavigationItem extends ConsumerWidget {
  final List<UserRole> allowedRoles;
  final Widget child;
  final VoidCallback? onTap;

  const RoleBasedNavigationItem({
    super.key,
    required this.allowedRoles,
    required this.child,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userRoleAsync = ref.watch(userRoleProvider);

    return userRoleAsync.when(
      data: (userRole) {
        if (userRole != null && allowedRoles.contains(userRole)) {
          return InkWell(
            onTap: onTap,
            child: child,
          );
        }
        return const SizedBox.shrink();
      },
      loading: () => const SizedBox.shrink(),
      error: (error, stack) => const SizedBox.shrink(),
    );
  }
}

/// Helper methods for role checking
class RoleChecker {
  static bool hasRole(UserRole? userRole, List<UserRole> allowedRoles) {
    return userRole != null && allowedRoles.contains(userRole);
  }
  
  static bool isAdmin(UserRole? userRole) {
    return userRole == UserRole.admin || userRole == UserRole.superAdmin;
  }
  
  static bool isSuperAdmin(UserRole? userRole) {
    return userRole == UserRole.superAdmin;
  }
  
  static bool isUser(UserRole? userRole) {
    return userRole == UserRole.user;
  }
}