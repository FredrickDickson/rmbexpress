import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// import 'package:flutter_animate/flutter_animate.dart';

class AmountInput extends StatefulWidget {
  final String currency;
  final double exchangeRate;
  final Function(double) onAmountChanged;
  final TextEditingController? controller;

  const AmountInput({
    super.key,
    required this.currency,
    required this.exchangeRate,
    required this.onAmountChanged,
    this.controller,
  });

  @override
  State<AmountInput> createState() => _AmountInputState();
}

class _AmountInputState extends State<AmountInput> with TickerProviderStateMixin {
  late TextEditingController _controller;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  double _amount = 0;
  bool _showRmbAmount = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _controller.addListener(_onAmountTextChanged);
    
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );
  }

  @override
  void dispose() {
    _controller.removeListener(_onAmountTextChanged);
    if (widget.controller == null) {
      _controller.dispose();
    }
    _shakeController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(AmountInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      _controller.removeListener(_onAmountTextChanged);
      _controller = widget.controller ?? TextEditingController();
      _controller.addListener(_onAmountTextChanged);
    }
  }

  void _onAmountTextChanged() {
    final text = _controller.text;
    final amount = double.tryParse(text) ?? 0;
    
    if (amount != _amount) {
      setState(() {
        _amount = amount;
        _showRmbAmount = amount > 0;
      });
      widget.onAmountChanged(amount);
    }
  }

  void _setQuickAmount(double amount) {
    _controller.text = amount.toStringAsFixed(0);
    
    // Animate input focus
    _shakeController.forward().then((_) {
      _shakeController.reverse();
    });
  }

  @override
  Widget build(BuildContext context) {
    final rmbAmount = _amount * widget.exchangeRate;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.payments_outlined,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Enter Amount',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Amount input
            AnimatedBuilder(
              animation: _shakeAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(_shakeAnimation.value, 0),
                  child: TextField(
                    controller: _controller,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}$')),
                    ],
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      hintText: '0.00',
                      prefixText: _getCurrencySymbol(widget.currency),
                      prefixStyle: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.primary.withOpacity(0.05),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                    ),
                  ),
                );
              },
            ),
            
            // RMB conversion
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _showRmbAmount
                  ? Container(
                      key: const ValueKey('rmb_amount'),
                      margin: const EdgeInsets.only(top: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).colorScheme.primary.withOpacity(0.1),
                            Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.swap_horiz,
                            color: Theme.of(context).colorScheme.primary,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'You will receive',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const Spacer(),
                          Text(
                            '¥${rmbAmount.toStringAsFixed(2)}',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(key: ValueKey('empty')),
            ),
            
            const SizedBox(height: 20),
            
            // Quick amount buttons
            Text(
              'Quick Amounts',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            
            const SizedBox(height: 12),
            
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _getQuickAmounts().map((amount) {
                return _QuickAmountButton(
                  amount: amount,
                  currency: widget.currency,
                  onTap: () => _setQuickAmount(amount),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  String _getCurrencySymbol(String currency) {
    switch (currency) {
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      case 'JPY':
        return '¥';
      default:
        return '$currency ';
    }
  }

  List<double> _getQuickAmounts() {
    switch (widget.currency) {
      case 'JPY':
        return [1000, 5000, 10000, 20000];
      default:
        return [100, 500, 1000, 2000];
    }
  }
}

class _QuickAmountButton extends StatelessWidget {
  final double amount;
  final String currency;
  final VoidCallback onTap;

  const _QuickAmountButton({
    required this.amount,
    required this.currency,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          _formatAmount(amount, currency),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  String _formatAmount(double amount, String currency) {
    switch (currency) {
      case 'USD':
        return '\$${amount.toStringAsFixed(0)}';
      case 'EUR':
        return '€${amount.toStringAsFixed(0)}';
      case 'GBP':
        return '£${amount.toStringAsFixed(0)}';
      case 'JPY':
        return '¥${amount.toStringAsFixed(0)}';
      default:
        return '${amount.toStringAsFixed(0)} $currency';
    }
  }
}