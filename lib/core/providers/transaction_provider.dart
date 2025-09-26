import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/transaction_model.dart';
import '../services/supabase_service.dart';

final transactionsProvider = StateNotifierProvider<TransactionsNotifier, List<Transaction>>((ref) {
  return TransactionsNotifier();
});

final isLoadingTransactionsProvider = StateProvider<bool>((ref) => false);

class TransactionsNotifier extends StateNotifier<List<Transaction>> {
  final _supabaseService = SupabaseService();
  
  TransactionsNotifier() : super([]) {
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    try {
      final user = _supabaseService.currentUser;
      if (user == null) return;
      
      final transactions = await _supabaseService.getUserTransactions();
      final convertedTransactions = transactions.map((transaction) {
        return _convertToTransactionModel(transaction);
      }).toList();
      
      state = convertedTransactions;
    } catch (e) {
      print('Failed to load transactions: $e');
      state = [];
    }
  }

  Transaction _convertToTransactionModel(Map<String, dynamic> data) {
    final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
    final exchangeRate = (data['exchange_rate'] as num?)?.toDouble() ?? 1.0;
    final status = data['status'] as String? ?? 'pending';
    final createdAt = data['created_at'] as String?;
    final recipientDetails = data['recipient_details'] as Map<String, dynamic>?;
    
    DateTime transactionDate = DateTime.now();
    if (createdAt != null) {
      transactionDate = DateTime.tryParse(createdAt) ?? DateTime.now();
    }

    TransactionStatus transactionStatus;
    switch (status.toLowerCase()) {
      case 'completed':
        transactionStatus = TransactionStatus.completed;
        break;
      case 'failed':
      case 'cancelled':
        transactionStatus = TransactionStatus.failed;
        break;
      default:
        transactionStatus = TransactionStatus.pending;
        break;
    }

    // Calculate RMB amount for display
    final rmbAmount = amount * exchangeRate;

    return Transaction(
      id: data['id']?.toString() ?? '',
      type: TransactionType.buy, // All transactions are currency purchases
      amount: rmbAmount, // Show RMB amount received
      currency: 'RMB',
      status: transactionStatus,
      date: transactionDate,
      recipient: recipientDetails?['name'] as String?,
      description: 'Currency exchange from ${data['from_currency'] ?? 'GHS'}',
    );
  }

  Future<void> refreshTransactions() async {
    await _loadTransactions();
  }

  void addTransaction(Transaction transaction) {
    state = [transaction, ...state];
  }
}