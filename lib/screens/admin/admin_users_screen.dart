import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/admin_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/router/app_router.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final _adminService = AdminService();
  final _searchController = TextEditingController();

  bool _isLoading = true;
  bool _isAuthorized = false;
  List<Map<String, dynamic>> _users = [];
  String _searchQuery = '';
  String _roleFilter = 'all';
  String _kycFilter = 'all';

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

      // Load users data
      await _loadUsers();

      setState(() {
        _isAuthorized = true;
      });
    } catch (e) {
      _showErrorSnackBar('Failed to load users: ${e.toString()}');
      _redirectToDashboard();
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadUsers() async {
    try {
      final users = await _adminService.getAllUsers(
        searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
        roleFilter: _roleFilter,
        kycFilter: _kycFilter,
      );
      
      setState(() {
        _users = users;
      });
    } catch (e) {
      _showErrorSnackBar('Failed to load users: ${e.toString()}');
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    _loadUsers();
  }

  void _onFilterChanged() {
    _loadUsers();
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
        appBar: AppBar(title: const Text('User Management')),
        body: const Center(
          child: Text('Access Denied'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUsers,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadUsers,
        child: Column(
          children: [
            // Search and Filter Section
            _buildSearchAndFilter(),
            
            // Users List
            Expanded(
              child: _users.isEmpty
                  ? _buildEmptyState()
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _users.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        return _buildUserCard(_users[index]);
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
              hintText: 'Search by name or email...',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: _onSearchChanged,
          ),
          
          const SizedBox(height: 16),
          
          // Filter Chips
          Row(
            children: [
              Text(
                'Filters: ',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Wrap(
                  spacing: 8,
                  children: [
                    _buildFilterChip('Role', _roleFilter, [
                      'all', 'user', 'admin', 'super_admin'
                    ], (value) {
                      setState(() => _roleFilter = value);
                      _onFilterChanged();
                    }),
                    _buildFilterChip('KYC', _kycFilter, [
                      'all', 'unverified', 'pending', 'verified', 'rejected'
                    ], (value) {
                      setState(() => _kycFilter = value);
                      _onFilterChanged();
                    }),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String currentValue, List<String> options, Function(String) onChanged) {
    return PopupMenuButton<String>(
      child: Chip(
        label: Text('$label: ${currentValue.replaceAll('_', ' ').toUpperCase()}'),
        avatar: const Icon(Icons.filter_list, size: 16),
      ),
      onSelected: onChanged,
      itemBuilder: (context) => options.map((option) => 
        PopupMenuItem(
          value: option,
          child: Text(option.replaceAll('_', ' ').toUpperCase()),
        ),
      ).toList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 64,
            color: AppTheme.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No users found',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty || _roleFilter != 'all' || _kycFilter != 'all'
                ? 'Try adjusting your search or filters'
                : 'No users in the system yet',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    final fullName = user['full_name'] as String? ?? 'No name';
    final email = user['email'] as String? ?? 'No email';
    final role = user['role'] as String? ?? 'user';
    final kycStatus = user['kyc_status'] as String? ?? 'unverified';
    final createdAt = user['created_at'] as String?;
    final suspendedAt = user['suspended_at'] as String?;
    final isSuspended = suspendedAt != null;

    DateTime? joinDate;
    if (createdAt != null) {
      joinDate = DateTime.tryParse(createdAt);
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: _getRoleColor(role).withOpacity(0.1),
                  child: Icon(
                    _getRoleIcon(role),
                    color: _getRoleColor(role),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fullName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        email,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSuspended)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.errorColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'SUSPENDED',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.errorColor,
                      ),
                    ),
                  ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Info Row
            Row(
              children: [
                _buildInfoChip('Role', role.replaceAll('_', ' ').toUpperCase(), _getRoleColor(role)),
                const SizedBox(width: 8),
                _buildInfoChip('KYC', kycStatus.toUpperCase(), _getKycColor(kycStatus)),
                const Spacer(),
                if (joinDate != null)
                  Text(
                    'Joined ${_formatDate(joinDate)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showUserDetails(user),
                    icon: const Icon(Icons.visibility, size: 16),
                    label: const Text('View'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: isSuspended 
                    ? ElevatedButton.icon(
                        onPressed: () => _unsuspendUser(user),
                        icon: const Icon(Icons.restore, size: 16),
                        label: const Text('Unsuspend'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.successColor,
                        ),
                      )
                    : ElevatedButton.icon(
                        onPressed: () => _suspendUser(user),
                        icon: const Icon(Icons.block, size: 16),
                        label: const Text('Suspend'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.errorColor,
                        ),
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, String value, Color color) {
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

  Color _getRoleColor(String role) {
    switch (role) {
      case 'admin':
      case 'super_admin':
        return Colors.red;
      case 'user':
      default:
        return AppTheme.primaryGreen;
    }
  }

  IconData _getRoleIcon(String role) {
    switch (role) {
      case 'admin':
      case 'super_admin':
        return Icons.admin_panel_settings;
      case 'user':
      default:
        return Icons.person;
    }
  }

  Color _getKycColor(String status) {
    switch (status) {
      case 'verified':
        return AppTheme.successColor;
      case 'pending':
        return AppTheme.warningColor;
      case 'rejected':
        return AppTheme.errorColor;
      case 'unverified':
      default:
        return AppTheme.textSecondary;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays < 1) {
      return 'Today';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()}w ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _showUserDetails(Map<String, dynamic> user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _UserDetailsSheet(user: user),
    );
  }

  void _suspendUser(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (context) => _SuspendUserDialog(
        user: user,
        onConfirm: (reason) async {
          try {
            await _adminService.suspendUser(user['id'], reason);
            _loadUsers();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('User suspended successfully')),
              );
            }
          } catch (e) {
            _showErrorSnackBar('Failed to suspend user: ${e.toString()}');
          }
        },
      ),
    );
  }

  void _unsuspendUser(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unsuspend User'),
        content: Text('Are you sure you want to unsuspend ${user['full_name']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await _adminService.unsuspendUser(user['id']);
                _loadUsers();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('User unsuspended successfully')),
                  );
                }
              } catch (e) {
                _showErrorSnackBar('Failed to unsuspend user: ${e.toString()}');
              }
            },
            child: const Text('Unsuspend'),
          ),
        ],
      ),
    );
  }
}

class _UserDetailsSheet extends StatelessWidget {
  final Map<String, dynamic> user;

  const _UserDetailsSheet({required this.user});

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
                      'User Details',
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
                      // Basic Info
                      _buildDetailSection('Basic Information', [
                        _DetailItem('Full Name', user['full_name'] ?? 'N/A'),
                        _DetailItem('Email', user['email'] ?? 'N/A'),
                        _DetailItem('Phone', user['phone_number'] ?? 'Not provided'),
                        _DetailItem('Role', (user['role'] as String? ?? 'user').replaceAll('_', ' ').toUpperCase()),
                      ]),
                      
                      const SizedBox(height: 24),
                      
                      // KYC Information
                      _buildDetailSection('KYC Information', [
                        _DetailItem('Status', (user['kyc_status'] as String? ?? 'unverified').toUpperCase()),
                        _DetailItem('Documents', user['kyc_documents']?.toString() ?? 'None uploaded'),
                      ]),
                      
                      const SizedBox(height: 24),
                      
                      // Account Status
                      _buildDetailSection('Account Status', [
                        _DetailItem('Suspended', user['suspended_at'] != null ? 'Yes' : 'No'),
                        if (user['suspended_at'] != null) ...[
                          _DetailItem('Suspended At', user['suspended_at']),
                          _DetailItem('Suspension Reason', user['suspension_reason'] ?? 'No reason provided'),
                        ],
                        _DetailItem('Created At', user['created_at'] ?? 'Unknown'),
                        _DetailItem('Updated At', user['updated_at'] ?? 'Unknown'),
                      ]),
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

  Widget _buildDetailSection(String title, List<_DetailItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        ...items.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 120,
                child: Text(
                  item.label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  item.value,
                  style: const TextStyle(fontWeight: FontWeight.w400),
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }
}

class _DetailItem {
  final String label;
  final String value;
  
  _DetailItem(this.label, this.value);
}

class _SuspendUserDialog extends StatefulWidget {
  final Map<String, dynamic> user;
  final Function(String) onConfirm;

  const _SuspendUserDialog({
    required this.user,
    required this.onConfirm,
  });

  @override
  State<_SuspendUserDialog> createState() => _SuspendUserDialogState();
}

class _SuspendUserDialogState extends State<_SuspendUserDialog> {
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Suspend User'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Are you sure you want to suspend ${widget.user['full_name']}?'),
          const SizedBox(height: 16),
          TextField(
            controller: _reasonController,
            decoration: const InputDecoration(
              labelText: 'Reason for suspension',
              hintText: 'Enter the reason for suspending this user',
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
                const SnackBar(content: Text('Please provide a reason for suspension')),
              );
              return;
            }
            Navigator.of(context).pop();
            widget.onConfirm(_reasonController.text.trim());
          },
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
          child: const Text('Suspend'),
        ),
      ],
    );
  }
}