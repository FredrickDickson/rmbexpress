import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/admin_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/router/app_router.dart';

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  final _adminService = AdminService();

  bool _isLoading = true;
  bool _isAuthorized = false;
  Map<String, dynamic> _financialReport = {};
  List<Map<String, dynamic>> _auditLogs = [];
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _checkAuthAndLoadData();
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

      // Load reports data
      await _loadReportsData();

      setState(() {
        _isAuthorized = true;
      });
    } catch (e) {
      _showErrorSnackBar('Failed to load reports: ${e.toString()}');
      _redirectToDashboard();
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadReportsData() async {
    try {
      final report = await _adminService.getFinancialReport(
        startDate: _startDate,
        endDate: _endDate,
      );
      final logs = await _adminService.getAuditLogs(limit: 50);
      
      setState(() {
        _financialReport = report;
        _auditLogs = logs;
      });
    } catch (e) {
      _showErrorSnackBar('Failed to load reports data: ${e.toString()}');
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
        appBar: AppBar(title: const Text('Financial Reports')),
        body: const Center(
          child: Text('Access Denied'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Financial Reports'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: _selectDateRange,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadReportsData,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadReportsData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date Range Selector
              _buildDateRangeSelector(),
              
              const SizedBox(height: 24),
              
              // Financial Summary
              _buildFinancialSummary(),
              
              const SizedBox(height: 24),
              
              // Charts and Analytics
              _buildAnalyticsSection(),
              
              const SizedBox(height: 24),
              
              // Audit Logs
              _buildAuditLogsSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateRangeSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.date_range,
              color: AppTheme.primaryGreen,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Report Period',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${_formatDate(_startDate)} - ${_formatDate(_endDate)}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            OutlinedButton(
              onPressed: _selectDateRange,
              child: const Text('Change'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialSummary() {
    final summary = _financialReport['summary'] as Map<String, dynamic>? ?? {};
    
    final totalTransactions = summary['total_transactions'] as int? ?? 0;
    final completedTransactions = summary['completed_transactions'] as int? ?? 0;
    final completionRate = (summary['completion_rate'] as num?)?.toDouble() ?? 0.0;
    final totalRevenue = (summary['total_revenue'] as num?)?.toDouble() ?? 0.0;
    final totalVolume = (summary['total_volume'] as num?)?.toDouble() ?? 0.0;
    final averageTransaction = (summary['average_transaction'] as num?)?.toDouble() ?? 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Financial Summary',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        
        const SizedBox(height: 16),
        
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.5,
          children: [
            _buildSummaryCard(
              'Total Revenue',
              '₵${totalRevenue.toStringAsFixed(2)}',
              Icons.monetization_on,
              AppTheme.successColor,
            ),
            _buildSummaryCard(
              'Total Volume',
              '₵${totalVolume.toStringAsFixed(2)}',
              Icons.trending_up,
              AppTheme.primaryGreen,
            ),
            _buildSummaryCard(
              'Transactions',
              '$completedTransactions / $totalTransactions',
              Icons.receipt_long,
              Colors.blue,
            ),
            _buildSummaryCard(
              'Success Rate',
              '${(completionRate * 100).toStringAsFixed(1)}%',
              Icons.check_circle,
              Colors.orange,
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.analytics,
                  color: AppTheme.textSecondary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Average Transaction',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      Text(
                        '₵${averageTransaction.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Icon(
                    Icons.trending_up,
                    size: 12,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsSection() {
    final dailyBreakdown = _financialReport['daily_breakdown'] as List<dynamic>? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Daily Performance',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        
        const SizedBox(height: 16),
        
        if (dailyBreakdown.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.analytics_outlined,
                      size: 48,
                      color: AppTheme.textSecondary.withOpacity(0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No data available for selected period',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Transaction Trends',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.show_chart,
                            size: 48,
                            color: AppTheme.textSecondary.withOpacity(0.5),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Chart visualization would go here',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAuditLogsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Recent Admin Activity',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              onPressed: _viewAllAuditLogs,
              child: const Text('View All'),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        if (_auditLogs.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.history_outlined,
                      size: 48,
                      color: AppTheme.textSecondary.withOpacity(0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No audit logs available',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _auditLogs.take(5).length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              return _buildAuditLogTile(_auditLogs[index]);
            },
          ),
      ],
    );
  }

  Widget _buildAuditLogTile(Map<String, dynamic> log) {
    final action = log['action'] as String? ?? 'unknown';
    final entityType = log['entity_type'] as String? ?? '';
    final createdAt = log['created_at'] as String?;
    final actorProfile = log['profiles'] as Map<String, dynamic>?;
    final actorName = actorProfile?['full_name'] as String? ?? 'Unknown Admin';

    DateTime? logDate;
    if (createdAt != null) {
      logDate = DateTime.tryParse(createdAt);
    }

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getActionColor(action).withOpacity(0.1),
          child: Icon(
            _getActionIcon(action),
            color: _getActionColor(action),
            size: 20,
          ),
        ),
        title: Text(
          _formatActionTitle(action, entityType),
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text('by $actorName'),
        trailing: logDate != null 
            ? Text(
                _formatDate(logDate),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                ),
              )
            : null,
      ),
    );
  }

  Color _getActionColor(String action) {
    switch (action.toLowerCase()) {
      case 'approve_transaction':
      case 'unsuspend_user':
        return AppTheme.successColor;
      case 'reject_transaction':
      case 'suspend_user':
        return AppTheme.errorColor;
      case 'update_config':
      case 'update_exchange_rate':
      case 'toggle_payment_method':
        return AppTheme.warningColor;
      default:
        return AppTheme.textSecondary;
    }
  }

  IconData _getActionIcon(String action) {
    switch (action.toLowerCase()) {
      case 'approve_transaction':
        return Icons.check_circle;
      case 'reject_transaction':
        return Icons.cancel;
      case 'suspend_user':
        return Icons.block;
      case 'unsuspend_user':
        return Icons.restore;
      case 'update_config':
        return Icons.settings;
      case 'update_exchange_rate':
        return Icons.currency_exchange;
      case 'toggle_payment_method':
        return Icons.payment;
      default:
        return Icons.history;
    }
  }

  String _formatActionTitle(String action, String entityType) {
    switch (action.toLowerCase()) {
      case 'approve_transaction':
        return 'Approved transaction';
      case 'reject_transaction':
        return 'Rejected transaction';
      case 'suspend_user':
        return 'Suspended user';
      case 'unsuspend_user':
        return 'Unsuspended user';
      case 'update_config':
        return 'Updated system configuration';
      case 'update_exchange_rate':
        return 'Updated exchange rate';
      case 'toggle_payment_method':
        return 'Toggled payment method';
      case 'update_kyc_status':
        return 'Updated KYC status';
      default:
        return '${action.replaceAll('_', ' ')} $entityType';
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

  void _selectDateRange() async {
    final pickedRange = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );

    if (pickedRange != null) {
      setState(() {
        _startDate = pickedRange.start;
        _endDate = pickedRange.end;
      });
      _loadReportsData();
    }
  }

  void _viewAllAuditLogs() {
    // Navigate to detailed audit logs screen
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Audit Logs'),
        content: const Text('Detailed audit logs view would be implemented here'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}