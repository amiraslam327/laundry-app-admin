import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'package:laundry_app/core/config/theme/app_theme.dart';
import 'package:laundry_app/shared/presentation/widgets/app_button.dart';
import 'package:laundry_app/shared/presentation/widgets/app_text_field.dart';

// Stable provider for service categories
final _serviceCategoriesForItemsProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  return FirebaseFirestore.instance
      .collection('serviceCategories')
      .snapshots()
      .map((snapshot) {
        return snapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'name': data['name'] as String? ?? 'Unknown',
            'icon': data['icon'] as String?,
            'duration': data['duration'] as String?,
          };
        }).toList();
      }).handleError((error) {
        throw error;
      });
});

class AddServiceItemPage extends ConsumerStatefulWidget {
  final String? itemId;
  final String? categoryId;
  
  const AddServiceItemPage({super.key, this.itemId, this.categoryId});

  @override
  ConsumerState<AddServiceItemPage> createState() => _AddServiceItemPageState();
}

class _AddServiceItemPageState extends ConsumerState<AddServiceItemPage> {
  final _formKey = GlobalKey<FormState>();
  final _itemNameController = TextEditingController();
  final _priceController = TextEditingController();
  final _minController = TextEditingController();
  final _maxController = TextEditingController();

  String? _selectedCategoryId;
  bool _isLoading = false;
  bool _isLoadingData = false;

  @override
  void initState() {
    super.initState();
    if (widget.itemId != null && widget.categoryId != null) {
      _selectedCategoryId = widget.categoryId;
      _loadItemData();
    } else if (widget.categoryId != null) {
      _selectedCategoryId = widget.categoryId;
    }
  }

  Future<void> _loadItemData() async {
    if (widget.itemId == null || widget.categoryId == null) return;
    
    setState(() => _isLoadingData = true);
    
    try {
      final firestore = FirebaseFirestore.instance;
      final doc = await firestore
          .collection('serviceCategories')
          .doc(widget.categoryId)
          .collection('items')
          .doc(widget.itemId)
          .get();
      
      if (doc.exists && mounted) {
        final data = doc.data()!;
        _itemNameController.text = data['name'] as String? ?? '';
        _priceController.text = (data['price'] as num?)?.toString() ?? '';
        _minController.text = (data['min'] as int?)?.toString() ?? '';
        _maxController.text = (data['max'] as int?)?.toString() ?? '';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading item data: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingData = false);
      }
    }
  }

  @override
  void dispose() {
    _itemNameController.dispose();
    _priceController.dispose();
    _minController.dispose();
    _maxController.dispose();
    super.dispose();
  }

  Future<void> _saveServiceItem() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final firestore = FirebaseFirestore.instance;
      final itemId = const Uuid().v4();
      final price = double.tryParse(_priceController.text.trim()) ?? 0.0;
      final min = int.tryParse(_minController.text.trim()) ?? 0;
      final max = int.tryParse(_maxController.text.trim()) ?? 0;

      if (max < min) {
        throw Exception('Max quantity must be greater than or equal to min');
      }

      if (_selectedCategoryId == null || _selectedCategoryId!.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please select a service category'),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      final isEditing = widget.itemId != null && widget.categoryId != null;
      final finalItemId = isEditing ? widget.itemId! : itemId;
      final finalCategoryId = _selectedCategoryId!;
      
      // Prepare item data
      final itemName = _itemNameController.text.trim();
      final itemData = {
        'id': finalItemId,
        'name': itemName,
        'price': price,
        'min': min,
        'max': max,
      };
      
      if (!isEditing) {
        itemData['createdAt'] = FieldValue.serverTimestamp();
      }
      
      // Save item to serviceCategories/{categoryId}/items/{itemId}
      if (isEditing) {
        await firestore
            .collection('serviceCategories')
            .doc(finalCategoryId)
            .collection('items')
            .doc(finalItemId)
            .update(itemData);
      } else {
        await firestore
            .collection('serviceCategories')
            .doc(finalCategoryId)
            .collection('items')
            .doc(finalItemId)
            .set(itemData, SetOptions(merge: false));
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEditing 
                ? 'Service item updated successfully!' 
                : 'Service item added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        
        if (isEditing) {
          // If editing, go back to list
          context.pop();
        } else {
          // Clear form only if adding new item (keep category selected for quick adding)
          _itemNameController.clear();
          _priceController.clear();
          _minController.clear();
          _maxController.clear();
          // Keep category selected for adding more items to same category
          // setState(() => _selectedCategoryId = null);
          _formKey.currentState?.reset();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving item: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get all service categories using stable provider
    final categoriesAsync = ref.watch(_serviceCategoriesForItemsProvider);

    final categories = categoriesAsync.valueOrNull ?? <Map<String, dynamic>>[];
    final isLoadingCategories = categoriesAsync.isLoading;
    final hasCategoryError = categoriesAsync.hasError;
    final categoryError = categoriesAsync.error;

    final isEditing = widget.itemId != null;
    
    if (_isLoadingData) {
      return Scaffold(
        appBar: AppBar(
          title: Text(isEditing ? 'Edit Service Item' : 'Add Service Item'),
          backgroundColor: AppTheme.primaryBlue,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Service Item' : 'Add Service Item'),
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Service Category Selection
              if (hasCategoryError && categoryError != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    border: Border.all(color: Colors.red[200]!),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red[700]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Error loading categories: $categoryError',
                          style: TextStyle(color: Colors.red[700]),
                        ),
                      ),
                    ],
                  ),
                ),
              if (categories.isEmpty && !isLoadingCategories)
                Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Icon(Icons.info_outline, size: 48),
                        const SizedBox(height: 8),
                        const Text('No service categories available'),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => context.push('/admin/add-service-category'),
                          child: const Text('Add Category'),
                        ),
                      ],
                    ),
                  ),
                )
              else
                DropdownButtonFormField<String>(
                value: _selectedCategoryId,
                decoration: InputDecoration(
                  labelText: 'Service Category *',
                  prefixIcon: isLoadingCategories
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: Padding(
                            padding: EdgeInsets.all(12),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : const Icon(Icons.category),
                  border: const OutlineInputBorder(),
                  hint: isLoadingCategories ? const Text('Loading categories...') : null,
                ),
                items: categories.map((category) {
                  return DropdownMenuItem<String>(
                    value: category['id'] as String,
                    child: Text(category['name'] as String),
                  );
                }).toList(),
                onChanged: (categories.isEmpty || isEditing) ? null : (value) {
                  setState(() => _selectedCategoryId = value);
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a service category';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Item Name *',
                controller: _itemNameController,
                hint: 'e.g., Shirt, Pants, Kurta, Dress',
                prefixIcon: const Icon(Icons.inventory_2),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter item name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Price (SAR) *',
                controller: _priceController,
                keyboardType: TextInputType.number,
                prefixIcon: const Icon(Icons.attach_money),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter price';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      label: 'Min Quantity *',
                      controller: _minController,
                      keyboardType: TextInputType.number,
                      prefixIcon: const Icon(Icons.remove),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Invalid';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: AppTextField(
                      label: 'Max Quantity *',
                      controller: _maxController,
                      keyboardType: TextInputType.number,
                      prefixIcon: const Icon(Icons.add),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Invalid';
                        }
                        final max = int.tryParse(value) ?? 0;
                        final min = int.tryParse(_minController.text) ?? 0;
                        if (max < min) {
                          return 'Must be >= min';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              AppButton(
                text: isEditing ? 'Update Service Item' : 'Save Service Item',
                onPressed: _saveServiceItem,
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

