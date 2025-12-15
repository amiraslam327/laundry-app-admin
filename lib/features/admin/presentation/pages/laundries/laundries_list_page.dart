import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:laundry_app/core/config/theme/app_theme.dart';
import 'package:laundry_app/shared/domain/models/laundry_model.dart';
import 'package:laundry_app/shared/presentation/providers/app_providers.dart';

class LaundriesListPage extends ConsumerWidget {
  const LaundriesListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final laundriesAsync = ref.watch(laundriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Laundries'),
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push('/admin/add-laundry'),
            tooltip: 'Add Laundry',
          ),
        ],
      ),
      body: laundriesAsync.when(
        data: (laundries) {
          if (laundries.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.local_laundry_service, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('No laundries found'),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => context.push('/admin/add-laundry'),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Laundry'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: laundries.length,
            itemBuilder: (context, index) {
              final laundry = laundries[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.primaryBlue,
                    child: const Icon(Icons.local_laundry_service, color: Colors.white),
                  ),
                  title: Text(laundry.name),
                subtitle: Text(
                  laundry.description,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _editLaundry(context, laundry),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteLaundry(context, laundry),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $error'),
            ],
          ),
        ),
      ),
    );
  }

  void _editLaundry(BuildContext context, LaundryModel laundry) {
    // Navigate to edit page (reuse add page with edit mode)
    context.push('/admin/add-laundry?id=${laundry.id}');
  }

  Future<void> _deleteLaundry(BuildContext context, LaundryModel laundry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Laundry'),
        content: Text('Are you sure you want to delete "${laundry.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirebaseFirestore.instance
            .collection('laundries')
            .doc(laundry.id)
            .delete();
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Laundry deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting laundry: $e')),
          );
        }
      }
    }
  }
}

