import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/supabase_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/exchange_rate_provider.dart';

class SendMoneyScreen extends ConsumerStatefulWidget {
  const SendMoneyScreen({super.key});

  @override
  ConsumerState<SendMoneyScreen> createState() => _SendMoneyScreenState();
}

class _SendMoneyScreenState extends ConsumerState<SendMoneyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _recipientNameController = TextEditingController();
  final _recipientPhoneController = TextEditingController();
  final _recipientWeChatController = TextEditingController();
  final _recipientAlipayController = TextEditingController();
  final _noteController = TextEditingController();
  
  final _supabaseService = SupabaseService();
  
  String _selectedPaymentMethod = 'wechat';
  String _selectedCurrency = 'RMB';
  bool _isProcessing = false;
  bool _saveRecipient = true;
  
  final Map<String, String> _paymentMethods = {
    'wechat': 'WeChat Pay',
    'alipay': 'Alipay',
    'bank': 'Bank Transfer',
  };

  @override
  void dispose() {
    _amountController.dispose();
    _recipientNameController.dispose();
    _recipientPhoneController.dispose();
    _recipientWeChatController.dispose();
    _recipientAlipayController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _sendMoney() async {
    if (!_formKey.currentState!.validate()) return;

    final user = _supabaseService.currentUser;
    if (user == null) {
      _showErrorSnackBar('Please log in to send money');
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final amount = double.parse(_amountController.text);
      final exchangeRates = ref.read(exchangeRatesProvider);
      final currentRate = exchangeRates['GHS']; // Assuming we're paying in GHS
      
      if (currentRate == null) {
        throw Exception('Exchange rate not available');
      }

      // Calculate GHS equivalent for RMB amount
      final ghsAmount = amount / currentRate.rate;

      // Create recipient details
      final recipientDetails = {
        'name': _recipientNameController.text.trim(),
        'phone': _recipientPhoneController.text.trim(),
        'payment_method': _selectedPaymentMethod,
        'note': _noteController.text.trim(),
        if (_selectedPaymentMethod == 'wechat')
          'wechat_id': _recipientWeChatController.text.trim(),
        if (_selectedPaymentMethod == 'alipay')
          'alipay_id': _recipientAlipayController.text.trim(),
        'rmb_amount': amount, // Amount recipient receives
      };

      // Create transaction - amount is what user pays in GHS, exchange rate is GHS to RMB
      final transaction = await _supabaseService.createTransaction(
        amount: ghsAmount, // User pays this amount in GHS
        fromCurrency: 'GHS',
        toCurrency: 'RMB',
        exchangeRate: currentRate.rate, // Rate: 1 GHS = X RMB
        status: 'pending',
        paymentMethod: 'mobile_money', // How user pays us
        recipientDetails: recipientDetails,
      );

      if (transaction != null && mounted) {
        // Show success dialog
        await _showSuccessDialog(amount, ghsAmount);
        
        if (context.mounted) {
          context.pop(); // Go back to dashboard
        }
      }
      
    } catch (e) {
      _showErrorSnackBar('Failed to send money: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _showSuccessDialog(double rmbAmount, double ghsAmount) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.successColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check,
                color: AppTheme.successColor,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Transfer Initiated!',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.successColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your transfer of ¥${rmbAmount.toStringAsFixed(2)} to ${_recipientNameController.text} is being processed.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'You will be charged ₵${ghsAmount.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      // Navigate to transaction history
                      context.push('/transactions');
                    },
                    child: const Text('View Status'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Done'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final exchangeRates = ref.watch(exchangeRatesProvider);
    final currentRate = exchangeRates['GHS']; // GHS to RMB rate

    return Scaffold(
      appBar: AppBar(
        title: const Text('Send Money'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              _buildHeader(),
              const SizedBox(height: 24),

              // Amount Section
              _buildAmountSection(currentRate),
              const SizedBox(height: 20),

              // Recipient Section
              _buildRecipientSection(),
              const SizedBox(height: 20),

              // Payment Method Section
              _buildPaymentMethodSection(),
              const SizedBox(height: 20),

              // Additional Note
              _buildNoteSection(),
              const SizedBox(height: 20),

              // Summary
              if (_amountController.text.isNotEmpty) ...[
                _buildSummarySection(currentRate),
                const SizedBox(height: 24),
              ],

              // Send Button
              _buildSendButton(),
              const SizedBox(height: 16),

              // Disclaimer
              _buildDisclaimer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.send,
                color: AppTheme.primaryGreen,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Send RMB to China',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Fast and secure money transfer to your contacts in China',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountSection(dynamic currentRate) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.attach_money,
                  color: AppTheme.primaryGreen,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Amount to Send',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              decoration: InputDecoration(
                labelText: 'Amount in RMB (¥)',
                prefixText: '¥ ',
                hintText: '0.00',
                suffixText: 'RMB',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value?.trim().isEmpty ?? true) {
                  return 'Please enter an amount';
                }
                final amount = double.tryParse(value!);
                if (amount == null || amount <= 0) {
                  return 'Please enter a valid amount';
                }
                if (amount < 30) {
                  return 'Minimum transfer amount is ¥30';
                }
                if (amount > 100000) {
                  return 'Maximum transfer amount is ¥100,000';
                }
                return null;
              },
              onChanged: (value) => setState(() {}),
            ),
            if (_amountController.text.isNotEmpty && currentRate != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.lightGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: AppTheme.primaryGreen,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'You will pay approximately ₵${(double.tryParse(_amountController.text) != null ? (double.parse(_amountController.text) / currentRate.rate).toStringAsFixed(2) : "0.00")} GHS',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.primaryGreen,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRecipientSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.person_outline,
                  color: AppTheme.primaryGreen,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Recipient Information',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _recipientNameController,
              decoration: const InputDecoration(
                labelText: 'Recipient Name',
                hintText: 'Enter full name in Chinese or English',
              ),
              validator: (value) {
                if (value?.trim().isEmpty ?? true) {
                  return 'Please enter recipient name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _recipientPhoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number (China)',
                hintText: '+86 XXX XXXX XXXX',
                prefixText: '+86 ',
              ),
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value?.trim().isEmpty ?? true) {
                  return 'Please enter recipient phone number';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.payment,
                  color: AppTheme.primaryGreen,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Recipient Payment Method',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Payment Method Selection
            ..._paymentMethods.entries.map((entry) {
              return RadioListTile<String>(
                title: Text(entry.value),
                value: entry.key,
                groupValue: _selectedPaymentMethod,
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedPaymentMethod = value);
                  }
                },
                contentPadding: EdgeInsets.zero,
              );
            }),
            
            const SizedBox(height: 16),
            
            // Payment Method ID Field
            if (_selectedPaymentMethod == 'wechat')
              TextFormField(
                controller: _recipientWeChatController,
                decoration: const InputDecoration(
                  labelText: 'WeChat ID *',
                  hintText: 'Enter recipient WeChat ID',
                  prefixIcon: Icon(Icons.chat),
                ),
                validator: (value) {
                  if (_selectedPaymentMethod == 'wechat') {
                    if (value?.trim().isEmpty ?? true) {
                      return 'WeChat ID is required';
                    }
                    if (value!.length < 3) {
                      return 'WeChat ID must be at least 3 characters';
                    }
                  }
                  return null;
                },
                onChanged: (value) => setState(() {}), // Trigger validation
              )
            else if (_selectedPaymentMethod == 'alipay')
              TextFormField(
                controller: _recipientAlipayController,
                decoration: const InputDecoration(
                  labelText: 'Alipay Account *',
                  hintText: 'Phone number or email',
                  prefixIcon: Icon(Icons.account_balance_wallet),
                ),
                validator: (value) {
                  if (_selectedPaymentMethod == 'alipay') {
                    if (value?.trim().isEmpty ?? true) {
                      return 'Alipay account is required';
                    }
                    // Basic email or phone validation
                    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                    final phoneRegex = RegExp(r'^\d{11}$');
                    if (!emailRegex.hasMatch(value!) && !phoneRegex.hasMatch(value)) {
                      return 'Enter valid email or 11-digit phone number';
                    }
                  }
                  return null;
                },
                keyboardType: TextInputType.emailAddress,
                onChanged: (value) => setState(() {}), // Trigger validation
              )
            else if (_selectedPaymentMethod == 'bank')
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.blue.shade700,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Bank transfer requires additional verification. You will be contacted for bank details.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoteSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.note_outlined,
                  color: AppTheme.primaryGreen,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Transfer Note (Optional)',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _noteController,
              decoration: const InputDecoration(
                hintText: 'Add a message for the recipient...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              maxLength: 200,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummarySection(dynamic currentRate) {
    if (_amountController.text.isEmpty || currentRate == null) {
      return const SizedBox.shrink();
    }

    final rmbAmount = double.tryParse(_amountController.text) ?? 0.0;
    final ghsAmount = rmbAmount / currentRate.rate;

    return Card(
      color: AppTheme.primaryGreen.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.receipt_long,
                  color: AppTheme.primaryGreen,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Transfer Summary',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSummaryRow('Recipient receives', '¥${rmbAmount.toStringAsFixed(2)} RMB'),
            _buildSummaryRow('You pay', '₵${ghsAmount.toStringAsFixed(2)} GHS'),
            _buildSummaryRow('Exchange rate', '1 GHS = ¥${currentRate.rate.toStringAsFixed(4)}'),
            _buildSummaryRow('Transfer method', _paymentMethods[_selectedPaymentMethod]!),
            const Divider(),
            _buildSummaryRow(
              'Total cost',
              '₵${ghsAmount.toStringAsFixed(2)} GHS',
              isTotal: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
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
              color: isTotal ? AppTheme.primaryGreen : null,
            ),
          ),
        ],
      ),
    );
  }

  bool _canSend() {
    // Check basic form validation
    if (!(_formKey.currentState?.validate() ?? false)) return false;
    
    // Check amount
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount < 30) return false;
    
    // Check required fields
    if (_recipientNameController.text.trim().isEmpty) return false;
    if (_recipientPhoneController.text.trim().isEmpty) return false;
    
    // Check payment method specific fields
    if (_selectedPaymentMethod == 'wechat' && _recipientWeChatController.text.trim().isEmpty) {
      return false;
    }
    if (_selectedPaymentMethod == 'alipay' && _recipientAlipayController.text.trim().isEmpty) {
      return false;
    }
    
    return true;
  }

  Widget _buildSendButton() {
    final canSend = _canSend();

    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: canSend && !_isProcessing ? _sendMoney : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryGreen,
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
                  Text('Processing Transfer...'),
                ],
              )
            : const Text(
                'Send Money',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Widget _buildDisclaimer() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.security,
                color: Colors.amber.shade700,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Transfer Information',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.amber.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '• Transfers are processed within 1-2 business days\n'
            '• Exchange rates may fluctuate during processing\n'
            '• Recipient will be notified once transfer is complete\n'
            '• Contact support for any transfer issues',
            style: TextStyle(
              fontSize: 12,
              color: Colors.amber.shade700,
            ),
          ),
        ],
      ),
    );
  }
}