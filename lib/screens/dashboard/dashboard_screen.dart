import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/user_provider.dart';
import '../../core/providers/transaction_provider.dart';
import '../../core/router/app_router.dart';
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
    _simulateLoading();
  }

  Future<void> _simulateLoading() async {
    // Simulate initial data loading
    await Future.delayed(const Duration(seconds: 2));
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
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome back,',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
              ),
            ),
            Text(
              user.name.split(' ').first,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ).animate().fadeIn(duration: 600.ms).slideX(
          begin: -0.3,
          duration: 600.ms,
          curve: Curves.easeOutCubic,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notifications - Coming Soon!')),
              );
            },
          ).animate().fadeIn(delay: 200.ms).scale(
            duration: 400.ms,
            curve: Curves.elasticOut,
          ),
          
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => context.push(AppRouter.profile),
          ).animate().fadeIn(delay: 400.ms).scale(
            duration: 400.ms,
            curve: Curves.elasticOut,
          ),
        ],
      ),
      
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              const SizedBox(height: 16),
              
              // Balance Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: BalanceCard(
                  balance: user.balance,
                  currency: user.currency,
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
                isLoading: _isLoading || isLoadingTransactions,
              ),
              
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      
      // Floating Action Button for main action
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRouter.buyRmb),
        icon: const Icon(Icons.currency_exchange),
        label: const Text('Buy RMB'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ).animate().fadeIn(delay: 1600.ms).scale(
        duration: 600.ms,
        curve: Curves.elasticOut,
      ),
    );
  }

  Future<void> _handleRefresh() async {
    setState(() => _isLoading = true);
    ref.read(isLoadingTransactionsProvider.notifier).state = true;
    
    // Simulate refresh delay
    await Future.delayed(const Duration(seconds: 1));
    
    setState(() => _isLoading = false);
    ref.read(isLoadingTransactionsProvider.notifier).state = false;
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Dashboard refreshed'),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
    }
  }
}