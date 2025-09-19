import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';

// Mock user data
final userProvider = StateNotifierProvider<UserNotifier, User>((ref) {
  return UserNotifier();
});

class UserNotifier extends StateNotifier<User> {
  UserNotifier() : super(_mockUser);

  static const _mockUser = User(
    id: '1',
    name: 'John Chen',
    email: 'john.chen@example.com',
    balance: 15847.50,
    currency: 'RMB',
  );

  void updateBalance(double newBalance) {
    state = User(
      id: state.id,
      name: state.name,
      email: state.email,
      balance: newBalance,
      currency: state.currency,
    );
  }
}