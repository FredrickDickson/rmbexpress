import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/user_provider.dart';
import '../../core/providers/transaction_provider.dart';
import '../../core/router/app_router.dart';
import '../../core/widgets/role_based_app_bar.dart';
import '../../core/widgets/role_based_drawer.dart';
import '../../core/widgets/role_based_widget.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/balance_card.dart';
import '../../widgets/quick_actions.dart';
import '../../widgets/recent_transactions.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    
    // Refresh user data from Supabase
    await ref.read(userProvider.notifier).refreshUserData();
    
    // Small delay for smooth UX
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    final transactions = ref.watch(transactionsProvider);
    final isLoadingTransactions = ref.watch(isLoadingTransactionsProvider);

    return Scaffold(
      appBar: RoleBasedAppBar(
        title: 'Welcome back, ${_getFirstName(user.name)}',
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notifications - Coming Soon!')),
              );
            },
          ),
        ],
      ),
      drawer: const RoleBasedDrawer(),
      
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              
              // Balance Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: BalanceCard(
                  balance: user.balance,
                  isLoading: _isLoading,
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Quick Actions
              const QuickActions(),
              
              const SizedBox(height: 32),
              
              // Recent Transactions
              RecentTransactions(
                transactions: transactions,
                isLoading: isLoadingTransactions,
              ),
              
              // Admin-only quick access section
              RoleBasedWidget.adminOnly(
                child: Column(
                  children: [
                    const SizedBox(height: 32),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: _buildAdminQuickAccess(context),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(AppRouter.buyRmb),
        child: const Icon(Icons.currency_exchange),
      ),
    );
  }

  String _getFirstName(String fullName) {
    if (fullName.isEmpty || fullName == 'Loading...') {
      return 'User';
    }
    final parts = fullName.split(' ');
    return parts.isNotEmpty ? parts.first : 'User';
  }

  Widget _buildAdminQuickAccess(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.admin_panel_settings,
                    color: AppTheme.primaryGreen,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Admin Quick Access',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildAdminQuickButton(
                    context,
                    'Users',
                    Icons.people,
                    () => context.go(AppRouter.adminUsers),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildAdminQuickButton(
                    context,
                    'Transactions',
                    Icons.receipt_long,
                    () => context.go(AppRouter.adminTransactions),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildAdminQuickButton(
                    context,
                    'Settings',
                    Icons.settings,
                    () => context.go(AppRouter.adminConfig),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildAdminQuickButton(
                    context,
                    'Reports',
                    Icons.analytics,
                    () => context.go(AppRouter.adminReports),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminQuickButton(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.dividerColor),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppTheme.primaryGreen, size: 24),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}