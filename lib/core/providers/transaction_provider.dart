import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/transaction_model.dart';

final transactionsProvider = StateNotifierProvider<TransactionsNotifier, List<Transaction>>((ref) {
  return TransactionsNotifier();
});

final isLoadingTransactionsProvider = StateProvider<bool>((ref) => false);

class TransactionsNotifier extends StateNotifier<List<Transaction>> {
  TransactionsNotifier() : super(_mockTransactions);

  static final _mockTransactions = [
    Transaction(
      id: '1',
      type: TransactionType.buy,
      amount: 5000.00,
      currency: 'RMB',
      status: TransactionStatus.completed,
      date: DateTime.now().subtract(const Duration(hours: 2)),
      description: 'Currency exchange from USD',
    ),
    Transaction(
      id: '2',
      type: TransactionType.send,
      amount: 1250.00,
      currency: 'RMB',
      status: TransactionStatus.completed,
      date: DateTime.now().subtract(const Duration(days: 1)),
      recipient: 'Li Wei',
    ),
    Transaction(
      id: '3',
      type: TransactionType.receive,
      amount: 800.00,
      currency: 'RMB',
      status: TransactionStatus.completed,
      date: DateTime.now().subtract(const Duration(days: 2)),
      recipient: 'Zhang Ming',
    ),
    Transaction(
      id: '4',
      type: TransactionType.buy,
      amount: 3200.00,
      currency: 'RMB',
      status: TransactionStatus.pending,
      date: DateTime.now().subtract(const Duration(days: 3)),
      description: 'Currency exchange from EUR',
    ),
    Transaction(
      id: '5',
      type: TransactionType.send,
      amount: 650.00,
      currency: 'RMB',
      status: TransactionStatus.failed,
      date: DateTime.now().subtract(const Duration(days: 5)),
      recipient: 'Wang Xia',
    ),
  ];

  void addTransaction(Transaction transaction) {
    state = [transaction, ...state];
  }
}