import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class AdminService {
  final _supabase = Supabase.instance.client;

  // Check if current user has admin role
  Future<bool> isCurrentUserAdmin() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      final profiles = await _supabase
          .from('profiles')
          .select('role')
          .eq('user_id', user.id);

      if (profiles.isEmpty) return false;
      
      final role = profiles.first['role'] as String?;
      return role == 'admin' || role == 'super_admin';
    } catch (e) {
      debugPrint('Error checking admin role: $e');
      return false;
    }
  }

  // Get current user's admin profile
  Future<Map<String, dynamic>?> getCurrentAdminProfile() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      final profiles = await _supabase
          .from('profiles')
          .select('*')
          .eq('user_id', user.id);

      if (profiles.isEmpty) return null;

      final profile = profiles.first;
      final role = profile['role'] as String?;
      if (role != 'admin' && role != 'super_admin') {
        return null;
      }

      return profile;
    } catch (e) {
      debugPrint('Error getting admin profile: $e');
      return null;
    }
  }

  // Analytics & Monitoring
  Future<Map<String, dynamic>> getDashboardAnalytics() async {
    try {
      // Get all users
      final allUsers = await _supabase
          .from('profiles')
          .select('id');

      // Get all transactions
      final allTransactions = await _supabase
          .from('transactions')
          .select('*');

      // Process transactions
      int pendingCount = 0;
      int completedCount = 0;
      double totalVolumeGHS = 0.0;
      double totalVolumeRMB = 0.0;
      int todayCount = 0;

      final today = DateTime.now().toIso8601String().split('T')[0];

      for (final transaction in allTransactions) {
        final status = transaction['status'] as String? ?? '';
        final amount = (transaction['amount'] as num?)?.toDouble() ?? 0.0;
        final convertedAmount = (transaction['converted_amount'] as num?)?.toDouble() ?? 0.0;
        final createdAt = transaction['created_at'] as String? ?? '';

        if (status == 'pending') pendingCount++;
        if (status == 'completed') {
          completedCount++;
          totalVolumeGHS += amount;
          totalVolumeRMB += convertedAmount;
        }

        if (createdAt.startsWith(today)) {
          todayCount++;
        }
      }

      // Get recent transactions with user info
      final recentTransactions = await _supabase
          .from('transactions')
          .select('*, profiles!transactions_user_id_fkey(full_name)')
          .order('created_at', ascending: false)
          .limit(10);

      return {
        'total_users': allUsers.length,
        'total_transactions': allTransactions.length,
        'pending_transactions': pendingCount,
        'completed_transactions': completedCount,
        'total_volume_ghs': totalVolumeGHS,
        'total_volume_rmb': totalVolumeRMB,
        'today_transactions': todayCount,
        'recent_transactions': recentTransactions,
      };
    } catch (e) {
      print('Error getting dashboard analytics: $e');
      throw e;
    }
  }

  // User Management
  Future<List<Map<String, dynamic>>> getAllUsers({
    int limit = 50,
    int offset = 0,
    String? searchQuery,
    String? roleFilter,
    String? kycFilter,
  }) async {
    try {
      var query = _supabase
          .from('profiles')
          .select('*')
          .order('created_at', ascending: false);

      final results = await query;

      // Apply filters in Dart since Supabase client doesn't support complex queries
      var filteredResults = results.where((profile) {
        // Search filter
        if (searchQuery != null && searchQuery.isNotEmpty) {
          final fullName = (profile['full_name'] as String? ?? '').toLowerCase();
          final email = (profile['email'] as String? ?? '').toLowerCase();
          final search = searchQuery.toLowerCase();
          if (!fullName.contains(search) && !email.contains(search)) {
            return false;
          }
        }

        // Role filter
        if (roleFilter != null && roleFilter != 'all') {
          if (profile['role'] != roleFilter) return false;
        }

        // KYC filter
        if (kycFilter != null && kycFilter != 'all') {
          if (profile['kyc_status'] != kycFilter) return false;
        }

        return true;
      }).toList();

      // Apply pagination
      final start = offset;
      final end = offset + limit;
      if (start >= filteredResults.length) return [];
      
      final endIndex = end > filteredResults.length ? filteredResults.length : end;
      return filteredResults.sublist(start, endIndex);
    } catch (e) {
      print('Error getting all users: $e');
      throw e;
    }
  }

  Future<Map<String, dynamic>?> getUserById(String userId) async {
    try {
      final results = await _supabase
          .from('profiles')
          .select('*')
          .eq('id', userId);
      
      return results.isNotEmpty ? results.first : null;
    } catch (e) {
      print('Error getting user by ID: $e');
      throw e;
    }
  }

  Future<void> updateUserKycStatus(String userId, String status) async {
    try {
      await _logAdminAction('update_kyc_status', 'profiles', userId, {'kyc_status': status});
      
      await _supabase
          .from('profiles')
          .update({'kyc_status': status, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', userId);
    } catch (e) {
      print('Error updating KYC status: $e');
      throw e;
    }
  }

  Future<void> suspendUser(String userId, String reason) async {
    try {
      final currentUser = await getCurrentAdminProfile();
      if (currentUser == null) throw 'Unauthorized';

      await _logAdminAction('suspend_user', 'profiles', userId, {
        'suspended': true,
        'reason': reason,
      });

      await _supabase
          .from('profiles')
          .update({
            'suspended_at': DateTime.now().toIso8601String(),
            'suspended_by': currentUser['id'],
            'suspension_reason': reason,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);
    } catch (e) {
      print('Error suspending user: $e');
      throw e;
    }
  }

  Future<void> unsuspendUser(String userId) async {
    try {
      await _logAdminAction('unsuspend_user', 'profiles', userId, {'suspended': false});

      await _supabase
          .from('profiles')
          .update({
            'suspended_at': null,
            'suspended_by': null,
            'suspension_reason': null,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);
    } catch (e) {
      print('Error unsuspending user: $e');
      throw e;
    }
  }

  // Transaction Management
  Future<List<Map<String, dynamic>>> getAllTransactions({
    int limit = 50,
    int offset = 0,
    String? statusFilter,
    String? searchQuery,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final transactions = await _supabase
          .from('transactions')
          .select('*, profiles!transactions_user_id_fkey(full_name, email)')
          .order('created_at', ascending: false);

      // Apply filters in Dart
      var filteredResults = transactions.where((transaction) {
        // Status filter
        if (statusFilter != null && statusFilter != 'all') {
          if (transaction['status'] != statusFilter) return false;
        }

        // Search filter
        if (searchQuery != null && searchQuery.isNotEmpty) {
          final referenceId = (transaction['reference_id'] as String? ?? '').toLowerCase();
          final paystackRef = (transaction['paystack_reference'] as String? ?? '').toLowerCase();
          final search = searchQuery.toLowerCase();
          if (!referenceId.contains(search) && !paystackRef.contains(search)) {
            return false;
          }
        }

        // Date filters
        if (startDate != null || endDate != null) {
          final createdAt = transaction['created_at'] as String?;
          if (createdAt != null) {
            final transactionDate = DateTime.parse(createdAt);
            if (startDate != null && transactionDate.isBefore(startDate)) return false;
            if (endDate != null && transactionDate.isAfter(endDate)) return false;
          }
        }

        return true;
      }).toList();

      // Apply pagination
      final start = offset;
      final end = offset + limit;
      if (start >= filteredResults.length) return [];
      
      final endIndex = end > filteredResults.length ? filteredResults.length : end;
      return filteredResults.sublist(start, endIndex);
    } catch (e) {
      print('Error getting all transactions: $e');
      throw e;
    }
  }

  Future<void> approveTransaction(String transactionId, String adminNotes) async {
    try {
      final currentUser = await getCurrentAdminProfile();
      if (currentUser == null) throw 'Unauthorized';

      await _logAdminAction('approve_transaction', 'transactions', transactionId, {
        'status': 'approved',
        'admin_notes': adminNotes,
      });

      await _supabase
          .from('transactions')
          .update({
            'status': 'approved',
            'reviewed_by': currentUser['id'],
            'reviewed_at': DateTime.now().toIso8601String(),
            'admin_notes': adminNotes,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', transactionId);
    } catch (e) {
      print('Error approving transaction: $e');
      throw e;
    }
  }

  Future<void> rejectTransaction(String transactionId, String reason) async {
    try {
      final currentUser = await getCurrentAdminProfile();
      if (currentUser == null) throw 'Unauthorized';

      await _logAdminAction('reject_transaction', 'transactions', transactionId, {
        'status': 'rejected',
        'admin_notes': reason,
      });

      await _supabase
          .from('transactions')
          .update({
            'status': 'rejected',
            'reviewed_by': currentUser['id'],
            'reviewed_at': DateTime.now().toIso8601String(),
            'admin_notes': reason,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', transactionId);
    } catch (e) {
      print('Error rejecting transaction: $e');
      throw e;
    }
  }

  // System Configuration
  Future<List<Map<String, dynamic>>> getSystemConfig({String? category}) async {
    try {
      final configs = await _supabase
          .from('system_config')
          .select('*')
          .order('category')
          .order('key');

      if (category != null && category != 'all') {
        return configs.where((config) => config['category'] == category).toList();
      }

      return configs;
    } catch (e) {
      print('Error getting system config: $e');
      throw e;
    }
  }

  Future<void> updateSystemConfig(String key, dynamic value, String? description) async {
    try {
      final currentUser = await getCurrentAdminProfile();
      if (currentUser == null) throw 'Unauthorized';

      await _logAdminAction('update_config', 'system_config', key, {
        'key': key,
        'value': value,
        'description': description,
      });

      await _supabase
          .from('system_config')
          .upsert({
            'key': key,
            'value': value,
            'description': description,
            'updated_by': currentUser['id'],
            'updated_at': DateTime.now().toIso8601String(),
          });
    } catch (e) {
      print('Error updating system config: $e');
      throw e;
    }
  }

  Future<List<Map<String, dynamic>>> getExchangeRates() async {
    try {
      return await _supabase
          .from('exchange_rates')
          .select('*, profiles!exchange_rates_created_by_fkey(full_name)')
          .order('created_at', ascending: false);
    } catch (e) {
      print('Error getting exchange rates: $e');
      throw e;
    }
  }

  Future<void> updateExchangeRate(String baseCurrency, String quoteCurrency, double rate) async {
    try {
      final currentUser = await getCurrentAdminProfile();
      if (currentUser == null) throw 'Unauthorized';

      await _logAdminAction('update_exchange_rate', 'exchange_rates', '$baseCurrency-$quoteCurrency', {
        'base_currency': baseCurrency,
        'quote_currency': quoteCurrency,
        'rate': rate,
      });

      await _supabase
          .from('exchange_rates')
          .insert({
            'base_currency': baseCurrency,
            'quote_currency': quoteCurrency,
            'rate': rate,
            'source': 'manual',
            'created_by': currentUser['id'],
          });
    } catch (e) {
      print('Error updating exchange rate: $e');
      throw e;
    }
  }

  Future<List<Map<String, dynamic>>> getPaymentMethods() async {
    try {
      return await _supabase
          .from('payment_methods')
          .select('*')
          .order('name');
    } catch (e) {
      print('Error getting payment methods: $e');
      throw e;
    }
  }

  Future<void> togglePaymentMethod(String methodId, bool enabled) async {
    try {
      final currentUser = await getCurrentAdminProfile();
      if (currentUser == null) throw 'Unauthorized';

      await _logAdminAction('toggle_payment_method', 'payment_methods', methodId, {
        'enabled': enabled,
      });

      await _supabase
          .from('payment_methods')
          .update({
            'enabled': enabled,
            'updated_by': currentUser['id'],
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', methodId);
    } catch (e) {
      print('Error toggling payment method: $e');
      throw e;
    }
  }

  // Financial Reports
  Future<Map<String, dynamic>> getFinancialReport({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final start = startDate ?? DateTime.now().subtract(const Duration(days: 30));
      final end = endDate ?? DateTime.now();

      // Get all transactions in date range
      final allTransactions = await _supabase
          .from('transactions')
          .select('*');

      final transactions = allTransactions.where((transaction) {
        final createdAt = transaction['created_at'] as String?;
        if (createdAt == null) return false;
        
        final transactionDate = DateTime.parse(createdAt);
        return !transactionDate.isBefore(start) && !transactionDate.isAfter(end);
      }).toList();

      int totalTransactions = transactions.length;
      int completedTransactions = 0;
      double totalRevenue = 0.0;
      double totalVolume = 0.0;

      for (final transaction in transactions) {
        if (transaction['status'] == 'completed') {
          completedTransactions++;
          final amount = (transaction['amount'] as num?)?.toDouble() ?? 0.0;
          totalVolume += amount;
          // Calculate revenue (assuming 2% fee)
          totalRevenue += amount * 0.02;
        }
      }

      // Get daily breakdown
      final dailyStats = <String, Map<String, dynamic>>{};
      for (final transaction in transactions) {
        final date = DateTime.parse(transaction['created_at']).toIso8601String().split('T')[0];
        if (!dailyStats.containsKey(date)) {
          dailyStats[date] = {
            'date': date,
            'transactions': 0,
            'completed': 0,
            'volume': 0.0,
            'revenue': 0.0,
          };
        }
        
        dailyStats[date]!['transactions'] += 1;
        if (transaction['status'] == 'completed') {
          dailyStats[date]!['completed'] += 1;
          final amount = (transaction['amount'] as num?)?.toDouble() ?? 0.0;
          dailyStats[date]!['volume'] += amount;
          dailyStats[date]!['revenue'] += amount * 0.02;
        }
      }

      return {
        'summary': {
          'total_transactions': totalTransactions,
          'completed_transactions': completedTransactions,
          'completion_rate': totalTransactions > 0 ? (completedTransactions / totalTransactions) : 0.0,
          'total_revenue': totalRevenue,
          'total_volume': totalVolume,
          'average_transaction': completedTransactions > 0 ? (totalVolume / completedTransactions) : 0.0,
        },
        'daily_breakdown': dailyStats.values.toList()..sort((a, b) => a['date'].compareTo(b['date'])),
        'period': {
          'start_date': start.toIso8601String(),
          'end_date': end.toIso8601String(),
        },
      };
    } catch (e) {
      print('Error getting financial report: $e');
      throw e;
    }
  }

  // Audit Logging
  Future<List<Map<String, dynamic>>> getAuditLogs({
    int limit = 100,
    int offset = 0,
    String? actionFilter,
    String? entityFilter,
  }) async {
    try {
      final logs = await _supabase
          .from('audit_logs')
          .select('*, profiles!audit_logs_actor_id_fkey(full_name)')
          .order('created_at', ascending: false);

      var filteredLogs = logs.where((log) {
        if (actionFilter != null && actionFilter != 'all') {
          if (log['action'] != actionFilter) return false;
        }

        if (entityFilter != null && entityFilter != 'all') {
          if (log['entity_type'] != entityFilter) return false;
        }

        return true;
      }).toList();

      // Apply pagination
      final start = offset;
      final end = offset + limit;
      if (start >= filteredLogs.length) return [];
      
      final endIndex = end > filteredLogs.length ? filteredLogs.length : end;
      return filteredLogs.sublist(start, endIndex);
    } catch (e) {
      print('Error getting audit logs: $e');
      throw e;
    }
  }

  Future<void> _logAdminAction(
    String action,
    String entityType,
    String entityId,
    Map<String, dynamic> afterData, {
    Map<String, dynamic>? beforeData,
  }) async {
    try {
      final currentUser = await getCurrentAdminProfile();
      if (currentUser == null) return;

      await _supabase.from('audit_logs').insert({
        'actor_id': currentUser['id'],
        'action': action,
        'entity_type': entityType,
        'entity_id': entityId,
        'before_data': beforeData,
        'after_data': afterData,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error logging admin action: $e');
    }
  }
}