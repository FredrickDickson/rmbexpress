import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/admin_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/router/app_router.dart';

class AdminTransactionsScreen extends StatefulWidget {
  const AdminTransactionsScreen({super.key});

  @override
  State<AdminTransactionsScreen> createState() => _AdminTransactionsScreenState();
}

class _AdminTransactionsScreenState extends State<AdminTransactionsScreen> {
  final _adminService = AdminService();
  final _searchController = TextEditingController();

  bool _isLoading = true;
  bool _isAuthorized = false;
  List<Map<String, dynamic>> _transactions = [];
  String _searchQuery = '';
  String _statusFilter = 'all';

  @override
  void initState() {
    super.initState();
    _checkAuthAndLoadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
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

      // Load transactions data
      await _loadTransactions();

      setState(() {
        _isAuthorized = true;
      });
    } catch (e) {
      _showErrorSnackBar('Failed to load transactions: ${e.toString()}');
      _redirectToDashboard();
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadTransactions() async {
    try {
      final transactions = await _adminService.getAllTransactions(
        searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
        statusFilter: _statusFilter,
      );
      
      setState(() {
        _transactions = transactions;
      });
    } catch (e) {
      _showErrorSnackBar('Failed to load transactions: ${e.toString()}');
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    _loadTransactions();
  }

  void _onStatusFilterChanged(String status) {
    setState(() {
      _statusFilter = status;
    });
    _loadTransactions();
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
        appBar: AppBar(title: const Text('Transaction Management')),
        body: const Center(
          child: Text('Access Denied'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction Management'),
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
      body: RefreshIndicator(
        onRefresh: _loadTransactions,
        child: Column(
          children: [
            // Search and Filter Section
            _buildSearchAndFilter(),
            
            // Transactions List
            Expanded(
              child: _transactions.isEmpty
                  ? _buildEmptyState()
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _transactions.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        return _buildTransactionCard(_transactions[index]);
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
            decoration: const InputDecoration(
              hintText: 'Search by reference ID...',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: _onSearchChanged,
          ),
          
          const SizedBox(height: 16),
          
          // Status Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('All', 'all'),
                const SizedBox(width: 8),
                _buildFilterChip('Pending', 'pending'),
                const SizedBox(width: 8),
                _buildFilterChip('Reviewing', 'reviewing'),
                const SizedBox(width: 8),
                _buildFilterChip('Approved', 'approved'),
                const SizedBox(width: 8),
                _buildFilterChip('Rejected', 'rejected'),
                const SizedBox(width: 8),
                _buildFilterChip('Completed', 'completed'),
                const SizedBox(width: 8),
                _buildFilterChip('Failed', 'failed'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _statusFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) => _onStatusFilterChanged(value),
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
          Icon(
            Icons.receipt_long_outlined,
            size: 64,
            color: AppTheme.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No transactions found',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty || _statusFilter != 'all'
                ? 'Try adjusting your search or filters'
                : 'No transactions in the system yet',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(Map<String, dynamic> transaction) {
    final amount = (transaction['amount'] as num?)?.toDouble() ?? 0.0;
    final convertedAmount = (transaction['converted_amount'] as num?)?.toDouble() ?? 0.0;
    final fromCurrency = transaction['from_currency'] as String? ?? 'GHS';
    final toCurrency = transaction['to_currency'] as String? ?? 'RMB';
    final status = transaction['status'] as String? ?? 'pending';
    final referenceId = transaction['reference_id'] as String?;
    final createdAt = transaction['created_at'] as String?;
    final userProfile = transaction['profiles'] as Map<String, dynamic>?;
    final userName = userProfile?['full_name'] as String? ?? 'Unknown User';
    final userEmail = userProfile?['email'] as String? ?? '';

    DateTime? transactionDate;
    if (createdAt != null) {
      transactionDate = DateTime.tryParse(createdAt);
    }

    final statusColor = _getStatusColor(status);
    final canApprove = status == 'pending' || status == 'reviewing';
    final canReject = status == 'pending' || status == 'reviewing';

    return Card(
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
                    _getStatusIcon(status),
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
                        'Currency Exchange',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (referenceId != null)
                        Text(
                          'Ref: $referenceId',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondary,
                            fontFamily: 'monospace',
                          ),
                        ),
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
                      '≈ ¥${convertedAmount.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // User Info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: AppTheme.primaryGreen.withOpacity(0.1),
                    child: Icon(
                      Icons.person,
                      size: 16,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (userEmail.isNotEmpty)
                          Text(
                            userEmail,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Transaction Info
            Row(
              children: [
                Icon(
                  Icons.schedule,
                  size: 14,
                  color: AppTheme.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  transactionDate != null ? _formatDate(transactionDate) : 'Unknown date',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.swap_horiz,
                  size: 14,
                  color: AppTheme.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  '$fromCurrency → $toCurrency',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
            
            if (canApprove || canReject) ...[
              const SizedBox(height: 16),
              
              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showTransactionDetails(transaction),
                      icon: const Icon(Icons.visibility, size: 16),
                      label: const Text('View Details'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (canReject)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _rejectTransaction(transaction),
                        icon: const Icon(Icons.close, size: 16),
                        label: const Text('Reject'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.errorColor,
                        ),
                      ),
                    ),
                  if (canApprove && canReject) const SizedBox(width: 8),
                  if (canApprove)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _approveTransaction(transaction),
                        icon: const Icon(Icons.check, size: 16),
                        label: const Text('Approve'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.successColor,
                        ),
                      ),
                    ),
                ],
              ),
            ] else ...[
              const SizedBox(height: 16),
              
              // View Only Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _showTransactionDetails(transaction),
                  icon: const Icon(Icons.visibility, size: 16),
                  label: const Text('View Details'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
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

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'approved':
        return AppTheme.successColor;
      case 'pending':
      case 'reviewing':
        return AppTheme.warningColor;
      case 'failed':
      case 'rejected':
        return AppTheme.errorColor;
      default:
        return AppTheme.textSecondary;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'approved':
        return Icons.check_circle;
      case 'pending':
      case 'reviewing':
        return Icons.access_time;
      case 'failed':
      case 'rejected':
        return Icons.error;
      default:
        return Icons.help_outline;
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

  void _approveTransaction(Map<String, dynamic> transaction) {
    showDialog(
      context: context,
      builder: (context) => _ApproveTransactionDialog(
        transaction: transaction,
        onConfirm: (notes) async {
          try {
            await _adminService.approveTransaction(transaction['id'], notes);
            _loadTransactions();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Transaction approved successfully')),
              );
            }
          } catch (e) {
            _showErrorSnackBar('Failed to approve transaction: ${e.toString()}');
          }
        },
      ),
    );
  }

  void _rejectTransaction(Map<String, dynamic> transaction) {
    showDialog(
      context: context,
      builder: (context) => _RejectTransactionDialog(
        transaction: transaction,
        onConfirm: (reason) async {
          try {
            await _adminService.rejectTransaction(transaction['id'], reason);
            _loadTransactions();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Transaction rejected successfully')),
              );
            }
          } catch (e) {
            _showErrorSnackBar('Failed to reject transaction: ${e.toString()}');
          }
        },
      ),
    );
  }
}

class _TransactionDetailsSheet extends StatelessWidget {
  final Map<String, dynamic> transaction;

  const _TransactionDetailsSheet({required this.transaction});

  @override
  Widget build(BuildContext context) {
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
                  child: Text('Transaction details would go here...'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ApproveTransactionDialog extends StatefulWidget {
  final Map<String, dynamic> transaction;
  final Function(String) onConfirm;

  const _ApproveTransactionDialog({
    required this.transaction,
    required this.onConfirm,
  });

  @override
  State<_ApproveTransactionDialog> createState() => _ApproveTransactionDialogState();
}

class _ApproveTransactionDialogState extends State<_ApproveTransactionDialog> {
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Approve Transaction'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Are you sure you want to approve this transaction?'),
          const SizedBox(height: 16),
          TextField(
            controller: _notesController,
            decoration: const InputDecoration(
              labelText: 'Admin notes (optional)',
              hintText: 'Enter any notes about this approval',
            ),
            maxLines: 2,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            widget.onConfirm(_notesController.text.trim());
          },
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.successColor),
          child: const Text('Approve'),
        ),
      ],
    );
  }
}

class _RejectTransactionDialog extends StatefulWidget {
  final Map<String, dynamic> transaction;
  final Function(String) onConfirm;

  const _RejectTransactionDialog({
    required this.transaction,
    required this.onConfirm,
  });

  @override
  State<_RejectTransactionDialog> createState() => _RejectTransactionDialogState();
}

class _RejectTransactionDialogState extends State<_RejectTransactionDialog> {
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Reject Transaction'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Are you sure you want to reject this transaction?'),
          const SizedBox(height: 16),
          TextField(
            controller: _reasonController,
            decoration: const InputDecoration(
              labelText: 'Reason for rejection',
              hintText: 'Enter the reason for rejecting this transaction',
            ),
            maxLines: 3,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_reasonController.text.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please provide a reason for rejection')),
              );
              return;
            }
            Navigator.of(context).pop();
            widget.onConfirm(_reasonController.text.trim());
          },
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
          child: const Text('Reject'),
        ),
      ],
    );
  }
}