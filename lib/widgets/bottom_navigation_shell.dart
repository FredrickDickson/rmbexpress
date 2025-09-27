import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/app_theme.dart';
import '../core/router/app_router.dart';

/// BottomNavigationShell provides Material Design bottom navigation
/// for the main user screens in the BuyRMBOnline app
class BottomNavigationShell extends StatefulWidget {
  final Widget child;

  const BottomNavigationShell({
    super.key,
    required this.child,
  });

  @override
  State<BottomNavigationShell> createState() => _BottomNavigationShellState();
}

class _BottomNavigationShellState extends State<BottomNavigationShell> {
  int get _currentIndex {
    final location = GoRouter.of(context).routerDelegate.currentConfiguration.last.matchedLocation;
    switch (location) {
      case AppRouter.dashboard:
        return 0;
      case AppRouter.buyRmb:
        return 1;
      case AppRouter.wallet:
        return 2;
      case AppRouter.transactions:
        return 3;
      case AppRouter.profile:
        return 4;
      default:
        return 0;
    }
  }

  void _onTabTapped(int index) {
    switch (index) {
      case 0:
        context.go(AppRouter.dashboard);
        break;
      case 1:
        context.go(AppRouter.buyRmb);
        break;
      case 2:
        context.go(AppRouter.wallet);
        break;
      case 3:
        context.go(AppRouter.transactions);
        break;
      case 4:
        context.go(AppRouter.profile);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: _onTabTapped,
            type: BottomNavigationBarType.fixed,
            backgroundColor: AppTheme.surfaceColor,
            selectedItemColor: AppTheme.primaryGreen,
            unselectedItemColor: AppTheme.textSecondary,
            selectedLabelStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
            elevation: 0,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.dashboard_outlined),
                activeIcon: Icon(Icons.dashboard),
                label: 'Dashboard',
                tooltip: 'View your account overview and quick actions',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.currency_exchange_outlined),
                activeIcon: Icon(Icons.currency_exchange),
                label: 'Buy RMB',
                tooltip: 'Exchange GHS to Chinese Yuan (RMB)',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.account_balance_wallet_outlined),
                activeIcon: Icon(Icons.account_balance_wallet),
                label: 'Wallet',
                tooltip: 'Manage your digital wallet and balances',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.history_outlined),
                activeIcon: Icon(Icons.history),
                label: 'History',
                tooltip: 'View your transaction history',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: 'Profile',
                tooltip: 'Manage your account settings and profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}