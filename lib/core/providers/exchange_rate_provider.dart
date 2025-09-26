import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/exchange_rate_model.dart';

final exchangeRatesProvider = StateNotifierProvider<ExchangeRatesNotifier, Map<String, ExchangeRate>>((ref) {
  return ExchangeRatesNotifier();
});

final selectedCurrencyProvider = StateProvider<String>((ref) => 'GHS');

class ExchangeRatesNotifier extends StateNotifier<Map<String, ExchangeRate>> {
  ExchangeRatesNotifier() : super(_mockRates) {
    _startRateUpdates();
  }

  static final _mockRates = {
    'GHS': ExchangeRate(
      fromCurrency: 'GHS',
      toCurrency: 'RMB',
      rate: 0.58,
      lastUpdated: DateTime.now(),
      changePercent: 0.12,
    ),
    'USD': ExchangeRate(
      fromCurrency: 'USD',
      toCurrency: 'RMB',
      rate: 7.23,
      lastUpdated: DateTime.now(),
      changePercent: 0.15,
    ),
    'EUR': ExchangeRate(
      fromCurrency: 'EUR',
      toCurrency: 'RMB',
      rate: 7.89,
      lastUpdated: DateTime.now(),
      changePercent: -0.08,
    ),
    'GBP': ExchangeRate(
      fromCurrency: 'GBP',
      toCurrency: 'RMB',
      rate: 9.12,
      lastUpdated: DateTime.now(),
      changePercent: 0.23,
    ),
    'JPY': ExchangeRate(
      fromCurrency: 'JPY',
      toCurrency: 'RMB',
      rate: 0.049,
      lastUpdated: DateTime.now(),
      changePercent: -0.12,
    ),
  };

  void _startRateUpdates() {
    // Simulate real-time rate updates
    Future.delayed(const Duration(seconds: 30), () {
      _updateRates();
    });
  }

  void _updateRates() {
    final updatedRates = <String, ExchangeRate>{};
    
    for (final entry in state.entries) {
      final currency = entry.key;
      final currentRate = entry.value;
      
      // Simulate small rate changes
      final changeAmount = (currentRate.rate * 0.002) * (0.5 - (DateTime.now().millisecond % 1000) / 1000);
      final newRate = currentRate.rate + changeAmount;
      final changePercent = ((newRate - currentRate.rate) / currentRate.rate) * 100;
      
      updatedRates[currency] = ExchangeRate(
        fromCurrency: currency,
        toCurrency: 'RMB',
        rate: newRate,
        lastUpdated: DateTime.now(),
        changePercent: changePercent,
      );
    }
    
    state = updatedRates;
    _startRateUpdates();
  }

  void refreshRates() {
    _updateRates();
  }
}