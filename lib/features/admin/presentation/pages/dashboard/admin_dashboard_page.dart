import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:laundry_app/core/config/theme/app_theme.dart';
import 'package:laundry_app/shared/presentation/providers/providers.dart';

class AdminDashboardPage extends ConsumerWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final firestoreAuthState = ref.watch(firestoreAuthServiceProvider);
    
    // Redirect to login if not logged in
    if (!firestoreAuthState.isLoggedIn || firestoreAuthState.admin == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/login');
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/admin/settings'),
            tooltip: 'Settings',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header & Quick Stats combined
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryBlue.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.admin_panel_settings,
                            size: 36,
                            color: AppTheme.primaryBlue,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Admin Dashboard',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Manage your laundry business',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Colors.grey.shade700,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    FutureBuilder<_DashboardStats>(
                      future: _fetchStats(),
                      builder: (context, snapshot) {
                        final stats = snapshot.data;
                        final isLoading = snapshot.connectionState == ConnectionState.waiting;
                        if (isLoading) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (snapshot.hasError) {
                          return Text(
                            'Failed to load stats: ${snapshot.error}',
                            style: const TextStyle(color: Colors.red),
                          );
                        }
                        if (stats == null) {
                          return const SizedBox.shrink();
                        }
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatItem(
                              context,
                              'Laundries',
                              stats.laundries.toString(),
                              Icons.local_laundry_service,
                            ),
                            _buildStatItem(
                              context,
                              'Services',
                              stats.services.toString(),
                              Icons.cleaning_services,
                            ),
                            _buildStatItem(
                              context,
                              'Pending Orders',
                              stats.pendingOrders.toString(),
                              Icons.receipt_long,
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Admin Actions Grid
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.15,
              children: [
                _buildAdminCard(
                  context,
                  icon: Icons.local_laundry_service,
                  title: 'Add Laundry',
                  subtitle: 'Create new laundry',
                  color: Colors.blue,
                  onTap: () => context.push('/admin/add-laundry'),
                ),
                _buildAdminCard(
                  context,
                  icon: Icons.category,
                  title: 'Service Categories',
                  subtitle: 'Manage categories',
                  color: Colors.cyan,
                  onTap: () => context.push('/admin/service-categories'),
                ),
                _buildAdminCard(
                  context,
                  icon: Icons.cleaning_services,
                  title: 'Add Service',
                  subtitle: 'Add service type',
                  color: Colors.green,
                  onTap: () => context.push('/admin/add-service'),
                ),
                _buildAdminCard(
                  context,
                  icon: Icons.inventory_2,
                  title: 'Add Service Item',
                  subtitle: 'Add items to service',
                  color: Colors.orange,
                  onTap: () => context.push('/admin/add-service-item'),
                ),
                _buildAdminCard(
                  context,
                  icon: Icons.list,
                  title: 'Manage Laundries',
                  subtitle: 'View all laundries',
                  color: Colors.blue,
                  onTap: () => context.push('/admin/laundries'),
                ),
                _buildAdminCard(
                  context,
                  icon: Icons.list_alt,
                  title: 'Manage Services',
                  subtitle: 'View all services',
                  color: Colors.green,
                  onTap: () => context.push('/admin/services'),
                ),
                _buildAdminCard(
                  context,
                  icon: Icons.inventory,
                  title: 'Manage Service Items',
                  subtitle: 'View all items',
                  color: Colors.orange,
                  onTap: () => context.push('/admin/items'),
                ),
                _buildAdminCard(
                  context,
                  icon: Icons.spa,
                  title: 'Manage Fragrances',
                  subtitle: 'View all fragrances',
                  color: Colors.purple,
                  onTap: () => context.push('/admin/fragrances'),
                ),
                _buildAdminCard(
                  context,
                  icon: Icons.delivery_dining,
                  title: 'Manage Drivers',
                  subtitle: 'View all drivers',
                  color: Colors.teal,
                  onTap: () => context.push('/admin/drivers'),
                ),
                _buildAdminCard(
                  context,
                  icon: Icons.receipt_long,
                  title: 'Manage Orders',
                  subtitle: 'View all orders',
                  color: Colors.indigo,
                  onTap: () => context.push('/admin/orders'),
                ),
              ],
            ),
            const SizedBox(height: 16), // Extra bottom padding
          ],
        ),
      ),
    );
  }

  Widget _buildAdminCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
          child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 28, color: color),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 4),
              Flexible(
                child: Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 11,
                      ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 32, color: AppTheme.primaryBlue),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppTheme.primaryBlue,
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _DashboardStats {
  const _DashboardStats({
    required this.laundries,
    required this.services,
    required this.pendingOrders,
  });

  final int laundries;
  final int services;
  final int pendingOrders;
}

Future<_DashboardStats> _fetchStats() async {
  try {
    final firestore = FirebaseFirestore.instance;
    final results = await Future.wait([
      firestore.collection('laundries').get(),
      firestore.collection('services').get(),
      firestore
          .collection('orders')
          .doc('pending')
          .collection('pending')
          .get(),
    ]);

    final laundries = results[0].docs.length;
    final services = results[1].docs.length;
    final pendingOrders = results[2].docs.length;

    return _DashboardStats(
      laundries: laundries,
      services: services,
      pendingOrders: pendingOrders,
    );
  } catch (e) {
    throw Exception('Failed to load stats: $e');
  }
}

