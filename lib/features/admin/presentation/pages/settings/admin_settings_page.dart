import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:laundry_app/core/config/theme/app_theme.dart';
import 'package:laundry_app/shared/presentation/providers/providers.dart';
import 'package:laundry_app/shared/presentation/providers/app_providers.dart';
import 'package:laundry_app/shared/presentation/providers/admin_notifier.dart';
import 'package:laundry_app/shared/domain/models/admin_model.dart';

class AdminSettingsPage extends ConsumerWidget {
  const AdminSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adminAsync = ref.watch(adminProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Settings'),
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: adminAsync.when(
        data: (admin) {
          if (admin == null) {
            // Try to get cached data directly as fallback
            final userId = FirebaseAuth.instance.currentUser?.uid;
            if (userId != null) {
              // Try to refresh admin data
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    const Text('Loading admin profile...'),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        // Manually refresh admin data
                        ref.read(adminNotifierProvider.notifier).refresh();
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red),
                  SizedBox(height: 16),
                  Text('Admin profile not found'),
                  SizedBox(height: 8),
                  Text(
                    'Please log out and log back in',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            );
          }
          return _buildSettingsContent(context, ref, admin);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) {
          // Try to get cached data as fallback
          final userId = FirebaseAuth.instance.currentUser?.uid;
          if (userId != null) {
            // Show loading while we try to restore from cache
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Restoring admin profile...'),
                ],
              ),
            );
          }
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error: $error'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    // Invalidate and retry
                    ref.invalidate(adminNotifierProvider);
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSettingsContent(BuildContext context, WidgetRef ref, AdminModel admin) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Profile Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: AppTheme.primaryBlue,
                    child: Text(
                      admin.fullName.isNotEmpty ? admin.fullName[0].toUpperCase() : (admin.email.isNotEmpty ? admin.email[0].toUpperCase() : 'A'),
                      style: const TextStyle(fontSize: 32, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    admin.fullName.isNotEmpty ? admin.fullName : admin.email,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    admin.email,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey,
                        ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Profile Information (Read-only) - All Details
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.person),
                  title: const Text('Full Name'),
                  subtitle: Text(admin.fullName.isNotEmpty ? admin.fullName : 'Not set'),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.phone),
                  title: const Text('Phone Number'),
                  subtitle: Text(admin.phoneNumber.isNotEmpty ? admin.phoneNumber : 'Not set'),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.email),
                  title: const Text('Email'),
                  subtitle: Text(admin.email),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Manage Admins Card
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.admin_panel_settings, color: AppTheme.primaryBlue),
                  title: const Text('Manage Admins'),
                  subtitle: const Text('Add, view, and delete admin accounts'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/admin/admin-list'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Logout Button
          ElevatedButton.icon(
            onPressed: () => _handleLogout(context, ref),
            icon: const Icon(Icons.logout),
            label: const Text('Logout'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ],
      ),
    );
  }


  Future<void> _handleLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // Use FirestoreAuthService for logout
        final firestoreAuth = ref.read(firestoreAuthServiceProvider.notifier);
        await firestoreAuth.signOut();
        
        // Invalidate admin provider
        ref.invalidate(adminNotifierProvider);
        
        if (context.mounted) {
          context.go('/login');
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error logging out: $e')),
          );
        }
      }
    }
  }

}

