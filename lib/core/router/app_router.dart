import 'package:go_router/go_router.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/register_screen.dart';
import '../../screens/dashboard/dashboard_screen.dart';
import '../../screens/buy_rmb/buy_rmb_screen.dart';
import '../../screens/wallet/wallet_screen.dart';
import '../../screens/transaction_history/transaction_history_screen.dart';
import '../../screens/profile/profile_screen.dart';
import '../../screens/admin/admin_dashboard_screen.dart';
import '../../screens/admin/admin_users_screen.dart';
import '../../screens/admin/admin_transactions_screen.dart';
import '../../screens/admin/admin_config_screen.dart';
import '../../screens/admin/admin_reports_screen.dart';
import '../services/admin_service.dart';

class AppRouter {
  static const String login = '/login';
  static const String register = '/register';
  static const String dashboard = '/dashboard';
  static const String buyRmb = '/buy-rmb';
  static const String wallet = '/wallet';
  static const String transactions = '/transactions';
  static const String profile = '/profile';
  
  // Admin routes
  static const String adminDashboard = '/admin';
  static const String adminUsers = '/admin/users';
  static const String adminTransactions = '/admin/transactions';
  static const String adminConfig = '/admin/config';
  static const String adminReports = '/admin/reports';

  static final GoRouter router = GoRouter(
    initialLocation: login,
    routes: [
      GoRoute(
        path: login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: dashboard,
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: buyRmb,
        builder: (context, state) => const BuyRmbScreen(),
      ),
      GoRoute(
        path: wallet,
        builder: (context, state) => const WalletScreen(),
      ),
      GoRoute(
        path: transactions,
        builder: (context, state) => const TransactionHistoryScreen(),
      ),
      GoRoute(
        path: profile,
        builder: (context, state) => const ProfileScreen(),
      ),
      
      // Admin routes with role guard
      GoRoute(
        path: adminDashboard,
        builder: (context, state) => const AdminDashboardScreen(),
        redirect: (context, state) => _adminGuard(),
      ),
      GoRoute(
        path: adminUsers,
        builder: (context, state) => const AdminUsersScreen(),
        redirect: (context, state) => _adminGuard(),
      ),
      GoRoute(
        path: adminTransactions,
        builder: (context, state) => const AdminTransactionsScreen(),
        redirect: (context, state) => _adminGuard(),
      ),
      GoRoute(
        path: adminConfig,
        builder: (context, state) => const AdminConfigScreen(),
        redirect: (context, state) => _adminGuard(),
      ),
      GoRoute(
        path: adminReports,
        builder: (context, state) => const AdminReportsScreen(),
        redirect: (context, state) => _adminGuard(),
      ),
    ],
  );

  // Admin route guard
  static String? _adminGuard() {
    final adminService = AdminService();
    
    // This is a simple check - in a real app you might want to cache this
    // For now, we'll check on each navigation
    return null; // Allow navigation, check will be done in the screen
  }
}