import 'package:go_router/go_router.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/register_screen.dart';
import '../../screens/dashboard/dashboard_screen.dart';
import '../../screens/buy_rmb/buy_rmb_screen.dart';
import '../../screens/wallet/wallet_screen.dart';
import '../../screens/transaction_history/transaction_history_screen.dart';
import '../../screens/profile/profile_screen.dart';
import '../../screens/auth/user_shell.dart';
import '../../screens/admin/admin_shell.dart';
import '../../screens/admin/admin_dashboard_screen.dart';
import '../../screens/admin/admin_users_screen.dart';
import '../../screens/admin/admin_transactions_screen.dart';
import '../../screens/admin/admin_config_screen.dart';
import '../../screens/admin/admin_reports_screen.dart';

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
      // Protected user routes with UserShell authentication wrapper
      GoRoute(
        path: dashboard,
        builder: (context, state) => const UserShell(
          child: DashboardScreen(),
        ),
      ),
      GoRoute(
        path: buyRmb,
        builder: (context, state) => const UserShell(
          child: BuyRmbScreen(),
        ),
      ),
      GoRoute(
        path: wallet,
        builder: (context, state) => const UserShell(
          child: WalletScreen(),
        ),
      ),
      GoRoute(
        path: transactions,
        builder: (context, state) => const UserShell(
          child: TransactionHistoryScreen(),
        ),
      ),
      GoRoute(
        path: profile,
        builder: (context, state) => const UserShell(
          child: ProfileScreen(),
        ),
      ),
      
      // Admin routes with AdminShell authentication wrapper
      GoRoute(
        path: adminDashboard,
        builder: (context, state) => const AdminShell(
          child: AdminDashboardScreen(),
        ),
      ),
      GoRoute(
        path: adminUsers,
        builder: (context, state) => const AdminShell(
          child: AdminUsersScreen(),
        ),
      ),
      GoRoute(
        path: adminTransactions,
        builder: (context, state) => const AdminShell(
          child: AdminTransactionsScreen(),
        ),
      ),
      GoRoute(
        path: adminConfig,
        builder: (context, state) => const AdminShell(
          child: AdminConfigScreen(),
        ),
      ),
      GoRoute(
        path: adminReports,
        builder: (context, state) => const AdminShell(
          child: AdminReportsScreen(),
        ),
      ),
    ],
  );

}