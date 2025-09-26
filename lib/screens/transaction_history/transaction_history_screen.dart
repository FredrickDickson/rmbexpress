import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/supabase_service.dart';
import '../../core/theme/app_theme.dart';

class TransactionHistoryScreen extends ConsumerStatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  ConsumerState<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends ConsumerState<TransactionHistoryScreen> {
  final _supabaseService = SupabaseService();
  final _searchController = TextEditingController();
  
  List<Map<String, dynamic>> _transactions = [];
  List<Map<String, dynamic>> _filteredTransactions = [];
  bool _isLoading = true;
  String _selectedFilter = 'all';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTransactions() async {
    try {
      setState(() => _isLoading = true);
      
      final user = _supabaseService.currentUser;
      if (user == null) {
        _redirectToLogin();
        return;
      }

      final transactions = await _supabaseService.getUserTransactions();
      setState(() {
        _transactions = transactions;
        _applyFilters();
      });
      
    } catch (e) {
      _showErrorSnackBar('Failed to load transactions: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _applyFilters() {
    _filteredTransactions = _transactions.where((transaction) {
      // Status filter
      final statusMatch = _selectedFilter == 'all' || 
                         transaction['status'] == _selectedFilter;
      
      // Search filter
      final searchMatch = _searchQuery.isEmpty ||
                         transaction['reference_id']?.toString().toLowerCase().contains(_searchQuery.toLowerCase()) == true ||
                         transaction['amount']?.toString().contains(_searchQuery) == true;
      
      return statusMatch && searchMatch;
    }).toList();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      _applyFilters();
    });
  }

  void _onFilterChanged(String filter) {
    setState(() {
      _selectedFilter = filter;
      _applyFilters();
    });
  }

  void _redirectToLogin() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.go('/login');
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction History'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTransactions,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadTransactions,
              child: Column(
                children: [
                  // Search and Filter Section
                  _buildSearchAndFilter(),
                  
                  // Transactions List
                  Expanded(
                    child: _filteredTransactions.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _filteredTransactions.length,
                            itemBuilder: (context, index) {
                              return _buildTransactionCard(_filteredTransactions[index]);
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Search Bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search by reference ID or amount...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _onSearchChanged('');
                      },
                    )
                  : null,
            ),
            onChanged: _onSearchChanged,
          ),
          
