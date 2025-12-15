import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'package:laundry_app/core/config/theme/app_theme.dart';
import 'package:laundry_app/shared/presentation/widgets/app_button.dart';
import 'package:laundry_app/shared/presentation/widgets/app_text_field.dart';
import 'package:laundry_app/shared/domain/models/fragrance_model.dart';

class AddFragrancePage extends ConsumerStatefulWidget {
  final String? fragranceId;
  
  const AddFragrancePage({super.key, this.fragranceId});

  @override
  ConsumerState<AddFragrancePage> createState() => _AddFragrancePageState();
}

class _AddFragrancePageState extends ConsumerState<AddFragrancePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _iconUrlController = TextEditingController();

  bool _isLoading = false;
  bool _isLoadingData = false;
  FragranceModel? _editingFragrance;

  @override
  void initState() {
    super.initState();
    if (widget.fragranceId != null) {
      _loadFragranceData();
    }
  }

  Future<void> _loadFragranceData() async {
    if (widget.fragranceId == null) return;
    
    setState(() => _isLoadingData = true);
    
    try {
      final firestore = FirebaseFirestore.instance;
      final doc = await firestore.collection('fragrances').doc(widget.fragranceId).get();
      
      if (doc.exists && mounted) {
        final data = doc.data()!;
        data['id'] = doc.id;
        _editingFragrance = FragranceModel.fromMap(data);
        
        // Populate all fields
        _nameController.text = _editingFragrance!.name;
        if (_editingFragrance!.iconUrl != null && _editingFragrance!.iconUrl!.isNotEmpty) {
          _iconUrlController.text = _editingFragrance!.iconUrl!;
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading fragrance data: $e')),
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
    _iconUrlController.dispose();
    super.dispose();
  }

  Future<void> _saveFragrance() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final firestore = FirebaseFirestore.instance;
      final fragranceName = _nameController.text.trim();
      final iconUrl = _iconUrlController.text.trim().isEmpty 
          ? null 
          : _iconUrlController.text.trim();

      final fragranceData = {
        'name': fragranceName,
        'iconUrl': iconUrl,
      };

      if (widget.fragranceId != null) {
        // Update existing fragrance
        fragranceData['id'] = widget.fragranceId;
        await firestore.collection('fragrances').doc(widget.fragranceId).update(fragranceData);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Fragrance updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          // Clear fields and go back
          _nameController.clear();
          _iconUrlController.clear();
          _formKey.currentState?.reset();
          context.pop();
        }
      } else {
        // Create new fragrance
        final fragranceId = const Uuid().v4();
        fragranceData['id'] = fragranceId;
        await firestore.collection('fragrances').doc(fragranceId).set(fragranceData);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Fragrance added successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          // Clear fields and go back
          _nameController.clear();
          _iconUrlController.clear();
          _formKey.currentState?.reset();
          context.pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving fragrance: $e')),
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
    final isEditing = widget.fragranceId != null;

    if (_isLoadingData) {
      return Scaffold(
        appBar: AppBar(
          title: Text(isEditing ? 'Edit Fragrance' : 'Add Fragrance'),
          backgroundColor: AppTheme.primaryBlue,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
        bottomNavigationBar: null,
        floatingActionButton: null,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Fragrance' : 'Add Fragrance'),
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
      ),
      bottomNavigationBar: null,
      floatingActionButton: null,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppTextField(
                label: 'Fragrance Name *',
                controller: _nameController,
                hint: 'e.g., Mild, Floral, Fruity, Citrus, Fresh, Lavender',
                prefixIcon: const Icon(Icons.spa),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter fragrance name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Icon URL (optional)',
                controller: _iconUrlController,
                hint: 'e.g., https://example.com/icon.png or assets/icons/fragrance.png',
                prefixIcon: const Icon(Icons.image),
              ),
              const SizedBox(height: 24),
              AppButton(
                text: isEditing ? 'Update Fragrance' : 'Save Fragrance',
                onPressed: _saveFragrance,
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

