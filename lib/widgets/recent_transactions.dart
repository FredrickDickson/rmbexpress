import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../core/models/transaction_model.dart';
import '../core/router/app_router.dart';

class RecentTransactions extends StatelessWidget {
  final List<Transaction> transactions;
  final bool isLoading;

  const RecentTransactions({
    super.key,
    required this.transactions,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Transactions',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextButton(
                onPressed: () => context.push(AppRouter.transactions),
                child: const Text('View All'),
              ),
            ],
          ).animate().fadeIn(delay: 800.ms),
        ),
        
        const SizedBox(height: 16),
        
        if (isLoading)
          ...List.generate(
            3,
            (index) => _TransactionLoadingSkeleton().animate().fadeIn(
              delay: Duration(milliseconds: 1000 + (index * 100)),
            ),
          )
        else if (transactions.isEmpty)
          _EmptyTransactions().animate().fadeIn(delay: 1000.ms)
        else
          ...transactions.take(5).map((transaction) {
            final index = transactions.indexOf(transaction);
            return _TransactionItem(
              transaction: transaction,
            ).animate().fadeIn(
              delay: Duration(milliseconds: 1000 + (index * 100)),
            ).slideX(
              begin: index.isEven ? -0.3 : 0.3,
              duration: 500.ms,
              curve: Curves.easeOutCubic,
            );
          }).toList(),
      ],
    );
  }
}

class _TransactionItem extends StatelessWidget {
  final Transaction transaction;

  const _TransactionItem({required this.transaction});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      child: Card(
        child: ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _getTransactionColor().withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getTransactionIcon(),
              color: _getTransactionColor(),
              size: 20,
            ),
          ),
          
          title: Text(
            _getTransactionTitle(),
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (transaction.recipient != null)
                Text('To: ${transaction.recipient}')
              else if (transaction.description != null)
                Text(transaction.description!),
              Text(
                _formatDate(transaction.date),
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6),
                ),
              ),
            ],
          ),
          
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${transaction.type == TransactionType.send ? '-' : '+'}¥${transaction.amount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: transaction.type == TransactionType.send
                      ? Colors.red
                      : Theme.of(context).colorScheme.primary,
                ),
              ),
              _StatusChip(status: transaction.status),
            ],
          ),
        ),
      ),
    );
  }

  Color _getTransactionColor() {
    switch (transaction.type) {
      case TransactionType.buy:
        return Colors.blue;
      case TransactionType.send:
        return Colors.orange;
      case TransactionType.receive:
        return Colors.green;
    }
  }

  IconData _getTransactionIcon() {
    switch (transaction.type) {
      case TransactionType.buy:
        return Icons.currency_exchange;
      case TransactionType.send:
        return Icons.send;
      case TransactionType.receive:
        return Icons.call_received;
    }
  }

  String _getTransactionTitle() {
    switch (transaction.type) {
      case TransactionType.buy:
        return 'Currency Exchange';
      case TransactionType.send:
        return 'Money Sent';
      case TransactionType.receive:
        return 'Money Received';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

class _StatusChip extends StatelessWidget {
  final TransactionStatus status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String text;
    
    switch (status) {
      case TransactionStatus.completed:
        color = Colors.green;
        text = 'Completed';
        break;
      case TransactionStatus.pending:
        color = Colors.orange;
        text = 'Pending';
        break;
      case TransactionStatus.failed:
        color = Colors.red;
        text = 'Failed';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _TransactionLoadingSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      child: Card(
        child: ListTile(
          leading: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          title: Container(
            height: 16,
            width: 120,
            color: Colors.grey.shade300,
          ),
          subtitle: Container(
            height: 12,
            width: 80,
            color: Colors.grey.shade300,
          ),
          trailing: Container(
            height: 16,
            width: 60,
            color: Colors.grey.shade300,
          ),
        ),
      ),
    );
  }
}

class _EmptyTransactions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No transactions yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start by buying some RMB or sending money',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}