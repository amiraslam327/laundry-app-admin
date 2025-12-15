import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:laundry_app/core/config/theme/app_theme.dart';
import 'package:laundry_app/shared/presentation/widgets/app_button.dart';
import 'package:laundry_app/shared/presentation/widgets/app_text_field.dart';
import 'package:laundry_app/shared/presentation/providers/providers.dart';
import 'package:laundry_app/shared/presentation/providers/app_providers.dart';
import 'package:laundry_app/shared/domain/models/admin_model.dart';
import 'package:laundry_app/shared/utils/password_hasher.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:uuid/uuid.dart';

class AddAdminPage extends ConsumerStatefulWidget {
  const AddAdminPage({super.key});

  @override
  ConsumerState<AddAdminPage> createState() => _AddAdminPageState();
}

class _AddAdminPageState extends ConsumerState<AddAdminPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  String _countryCode = '+966';
  String _phoneNumber = '';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final adminRepository = ref.read(adminRepositoryProvider);

      // Check if admin with this email already exists in Firestore
      final emailExists = await adminRepository.adminExistsByEmail(_emailController.text.trim());
      if (emailExists) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('An admin with this email already exists'),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      // Generate unique ID for admin
      final adminId = const Uuid().v4();
      final uid = adminId; // Same as id

      // Check if admin document already exists (prevent overwrite)
      final adminExists = await adminRepository.adminExists(adminId);
      if (adminExists) {
        throw Exception('Admin document already exists. Cannot overwrite existing admin data.');
      }

      // Hash the password
      final passwordHash = PasswordHasher.hashPassword(_passwordController.text.trim());

      // Create admin document in Firestore ONLY (no Firebase Auth)
      // Save all fields: id, uid, fullName, name, email, phoneNumber, phone, role, createdAt, visible, passwordHash
      final admin = AdminModel(
        id: adminId,
        fullName: _nameController.text.trim(),
        phoneNumber: _phoneNumber.isEmpty ? _phoneController.text.trim() : _phoneNumber,
        email: _emailController.text.trim(),
        createdAt: DateTime.now(),
        role: 'admin',
        visible: true, // Always visible by default
      );

      // Create admin document with password hash and all fields
      await adminRepository.createAdminWithPassword(admin, passwordHash);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Admin created successfully in Firestore'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating admin: $e'),
            backgroundColor: Colors.red,
          ),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Admin'),
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
              const SizedBox(height: 16),
              // Name Field
              AppTextField(
                controller: _nameController,
                label: 'Name',
                hint: 'Enter admin name',
                prefixIcon: const Icon(Icons.person),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Email Field
              AppTextField(
                controller: _emailController,
                label: 'Email',
                hint: 'Enter email address',
                prefixIcon: const Icon(Icons.email),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter an email';
                  }
                  if (!value.contains('@')) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Phone Field
              IntlPhoneField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  hintText: 'Enter phone number',
                  prefixIcon: const Icon(Icons.phone),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                initialCountryCode: 'SA',
                onChanged: (phone) {
                  _countryCode = phone.countryCode;
                  _phoneNumber = phone.completeNumber;
                },
                validator: (phone) {
                  if (phone == null || phone.number.isEmpty) {
                    return 'Please enter a phone number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Password Field
              AppTextField(
                controller: _passwordController,
                label: 'Password',
                hint: 'Enter password',
                prefixIcon: const Icon(Icons.lock),
                obscureText: _obscurePassword,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a password';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              // Submit Button
              AppButton(
                text: _isLoading ? 'Creating...' : 'Create Admin',
                onPressed: _isLoading ? null : _submitForm,
                backgroundColor: AppTheme.primaryBlue,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

