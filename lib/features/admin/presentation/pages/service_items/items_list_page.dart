import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:laundry_app/core/config/theme/app_theme.dart';
import 'package:laundry_app/shared/domain/models/service_item.dart';

// Stable provider for service categories
final _itemsListCategoriesProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  return FirebaseFirestore.instance
      .collection('serviceCategories')
      .snapshots()
      .map((snapshot) {
        return snapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'name': data['name'] as String? ?? 'Unknown',
          };
        }).toList();
      });
});

class ItemsListPage extends ConsumerWidget {
  const ItemsListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get all service categories
    final categoriesAsync = ref.watch(_itemsListCategoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Service Items'),
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // Refresh by invalidating the provider
              ref.invalidate(_itemsListCategoriesProvider);
            },
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push('/admin/add-service-item'),
            tooltip: 'Add Service Item',
          ),
        ],
      ),
      body: categoriesAsync.when(
        data: (categories) {
          if (categories.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.category, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('No service categories found'),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => context.push('/admin/add-service-category'),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Category'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              final categoryId = category['id'] as String;
              final categoryName = category['name'] as String;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ExpansionTile(
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.primaryBlue,
                    child: const Icon(Icons.category, color: Colors.white),
                  ),
                  title: Text(categoryName),
                  subtitle: const Text('Tap to view items'),
                  children: [
                    _buildCategoryItemsList(context, categoryId),
                  ],
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
              Text('Error loading categories: $error'),
            ],
          ),
        ),
      ),
      bottomNavigationBar: null,
      floatingActionButton: null,
    );
  }

  Widget _buildCategoryItemsList(BuildContext context, String categoryId) {
    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection('serviceCategories')
          .doc(categoryId)
          .collection('items')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text('Error: ${snapshot.error}'),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const Text('No items in this category'),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () => context.push('/admin/add-service-item?categoryId=$categoryId'),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Item'),
                ),
              ],
            ),
          );
        }

        final items = snapshot.data!.docs;

        return Column(
          children: items.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            try {
              final item = ServiceItem.fromMap(data);
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                elevation: 1,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.primaryBlue.withOpacity(0.1),
                    child: const Icon(Icons.inventory_2, color: AppTheme.primaryBlue),
                  ),
                  title: Text(
                    item.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.only(right: 40),
                        child: Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Chip(
                              label: Text(
                                '${item.price.toStringAsFixed(2)} SAR',
                                style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
                              ),
                              backgroundColor: Colors.green.withOpacity(0.1),
                              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 0),
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                            ),
                            Chip(
                              label: Text(
                                'Min: ${item.min}',
                                style: const TextStyle(fontSize: 9),
                              ),
                              backgroundColor: Colors.blue.withOpacity(0.1),
                              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 0),
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                            ),
                            Chip(
                              label: Text(
                                'Max: ${item.max}',
                                style: const TextStyle(fontSize: 9),
                              ),
                              backgroundColor: Colors.orange.withOpacity(0.1),
                              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 0),
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                            ),
                          ],
                        ),
                      ),
                      if (item.categoryId != null && item.categoryId!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'Category ID: ${item.categoryId}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Item ID: ${item.id}',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[500],
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ],
                  ),
                  trailing: PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (value) {
                      if (value == 'edit') {
                        _editItem(context, categoryId, item);
                      } else if (value == 'delete') {
                        _deleteItem(context, categoryId, item);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, color: Colors.blue, size: 20),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red, size: 20),
                            SizedBox(width: 8),
                            Text('Delete'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  isThreeLine: true,
                ),
              );
            } catch (e) {
              return const SizedBox.shrink();
            }
          }).toList(),
        );
      },
    );
  }

  void _editItem(BuildContext context, String categoryId, ServiceItem item) {
    // Navigate to edit page (reuse add page with edit mode)
    context.push('/admin/add-service-item?id=${item.id}&categoryId=$categoryId');
  }

  Future<void> _deleteItem(BuildContext context, String categoryId, ServiceItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item'),
        content: Text('Are you sure you want to delete "${item.name}"?'),
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
            .collection('serviceCategories')
            .doc(categoryId)
            .collection('items')
            .doc(item.id)
            .delete();
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Item deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting item: $e')),
          );
        }
      }
    }
  }
}

