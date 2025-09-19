enum TransactionType { buy, send, receive }
enum TransactionStatus { completed, pending, failed }

class Transaction {
  final String id;
  final TransactionType type;
  final double amount;
  final String currency;
  final TransactionStatus status;
  final DateTime date;
  final String? recipient;
  final String? description;

  const Transaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.currency,
    required this.status,
    required this.date,
    this.recipient,
    this.description,
  });
}