import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/admin_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/router/app_router.dart';

class AdminConfigScreen extends StatefulWidget {
  const AdminConfigScreen({super.key});

  @override
  State<AdminConfigScreen> createState() => _AdminConfigScreenState();
}

class _AdminConfigScreenState extends State<AdminConfigScreen> with SingleTickerProviderStateMixin {
  final _adminService = AdminService();
  late TabController _tabController;

  bool _isLoading = true;
  bool _isAuthorized = false;
  List<Map<String, dynamic>> _systemConfigs = [];
  List<Map<String, dynamic>> _exchangeRates = [];
  List<Map<String, dynamic>> _paymentMethods = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _checkAuthAndLoadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _checkAuthAndLoadData() async {
    try {
      setState(() => _isLoading = true);
      
      // Check if user is admin
      final isAdmin = await _adminService.isCurrentUserAdmin();
      if (!isAdmin) {
        _redirectToDashboard();
        return;
      }

      // Load configuration data
      await _loadAllConfigs();

      setState(() {
        _isAuthorized = true;
      });
    } catch (e) {
      _showErrorSnackBar('Failed to load configuration: ${e.toString()}');
      _redirectToDashboard();
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadAllConfigs() async {
    try {
      final configs = await _adminService.getSystemConfig();
      final rates = await _adminService.getExchangeRates();
      final methods = await _adminService.getPaymentMethods();
      
      setState(() {
        _systemConfigs = configs;
        _exchangeRates = rates;
        _paymentMethods = methods;
      });
    } catch (e) {
      _showErrorSnackBar('Failed to load configurations: ${e.toString()}');
    }
  }

  void _redirectToDashboard() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.go(AppRouter.dashboard);
      }
    });
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
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!_isAuthorized) {
      return Scaffold(
        appBar: AppBar(title: const Text('System Configuration')),
        body: const Center(
          child: Text('Access Denied'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('System Configuration'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAllConfigs,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.settings),
              text: 'System',
            ),
            Tab(
              icon: Icon(Icons.currency_exchange),
              text: 'Exchange Rates',
            ),
            Tab(
              icon: Icon(Icons.payment),
              text: 'Payment Methods',
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadAllConfigs,
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildSystemConfigTab(),
            _buildExchangeRatesTab(),
            _buildPaymentMethodsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemConfigTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'System Configuration',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          
          const SizedBox(height: 8),
          
          Text(
            'Manage system-wide settings and configurations',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          
          const SizedBox(height: 24),
          
          if (_systemConfigs.isEmpty)
            _buildEmptyConfigState()
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _systemConfigs.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return _buildSystemConfigCard(_systemConfigs[index]);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildSystemConfigCard(Map<String, dynamic> config) {
    final key = config['key'] as String? ?? '';
    final value = config['value']?.toString() ?? '';
    final description = config['description'] as String? ?? '';
    final category = config['category'] as String? ?? 'general';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        key,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          description,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getCategoryColor(category).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    category.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: _getCategoryColor(category),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontFamily: 'monospace',
                ),
              ),
            ),
            
            const SizedBox(height: 12),
            
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _editSystemConfig(config),
                icon: const Icon(Icons.edit, size: 16),
                label: const Text('Edit'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExchangeRatesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Exchange Rates',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Manage currency exchange rates',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: _addExchangeRate,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Rate'),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          if (_exchangeRates.isEmpty)
            _buildEmptyRatesState()
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _exchangeRates.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return _buildExchangeRateCard(_exchangeRates[index]);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildExchangeRateCard(Map<String, dynamic> rate) {
    final baseCurrency = rate['base_currency'] as String? ?? '';
    final quoteCurrency = rate['quote_currency'] as String? ?? '';
    final rateValue = (rate['rate'] as num?)?.toDouble() ?? 0.0;
    final source = rate['source'] as String? ?? 'manual';
    final createdAt = rate['created_at'] as String?;
    final creator = rate['profiles'] as Map<String, dynamic>?;
    final creatorName = creator?['full_name'] as String? ?? 'Unknown';

    DateTime? createdDate;
    if (createdAt != null) {
      createdDate = DateTime.tryParse(createdAt);
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.currency_exchange,
                    color: AppTheme.primaryGreen,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$baseCurrency → $quoteCurrency',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '1 $baseCurrency = ${rateValue.toStringAsFixed(4)} $quoteCurrency',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            Row(
              children: [
                _buildRateInfoChip('Source', source.toUpperCase()),
                const SizedBox(width: 8),
                _buildRateInfoChip('By', creatorName),
                const Spacer(),
                if (createdDate != null)
                  Text(
                    _formatDate(createdDate),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRateInfoChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$label: $value',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildPaymentMethodsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment Methods',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          
          const SizedBox(height: 8),
          
          Text(
            'Manage available payment methods and their settings',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          
          const SizedBox(height: 24),
          
          if (_paymentMethods.isEmpty)
            _buildEmptyMethodsState()
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _paymentMethods.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return _buildPaymentMethodCard(_paymentMethods[index]);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodCard(Map<String, dynamic> method) {
    final name = method['name'] as String? ?? '';
    final code = method['code'] as String? ?? '';
    final enabled = method['enabled'] as bool? ?? false;
    final minLimit = (method['min_limit'] as num?)?.toDouble() ?? 0.0;
    final maxLimit = (method['max_limit'] as num?)?.toDouble();
    final feePercentage = (method['fee_percentage'] as num?)?.toDouble() ?? 0.0;
    final feeFixed = (method['fee_fixed'] as num?)?.toDouble() ?? 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: enabled 
                        ? AppTheme.successColor.withOpacity(0.1)
                        : AppTheme.errorColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getPaymentIcon(code),
                    color: enabled ? AppTheme.successColor : AppTheme.errorColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        code.toUpperCase(),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: enabled,
                  onChanged: (value) => _togglePaymentMethod(method, value),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _buildMethodInfoItem(
                    'Min Limit',
                    '₵${minLimit.toStringAsFixed(2)}',
                  ),
                ),
                Expanded(
                  child: _buildMethodInfoItem(
                    'Max Limit',
                    maxLimit != null ? '₵${maxLimit.toStringAsFixed(2)}' : 'No limit',
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: _buildMethodInfoItem(
                    'Fee %',
                    '${feePercentage.toStringAsFixed(2)}%',
                  ),
                ),
                Expanded(
                  child: _buildMethodInfoItem(
                    'Fixed Fee',
                    '₵${feeFixed.toStringAsFixed(2)}',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMethodInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyConfigState() {
    return Center(
      child: Column(
        children: [
          Icon(
            Icons.settings_outlined,
            size: 64,
            color: AppTheme.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No system configurations',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyRatesState() {
    return Center(
      child: Column(
        children: [
          Icon(
            Icons.currency_exchange_outlined,
            size: 64,
            color: AppTheme.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No exchange rates configured',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyMethodsState() {
    return Center(
      child: Column(
        children: [
          Icon(
            Icons.payment_outlined,
            size: 64,
            color: AppTheme.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No payment methods configured',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'system':
        return Colors.blue;
      case 'transactions':
        return AppTheme.primaryGreen;
      case 'exchange':
        return Colors.orange;
      case 'fees':
        return Colors.purple;
      case 'compliance':
        return Colors.red;
      case 'limits':
        return AppTheme.warningColor;
      case 'security':
        return Colors.indigo;
      default:
        return AppTheme.textSecondary;
    }
  }

  IconData _getPaymentIcon(String code) {
    switch (code.toLowerCase()) {
      case 'mobile_money':
        return Icons.phone_android;
      case 'bank_transfer':
        return Icons.account_balance;
      case 'card':
        return Icons.credit_card;
      default:
        return Icons.payment;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _editSystemConfig(Map<String, dynamic> config) {
    // Show edit dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit ${config['key']}'),
        content: const Text('Edit functionality would be implemented here'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _addExchangeRate() {
    // Show add exchange rate dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Exchange Rate'),
        content: const Text('Add exchange rate functionality would be implemented here'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _togglePaymentMethod(Map<String, dynamic> method, bool enabled) async {
    try {
      await _adminService.togglePaymentMethod(method['id'], enabled);
      _loadAllConfigs();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${method['name']} ${enabled ? 'enabled' : 'disabled'} successfully'
            ),
          ),
        );
      }
    } catch (e) {
      _showErrorSnackBar('Failed to update payment method: ${e.toString()}');
    }
  }
}