import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:laundry_app/shared/presentation/providers/providers.dart';
import 'package:laundry_app/shared/presentation/providers/admin_notifier.dart';
import 'package:laundry_app/shared/domain/models/laundry_model.dart';
import 'package:laundry_app/shared/domain/models/service_model.dart';
import 'package:laundry_app/shared/domain/models/fragrance_model.dart';
import 'package:laundry_app/shared/domain/models/admin_model.dart';

// Export adminProvider from admin_notifier
export 'admin_notifier.dart' show adminProvider;

// Auth Provider
final authProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

// Current User ID Provider
final currentUserIdProvider = Provider<String?>((ref) {
  final authAsync = ref.watch(authProvider);
  return authAsync.value?.uid;
});

// Laundries Provider
final laundriesProvider = StreamProvider<List<LaundryModel>>((ref) {
  final repository = ref.watch(laundriesRepositoryProvider);
  return repository.getAllLaundries();
});

// Services Provider (family for laundryId)
final servicesProvider = StreamProvider.family<List<ServiceModel>, String>((ref, laundryId) {
  final repository = ref.watch(servicesRepositoryProvider);
  return repository.getServicesByLaundry(laundryId);
});

// All Services Provider
final allServicesProvider = StreamProvider<List<ServiceModel>>((ref) {
  final repository = ref.watch(servicesRepositoryProvider);
  return repository.getAllServices();
});

// Fragrances Provider
final fragrancesProvider = StreamProvider<List<FragranceModel>>((ref) {
  final repository = ref.watch(fragrancesRepositoryProvider);
  return repository.getAllFragrances();
});

// All Admins Provider
final allAdminsProvider = StreamProvider<List<AdminModel>>((ref) {
  final repository = ref.watch(adminRepositoryProvider);
  return repository.getAllAdmins();
});

// Firestore Auth Login State Provider
final firestoreAuthLoginStateProvider = Provider<bool>((ref) {
  final firestoreAuthState = ref.watch(firestoreAuthServiceProvider);
  return firestoreAuthState.isLoggedIn;
});

