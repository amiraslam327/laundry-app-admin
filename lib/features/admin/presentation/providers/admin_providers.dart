import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:laundry_app/shared/presentation/providers/app_providers.dart';
import 'package:laundry_app/shared/domain/models/admin_model.dart';
import 'package:laundry_app/shared/presentation/providers/providers.dart';

/// Provider to check if current user is admin
final isAdminProvider = FutureProvider<bool>((ref) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return false;

  try {
    final adminRepository = ref.read(adminRepositoryProvider);
    return await adminRepository.isAdmin(user.uid);
  } catch (e) {
    return false;
  }
});

/// Provider to get current admin model
final currentAdminProvider = Provider<AdminModel?>((ref) {
  final adminAsync = ref.watch(adminProvider);
  return adminAsync.valueOrNull;
});

