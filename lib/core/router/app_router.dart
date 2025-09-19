import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/register_screen.dart';
import '../../screens/dashboard/dashboard_screen.dart';
import '../../screens/buy_rmb/buy_rmb_screen.dart';
import '../../screens/send_money/send_money_screen.dart';
import '../../screens/transaction_history/transaction_history_screen.dart';
import '../../screens/profile/profile_screen.dart';

class AppRouter {
  static const String login = '/login';
  static const String register = '/register';
  static const String dashboard = '/dashboard';
  static const String buyRmb = '/buy-rmb';
  static const String sendMoney = '/send-money';
  static const String transactions = '/transactions';
  static const String profile = '/profile';

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
        path: sendMoney,
        builder: (context, state) => const SendMoneyScreen(),
      ),
      GoRoute(
        path: transactions,
        builder: (context, state) => const TransactionHistoryScreen(),
      ),
      GoRoute(
        path: profile,
        builder: (context, state) => const ProfileScreen(),
      ),
    ],
  );
}