class User {
  final String id;
  final String name;
  final String email;
  final double balance;
  final String currency;

  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.balance,
    this.currency = 'RMB',
  });
}