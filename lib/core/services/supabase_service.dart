import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL', 
      defaultValue: 'https://your-project.supabase.co');
  static const String supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY', 
      defaultValue: 'your-anon-key');

  late final SupabaseClient _client;
  SupabaseClient get client => _client;

  /// Initialize Supabase client
  Future<void> initialize() async {
    try {
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
        debug: kDebugMode,
      );
      _client = Supabase.instance.client;
      debugPrint('✅ Supabase initialized successfully');
    } catch (e) {
      debugPrint('❌ Error initializing Supabase: $e');
      rethrow;
    }
  }

  /// Get current user
  User? get currentUser => _client.auth.currentUser;

  /// Check if user is authenticated
  bool get isAuthenticated => currentUser != null;

  /// Sign up with email and password
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    Map<String, dynamic>? data,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: data,
      );
      return response;
    } catch (e) {
      debugPrint('Error signing up: $e');
      rethrow;
    }
  }

  /// Sign in with email and password
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response;
    } catch (e) {
      debugPrint('Error signing in: $e');
      rethrow;
    }
  }

  /// Sign in with Google OAuth (web implementation)
  Future<void> signInWithGoogle() async {
    try {
      await _client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: kIsWeb ? null : 'io.supabase.buyrmbonline://callback',
      );
      // On web, this will redirect to Google OAuth
      // Auth state changes will be handled by the auth stream
    } catch (e) {
      debugPrint('Error signing in with Google: $e');
      rethrow;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (e) {
      debugPrint('Error signing out: $e');
      rethrow;
    }
  }

  /// Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(email);
    } catch (e) {
      debugPrint('Error resetting password: $e');
      rethrow;
    }
  }

  /// Listen to auth state changes
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  /// Get current user's profile
  Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    try {
      final user = currentUser;
      if (user == null) return null;

      final profiles = await _client
          .from('profiles')
          .select('*')
          .eq('user_id', user.id);

      if (profiles.isEmpty) return null;
      return profiles.first;
    } catch (e) {
      debugPrint('Error getting user profile: $e');
      return null;
    }
  }

  /// Get current user's role
  Future<String?> getCurrentUserRole() async {
    try {
      final profile = await getCurrentUserProfile();
      return profile?['role'] as String?;
    } catch (e) {
      debugPrint('Error getting user role: $e');
      return null;
    }
  }

  /// Generate unique transaction reference ID
  String _generateTransactionReference() {
    final now = DateTime.now();
    final dateStr = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final timeStr = '${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';
    final random = (DateTime.now().millisecondsSinceEpoch % 10000).toString().padLeft(4, '0');
    return 'TXN$dateStr$timeStr$random';
  }

  /// Create a new transaction record (uses authenticated user)
  Future<Map<String, dynamic>?> createTransaction({
    required double amount,
    required String fromCurrency,
    required String toCurrency,
    required double exchangeRate,
    required String status,
    String? paymentMethod,
    Map<String, dynamic>? recipientDetails,
    String? paystackReference,
  }) async {
    final user = currentUser;
    if (user == null) {
      throw Exception('User must be authenticated to create transactions');
    }

    try {
      final referenceId = _generateTransactionReference();
      
      final response = await _client
          .from('transactions')
          .insert({
            'user_id': user.id, // Use authenticated user ID
            'amount': amount,
            'from_currency': fromCurrency,
            'to_currency': toCurrency,
            'exchange_rate': exchangeRate,
            'status': status,
            'payment_method': paymentMethod,
            'reference_id': referenceId,
            if (recipientDetails != null) 'recipient_details': recipientDetails,
            if (paystackReference != null) 'paystack_reference': paystackReference,
            // Remove client-side timestamp, let DB handle it
          })
          .select()
          .single();
      
      return response;
    } catch (e) {
      debugPrint('Error creating transaction: $e');
      rethrow;
    }
  }

  /// Get user transactions (for authenticated user only)
  Future<List<Map<String, dynamic>>> getUserTransactions() async {
    final user = currentUser;
    if (user == null) {
      throw Exception('User must be authenticated to view transactions');
    }

    try {
      final response = await _client
          .from('transactions')
          .select()
          .eq('user_id', user.id) // Use authenticated user ID
          .order('created_at', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching transactions: $e');
      rethrow;
    }
  }

  /// Update user profile (for authenticated user only)
  Future<Map<String, dynamic>?> updateProfile({
    String? fullName,
    String? phoneNumber,
    String? address,
  }) async {
    final user = currentUser;
    if (user == null) {
      throw Exception('User must be authenticated to update profile');
    }

    try {
      final response = await _client
          .from('profiles')
          .update({
            if (fullName != null) 'full_name': fullName,
            if (phoneNumber != null) 'phone_number': phoneNumber,
            if (address != null) 'address': address,
            // Remove client-side timestamp, let DB handle it
          })
          .eq('id', user.id) // Use authenticated user ID
          .select()
          .single();
      
      return response;
    } catch (e) {
      debugPrint('Error updating profile: $e');
      rethrow;
    }
  }

  /// Get user profile (for authenticated user only)
  Future<Map<String, dynamic>?> getUserProfile() async {
    final user = currentUser;
    if (user == null) {
      throw Exception('User must be authenticated to view profile');
    }

    try {
      final response = await _client
          .from('profiles')
          .select()
          .eq('id', user.id) // Use authenticated user ID
          .single();
      
      return response;
    } catch (e) {
      debugPrint('Error fetching profile: $e');
      return null;
    }
  }

  /// Create or update user profile (for new user registration)
  Future<Map<String, dynamic>?> createOrUpdateProfile({
    String? fullName,
    String? phoneNumber,
    String? address,
  }) async {
    final user = currentUser;
    if (user == null) {
      throw Exception('User must be authenticated to create profile');
    }

    try {
      final response = await _client
          .from('profiles')
          .upsert({
            'id': user.id,
            'email': user.email,
            if (fullName != null) 'full_name': fullName,
            if (phoneNumber != null) 'phone_number': phoneNumber,
            if (address != null) 'address': address,
          })
          .select()
          .single();
      
      return response;
    } catch (e) {
      debugPrint('Error creating/updating profile: $e');
      rethrow;
    }
  }
}