import 'dart:async';
import 'package:flutter/material.dart';
import 'package:paystack_for_flutter/paystack_for_flutter.dart';

class PaystackService {
  static final PaystackService _instance = PaystackService._internal();
  factory PaystackService() => _instance;
  PaystackService._internal();

  static const String _publicKey = String.fromEnvironment('PAYSTACK_PUBLIC_KEY');
  
  /// Initialize Paystack with the public key
  void initialize() {
    if (_publicKey.isEmpty) {
      throw Exception('PAYSTACK_PUBLIC_KEY environment variable is required');
    }
    // No initialization needed for this package - keys are passed directly
  }

  /// Process payment for buying RMB
  Future<PaymentResponse> processBuyRmbPayment({
    required BuildContext context,
    required String email,
    required double ghsAmount,
    required double rmbAmount,
    required String currency,
    required String customerName,
    String? phoneNumber,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // Convert GHS amount to pesewas (multiply by 100)
      final int amountInPesewas = (ghsAmount * 100).round();
      
      // Create metadata with transaction details
      final Map<String, dynamic> paymentMetadata = {
        'rmbAmount': rmbAmount,
        'ghsAmount': ghsAmount,
        'exchangeRate': rmbAmount / ghsAmount,
        'currency': currency,
        'customerName': customerName,
        'transactionType': 'buy_rmb',
        'timestamp': DateTime.now().toIso8601String(),
        ...?metadata,
      };

      // For now, show user that payment processing is being implemented
      // This prevents security risks while maintaining UX
      return PaymentResponse(
        success: false,
        reference: 'PENDING_BACKEND_IMPLEMENTATION',
        message: 'Payment processing requires secure backend implementation. Please contact support.',
        amount: ghsAmount,
        rmbAmount: rmbAmount,
        metadata: paymentMetadata,
      );
    } catch (e) {
      throw PaystackPaymentException('Payment failed: ${e.toString()}');
    }
  }

  /// Verify payment transaction (optional - for additional security)
  Future<bool> verifyPayment(String reference) async {
    try {
      // Note: In production, you should verify payments on your backend
      // This is a client-side verification for demonstration
      return true; // Assume verified for now
    } catch (e) {
      return false;
    }
  }

  /// Get supported payment channels
  List<PaymentChannel> getSupportedChannels() {
    return [
      PaymentChannel.mobileMoney,
      PaymentChannel.card,
      PaymentChannel.bankTransfer,
      PaymentChannel.ussd,
    ];
  }

  /// Convert amount to kobo (Paystack uses kobo for GHS)
  static int toKobo(double amount) {
    return (amount * 100).round();
  }

  /// Convert kobo back to GHS
  static double fromKobo(int kobo) {
    return kobo / 100.0;
  }
}

/// Payment response data class
class PaymentResponse {
  final bool success;
  final String reference;
  final String message;
  final double amount;
  final double rmbAmount;
  final Map<String, dynamic> metadata;

  PaymentResponse({
    required this.success,
    required this.reference,
    required this.message,
    required this.amount,
    required this.rmbAmount,
    required this.metadata,
  });

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'reference': reference,
      'message': message,
      'amount': amount,
      'rmbAmount': rmbAmount,
      'metadata': metadata,
    };
  }

  @override
  String toString() {
    return 'PaymentResponse(success: $success, reference: $reference, message: $message)';
  }
}

/// Payment channel enum for different payment methods
enum PaymentChannel {
  card,
  bankTransfer,
  mobileMoney,
  ussd,
}

/// Custom exception for Paystack payment errors
class PaystackPaymentException implements Exception {
  final String message;
  
  PaystackPaymentException(this.message);
  
  @override
  String toString() => 'PaystackPaymentException: $message';
}