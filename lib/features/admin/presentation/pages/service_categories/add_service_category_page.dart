import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:laundry_app/core/config/theme/app_theme.dart';
import 'package:laundry_app/shared/presentation/widgets/app_button.dart';
import 'package:laundry_app/shared/presentation/widgets/app_text_field.dart';

class AddServiceCategoryPage extends ConsumerStatefulWidget {
  final String? categoryId;
  
  const AddServiceCategoryPage({super.key, this.categoryId});

  @override
  ConsumerState<AddServiceCategoryPage> createState() => _AddServiceCategoryPageState();
}

class _AddServiceCategoryPageState extends ConsumerState<AddServiceCategoryPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _iconController = TextEditingController();
  final _durationController = TextEditingController();

  bool _isLoading = false;
  bool _isLoadingData = false;

  @override
  void initState() {
    super.initState();
    if (widget.categoryId != null) {
      _loadCategoryData();
    }
  }

  Future<void> _loadCategoryData() async {
    if (widget.categoryId == null) return;
    
    setState(() => _isLoadingData = true);
    
    try {
      final firestore = FirebaseFirestore.instance;
      final doc = await firestore.collection('serviceCategories').doc(widget.categoryId).get();
      
      if (doc.exists && mounted) {
        final data = doc.data()!;
        _nameController.text = data['name'] as String? ?? '';
        _iconController.text = data['icon'] as String? ?? '';
        _durationController.text = data['duration'] as String? ?? '';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading category data: $e')),
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
    _nameController.dispose();
    _iconController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _saveCategory() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final firestore = FirebaseFirestore.instance;
      final isEditing = widget.categoryId != null;
      final categoryId = widget.categoryId ?? _nameController.text.trim().toLowerCase().replaceAll(' ', '_');

      final categoryData = {
        'id': categoryId,
        'name': _nameController.text.trim(),
        'icon': _iconController.text.trim().isNotEmpty ? _iconController.text.trim() : null,
        'duration': _durationController.text.trim().isNotEmpty ? _durationController.text.trim() : null,
      };

      if (isEditing) {
        await firestore
            .collection('serviceCategories')
            .doc(categoryId)
            .update(categoryData);
      } else {
        await firestore
            .collection('serviceCategories')
            .doc(categoryId)
            .set(categoryData);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEditing 
                ? 'Category updated successfully!' 
                : 'Category added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving category: $e')),
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
    final isEditing = widget.categoryId != null;
    
    if (_isLoadingData) {
      return Scaffold(
        appBar: AppBar(
          title: Text(isEditing ? 'Edit Category' : 'Add Category'),
          backgroundColor: AppTheme.primaryBlue,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Category' : 'Add Category'),
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
              AppTextField(
                label: 'Category Name *',
                controller: _nameController,
                hint: 'e.g., Wash, Dry Clean, Iron',
                prefixIcon: const Icon(Icons.category),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter category name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Icon Path',
                controller: _iconController,
                hint: 'e.g., assets/icons/wash.png',
                prefixIcon: const Icon(Icons.image),
                validator: (value) {
                  // Optional field
                  return null;
                },
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Duration',
                controller: _durationController,
                hint: 'e.g., 24 hours, 3 days',
                prefixIcon: const Icon(Icons.access_time),
                validator: (value) {
                  // Optional field
                  return null;
                },
              ),
              const SizedBox(height: 24),
              AppButton(
                text: isEditing ? 'Update Category' : 'Save Category',
                onPressed: _saveCategory,
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: null,
      floatingActionButton: null,
    );
  }
}

