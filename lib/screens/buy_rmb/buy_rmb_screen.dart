import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/exchange_rate_provider.dart';
import '../../core/models/exchange_rate_model.dart';
import '../../widgets/currency_selector.dart';
import '../../widgets/amount_input.dart';

class BuyRmbScreen extends ConsumerStatefulWidget {
  const BuyRmbScreen({super.key});

  @override
  ConsumerState<BuyRmbScreen> createState() => _BuyRmbScreenState();
}

class _BuyRmbScreenState extends ConsumerState<BuyRmbScreen> {
  final _amountController = TextEditingController();
  double _amount = 0;
  bool _isProcessing = false;
  String _selectedPaymentMethod = 'card';

  @override
  Widget build(BuildContext context) {
    final selectedCurrency = ref.watch(selectedCurrencyProvider);
    final exchangeRates = ref.watch(exchangeRatesProvider);
    final currentRate = exchangeRates[selectedCurrency];
    
    if (currentRate == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Buy RMB'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading exchange rates...'),
            ],
          ),
        ),
      );
    }

    final rmbAmount = _amount * currentRate.rate;
    final canProceed = _amount > 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Buy RMB'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(exchangeRatesProvider.notifier).refreshRates();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Exchange rates updated'),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                ),
              );
            },
          ),
        ],
      ),
      
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.currency_exchange,
                    color: Theme.of(context).colorScheme.primary,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Exchange Currency to RMB',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Get the best exchange rates for Chinese Renminbi',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // Currency Selector
            CurrencySelector(
              onCurrencyChanged: (currency) {
                // Update amount display when currency changes
                if (_amount > 0) {
                  setState(() {});
                }
              },
            ),
            
            const SizedBox(height: 16),
            
            // Amount Input
            AmountInput(
              currency: selectedCurrency,
              exchangeRate: currentRate.rate,
              controller: _amountController,
              onAmountChanged: (amount) {
                setState(() => _amount = amount);
              },
            ),
            
            const SizedBox(height: 16),
            
            // Exchange Rate Info
            _ExchangeRateInfo(rate: currentRate),
            
            const SizedBox(height: 24),
            
            // Payment Method
            _PaymentMethodSelector(
              selectedMethod: _selectedPaymentMethod,
              onMethodChanged: (method) {
                setState(() => _selectedPaymentMethod = method);
              },
            ),
            
            const SizedBox(height: 32),
            
            // Transaction Summary
            if (canProceed) ...[
              _TransactionSummary(
                fromAmount: _amount,
                fromCurrency: selectedCurrency,
                toAmount: rmbAmount,
                rate: currentRate.rate,
                paymentMethod: _selectedPaymentMethod,
              ),
              
              const SizedBox(height: 24),
            ],
            
            // Continue Button
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: canProceed && !_isProcessing ? _handleBuyRmb : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300,
                ),
                child: _isProcessing
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          SizedBox(width: 12),
                          Text('Processing...'),
                        ],
                      )
                    : Text(
                        canProceed
                            ? 'Buy ¥${rmbAmount.toStringAsFixed(2)} RMB'
                            : 'Enter Amount to Continue',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Disclaimer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.amber.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Exchange rates may fluctuate. Final amount will be confirmed before processing.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.amber.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleBuyRmb() async {
    setState(() => _isProcessing = true);
    
    try {
      // Simulate payment processing
      await Future.delayed(const Duration(seconds: 3));
      
      if (mounted) {
        // Show success dialog
        await showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (context) => _SuccessDialog(
            amount: _amount,
            currency: ref.read(selectedCurrencyProvider),
            rmbAmount: _amount * (ref.read(exchangeRatesProvider)[ref.read(selectedCurrencyProvider)]?.rate ?? 1),
          ),
        );
        
        // Navigate back to dashboard
        if (context.mounted) {
          context.pop();
        }
      }
    } catch (e) {
      // Show error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Transaction failed: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }
}

class _ExchangeRateInfo extends StatelessWidget {
  final ExchangeRate rate;

  const _ExchangeRateInfo({required this.rate});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.trending_up,
              color: rate.isPositive ? Colors.green : Colors.red,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '1 ${rate.fromCurrency} = ¥${rate.rate.toStringAsFixed(4)} RMB',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Updated ${_formatTime(rate.lastUpdated)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: (rate.isPositive ? Colors.green : Colors.red).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${rate.isPositive ? '+' : ''}${rate.changePercent.toStringAsFixed(2)}%',
                style: TextStyle(
                  color: rate.isPositive ? Colors.green : Colors.red,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    
    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else {
      return '${difference.inHours}h ago';
    }
  }
}

class _PaymentMethodSelector extends StatelessWidget {
  final String selectedMethod;
  final Function(String) onMethodChanged;

  const _PaymentMethodSelector({
    required this.selectedMethod,
    required this.onMethodChanged,
  });

  @override
  Widget build(BuildContext context) {
    final methods = [
      {'id': 'card', 'name': 'Credit/Debit Card', 'icon': Icons.credit_card},
      {'id': 'bank', 'name': 'Bank Transfer', 'icon': Icons.account_balance},
      {'id': 'wallet', 'name': 'DIGITAL WALLET OR MOMO', 'icon': Icons.wallet},
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.payment,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Payment Method',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...methods.map((method) {
              final isSelected = method['id'] == selectedMethod;
              return InkWell(
                onTap: () => onMethodChanged(method['id'] as String),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey.shade300,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        method['icon'] as IconData,
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey.shade600,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          method['name'] as String,
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : null,
                          ),
                        ),
                      ),
                      if (isSelected)
                        Icon(
                          Icons.check_circle,
                          color: Theme.of(context).colorScheme.primary,
                          size: 20,
                        ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _TransactionSummary extends StatelessWidget {
  final double fromAmount;
  final String fromCurrency;
  final double toAmount;
  final double rate;
  final String paymentMethod;

  const _TransactionSummary({
    required this.fromAmount,
    required this.fromCurrency,
    required this.toAmount,
    required this.rate,
    required this.paymentMethod,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.receipt_long,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Transaction Summary',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _SummaryRow(
              label: 'You pay',
              value: '${_getCurrencySymbol(fromCurrency)}${fromAmount.toStringAsFixed(2)} $fromCurrency',
            ),
            const SizedBox(height: 8),
            _SummaryRow(
              label: 'Exchange rate',
              value: '1 $fromCurrency = ¥${rate.toStringAsFixed(4)}',
            ),
            const SizedBox(height: 8),
            _SummaryRow(
              label: 'Payment method',
              value: _getPaymentMethodName(paymentMethod),
            ),
            const Divider(height: 24),
            _SummaryRow(
              label: 'You receive',
              value: '¥${toAmount.toStringAsFixed(2)} RMB',
              isTotal: true,
            ),
          ],
        ),
      ),
    );
  }

  String _getCurrencySymbol(String currency) {
    switch (currency) {
      case 'GHS': return '₵';
      case 'USD': return '\$';
      case 'EUR': return '€';
      case 'GBP': return '£';
      case 'JPY': return '¥';
      default: return '';
    }
  }

  String _getPaymentMethodName(String method) {
    switch (method) {
      case 'card': return 'Credit/Debit Card';
      case 'bank': return 'Bank Transfer';
      case 'wallet': return 'DIGITAL WALLET OR MOMO';
      default: return method;
    }
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isTotal;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.isTotal = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            color: isTotal ? Theme.of(context).colorScheme.primary : null,
          ),
        ),
      ],
    );
  }
}

class _SuccessDialog extends StatelessWidget {
  final double amount;
  final String currency;
  final double rmbAmount;

  const _SuccessDialog({
    required this.amount,
    required this.currency,
    required this.rmbAmount,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check,
                color: Colors.green,
                size: 32,
              ),
            ),
            
            const SizedBox(height: 16),
            
            Text(
              'Transaction Successful!',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            
            const SizedBox(height: 8),
            
            Text(
              'You have successfully exchanged $currency ${amount.toStringAsFixed(2)} for ¥${rmbAmount.toStringAsFixed(2)} RMB',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 24),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}