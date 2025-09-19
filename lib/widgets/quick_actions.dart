import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../core/router/app_router.dart';

class QuickActions extends StatelessWidget {
  const QuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'Quick Actions',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ).animate().fadeIn(delay: 400.ms),
        ),
        
        const SizedBox(height: 16),
        
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.currency_exchange,
                  title: 'Buy RMB',
                  subtitle: 'Exchange currency',
                  color: Theme.of(context).colorScheme.primary,
                  onTap: () => context.push(AppRouter.buyRmb),
                ).animate().fadeIn(delay: 600.ms).slideX(
                  begin: -0.3,
                  duration: 500.ms,
                  curve: Curves.easeOutCubic,
                ),
              ),
              
              const SizedBox(width: 12),
              
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.send,
                  title: 'Send Money',
                  subtitle: 'Transfer RMB',
                  color: Theme.of(context).colorScheme.secondary,
                  onTap: () => context.push(AppRouter.sendMoney),
                ).animate().fadeIn(delay: 800.ms).slideX(
                  begin: 0.3,
                  duration: 500.ms,
                  curve: Curves.easeOutCubic,
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 12),
        
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.history,
                  title: 'History',
                  subtitle: 'View transactions',
                  color: Colors.orange,
                  onTap: () => context.push(AppRouter.transactions),
                ).animate().fadeIn(delay: 1000.ms).slideX(
                  begin: -0.3,
                  duration: 500.ms,
                  curve: Curves.easeOutCubic,
                ),
              ),
              
              const SizedBox(width: 12),
              
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.person,
                  title: 'Profile',
                  subtitle: 'Manage account',
                  color: Colors.purple,
                  onTap: () => context.push(AppRouter.profile),
                ).animate().fadeIn(delay: 1200.ms).slideX(
                  begin: 0.3,
                  duration: 500.ms,
                  curve: Curves.easeOutCubic,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              
              const SizedBox(height: 12),
              
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              
              const SizedBox(height: 4),
              
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}