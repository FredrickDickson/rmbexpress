import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../services/supabase_service.dart';

// Real user data from Supabase
final userProvider = StateNotifierProvider<UserNotifier, User>((ref) {
  return UserNotifier();
});

class UserNotifier extends StateNotifier<User> {
  final _supabaseService = SupabaseService();
  
  UserNotifier() : super(_defaultUser) {
    _loadUserData();
  }

  static const _defaultUser = User(
    id: '',
    name: 'Loading...',
    email: '',
    balance: 0.0,
    currency: 'RMB',
  );

  Future<void> _loadUserData() async {
    try {
      final user = _supabaseService.currentUser;
      if (user == null) return;
      
      // Get user profile data
      final profile = await _supabaseService.getUserProfile();
      
      // Calculate balance from completed transactions
      final transactions = await _supabaseService.getUserTransactions();
      double totalRmb = 0.0;
      
      for (final transaction in transactions) {
        if (transaction['status'] == 'completed') {
          final amount = (transaction['amount'] as num?)?.toDouble() ?? 0.0;
          final exchangeRate = (transaction['exchange_rate'] as num?)?.toDouble() ?? 1.0;
          totalRmb += (amount * exchangeRate); // RMB amount received
        }
      }
      
      state = User(
        id: user.id,
        name: profile?['full_name'] ?? _extractNameFromEmail(user.email ?? ''),
        email: user.email ?? '',
        balance: totalRmb,
        currency: 'RMB',
      );
    } catch (e) {
      // Keep default state if loading fails
      debugPrint('Failed to load user data: $e');
    }
  }

  String _extractNameFromEmail(String email) {
    if (email.isEmpty) return 'User';
    final parts = email.split('@');
    if (parts.isEmpty) return 'User';
    final localPart = parts.first;
    if (localPart.isEmpty) return 'User';
    
    // Convert email like john.doe to John Doe
    final nameParts = localPart.split('.');
    final processedParts = nameParts
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .toList();
    
    return processedParts.isNotEmpty ? processedParts.join(' ') : 'User';
  }

  Future<void> refreshUserData() async {
    await _loadUserData();
  }

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