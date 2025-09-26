import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notifications - Coming Soon!')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.person_outlined),
            onPressed: () => context.push(AppRouter.profile),
          ),
        ],
      ),
      
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() => _isLoading = true);
          await _simulateLoading();
          // Refresh transactions - provider will automatically update
        },
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
}