          const SizedBox(height: 16),
          
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('All', 'all'),
                const SizedBox(width: 8),
                _buildFilterChip('Completed', 'completed'),
                const SizedBox(width: 8),
                _buildFilterChip('Pending', 'pending'),
                const SizedBox(width: 8),
                _buildFilterChip('Failed', 'failed'),
                const SizedBox(width: 8),
                _buildFilterChip('Cancelled', 'cancelled'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) => _onFilterChanged(value),
      backgroundColor: isSelected ? AppTheme.primaryGreen.withOpacity(0.1) : null,
      selectedColor: AppTheme.primaryGreen.withOpacity(0.2),
      checkmarkColor: AppTheme.primaryGreen,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppTheme.lightGreen.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.history,
              size: 64,
              color: AppTheme.primaryGreen.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _searchQuery.isNotEmpty || _selectedFilter != 'all'
                ? 'No transactions match your filters'
                : 'No transactions yet',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty || _selectedFilter != 'all'
                ? 'Try adjusting your search or filters'
                : 'Your transaction history will appear here',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary.withOpacity(0.7),
            ),
          ),
          if (_searchQuery.isEmpty && _selectedFilter == 'all') ...[
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.pop(),
              child: const Text('Start Trading'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTransactionCard(Map<String, dynamic> transaction) {
    final amount = (transaction['amount'] as num?)?.toDouble() ?? 0.0;
    final fromCurrency = transaction['from_currency'] as String? ?? 'GHS';
    final toCurrency = transaction['to_currency'] as String? ?? 'RMB';
    final status = transaction['status'] as String? ?? 'pending';
    final createdAt = transaction['created_at'] as String?;
    final referenceId = transaction['reference_id'] as String?;
    final exchangeRate = (transaction['exchange_rate'] as num?)?.toDouble() ?? 1.0;
    final paymentMethod = transaction['payment_method'] as String?;
    final recipientDetails = transaction['recipient_details'] as Map<String, dynamic>?;

    DateTime? transactionDate;
    if (createdAt != null) {
      transactionDate = DateTime.tryParse(createdAt);
    }

    // For display purposes - if from GHS to RMB, show RMB amount to recipient
    final displayAmount = recipientDetails?['rmb_amount'] ?? (amount * exchangeRate);
    final statusColor = _getStatusColor(status);
    final statusIcon = _getStatusIcon(status);
    final recipientName = recipientDetails?['name'] as String?;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showTransactionDetails(transaction),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      statusIcon,
                      color: statusColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          recipientName != null ? 'Send to $recipientName' : 'Currency Exchange',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (referenceId != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Ref: $referenceId',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${_getCurrencySymbol(fromCurrency)}${amount.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '≈ ¥${displayAmount.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Transaction Details Row
              Row(
                children: [
                  _buildDetailChip(
                    'Status',
                    status.toUpperCase(),
                    statusColor,
                  ),
                  const SizedBox(width: 8),
                  if (paymentMethod != null)
                    _buildDetailChip(
                      'Payment',
                      _getPaymentMethodName(paymentMethod),
                      AppTheme.textSecondary,
                    ),
                  const Spacer(),
                  if (transactionDate != null)
                    Text(
                      _formatDate(transactionDate),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Exchange Rate
              Row(
                children: [
                  Icon(
                    Icons.swap_horiz,
                    size: 16,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '1 $fromCurrency = ¥${exchangeRate.toStringAsFixed(4)} $toCurrency',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
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

  Widget _buildDetailChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        value,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return AppTheme.successColor;
      case 'pending':
      case 'processing':
        return AppTheme.warningColor;
      case 'failed':
      case 'cancelled':
        return AppTheme.errorColor;
      default:
        return AppTheme.textSecondary;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Icons.check_circle;
      case 'pending':
      case 'processing':
        return Icons.access_time;
      case 'failed':
        return Icons.error;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  String _getCurrencySymbol(String currency) {
    switch (currency.toUpperCase()) {
      case 'GHS':
        return '₵';
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      case 'RMB':
      case 'CNY':
        return '¥';
      default:
        return '';
    }
  }

  String _getPaymentMethodName(String method) {
    switch (method.toLowerCase()) {
      case 'mobile_money':
        return 'Mobile Money';
      case 'bank_transfer':
        return 'Bank Transfer';
      case 'card':
        return 'Card';
      default:
        return method;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _showTransactionDetails(Map<String, dynamic> transaction) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _TransactionDetailsSheet(transaction: transaction),
    );
  }
}

class _TransactionDetailsSheet extends StatelessWidget {
  final Map<String, dynamic> transaction;

  const _TransactionDetailsSheet({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final amount = (transaction['amount'] as num?)?.toDouble() ?? 0.0;
    final fromCurrency = transaction['from_currency'] as String? ?? 'GHS';
    final toCurrency = transaction['to_currency'] as String? ?? 'RMB';
    final status = transaction['status'] as String? ?? 'pending';
    final createdAt = transaction['created_at'] as String?;
    final referenceId = transaction['reference_id'] as String?;
    final exchangeRate = (transaction['exchange_rate'] as num?)?.toDouble() ?? 1.0;
    final paymentMethod = transaction['payment_method'] as String?;

    DateTime? transactionDate;
    if (createdAt != null) {
      transactionDate = DateTime.tryParse(createdAt);
    }

    final convertedAmount = amount * exchangeRate;
    final statusColor = _getStatusColor(status);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                height: 4,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Text(
                      'Transaction Details',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              
              const Divider(height: 1),
              
              // Content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Amount Section
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Text(
                                'Transaction Amount',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${_getCurrencySymbol(fromCurrency)}${amount.toStringAsFixed(2)} $fromCurrency',
                                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryGreen,
                                ),
                              ),
                              Text(
                                '≈ ¥${convertedAmount.toStringAsFixed(2)} $toCurrency',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Details Section
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildDetailRow('Status', status.toUpperCase(), statusColor),
                              if (referenceId != null)
                                _buildDetailRow('Reference ID', referenceId),
                              _buildDetailRow('Exchange Rate', '1 $fromCurrency = ¥${exchangeRate.toStringAsFixed(4)}'),
                              if (paymentMethod != null)
                                _buildDetailRow('Payment Method', _getPaymentMethodName(paymentMethod)),
                              if (transactionDate != null)
                                _buildDetailRow('Date & Time', _formatFullDate(transactionDate)),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Action Buttons
                      if (status == 'failed') ...[
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              // Navigate to retry transaction
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Retry transaction - Coming Soon!')),
                              );
                            },
                            child: const Text('Retry Transaction'),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Get support - Coming Soon!')),
                            );
                          },
                          child: const Text('Get Support'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value, [Color? valueColor]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return AppTheme.successColor;
      case 'pending':
      case 'processing':
        return AppTheme.warningColor;
      case 'failed':
      case 'cancelled':
        return AppTheme.errorColor;
      default:
        return AppTheme.textSecondary;
    }
  }

  String _getCurrencySymbol(String currency) {
    switch (currency.toUpperCase()) {
      case 'GHS':
        return '₵';
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      case 'RMB':
      case 'CNY':
        return '¥';
      default:
        return '';
    }
  }

  String _getPaymentMethodName(String method) {
    switch (method.toLowerCase()) {
      case 'mobile_money':
        return 'Mobile Money';
      case 'bank_transfer':
        return 'Bank Transfer';
      case 'card':
        return 'Card';
      default:
        return method;
    }
  }

  String _formatFullDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    
    return '${date.day} ${months[date.month - 1]} ${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}