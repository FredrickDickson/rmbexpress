import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:flutter_animate/flutter_animate.dart';
import '../core/providers/exchange_rate_provider.dart';
import '../core/models/exchange_rate_model.dart';

class CurrencySelector extends ConsumerWidget {
  final Function(String) onCurrencyChanged;

  const CurrencySelector({
    super.key,
    required this.onCurrencyChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCurrency = ref.watch(selectedCurrencyProvider);
    final exchangeRates = ref.watch(exchangeRatesProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.currency_exchange,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'From Currency',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: exchangeRates.entries.map((entry) {
                final currency = entry.key;
                final rate = entry.value;
                final isSelected = currency == selectedCurrency;
                
                return _CurrencyChip(
                  currency: currency,
                  rate: rate,
                  isSelected: isSelected,
                  onTap: () {
                    ref.read(selectedCurrencyProvider.notifier).state = currency;
                    onCurrencyChanged(currency);
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _CurrencyChip extends StatelessWidget {
  final String currency;
  final ExchangeRate rate;
  final bool isSelected;
  final VoidCallback onTap;

  const _CurrencyChip({
    required this.currency,
    required this.rate,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                : Colors.grey.shade100,
            border: Border.all(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Text(
                currency,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              
              const SizedBox(height: 4),
              
              Text(
                '¥${rate.rate.toStringAsFixed(3)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
              
              const SizedBox(height: 2),
              
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    rate.isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                    size: 10,
                    color: rate.isPositive ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    '${rate.changePercent.toStringAsFixed(2)}%',
                    style: TextStyle(
                      fontSize: 10,
                      color: rate.isPositive ? Colors.green : Colors.red,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}