import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:laundry_app/shared/data/services/auth_service.dart';
import 'package:laundry_app/shared/data/services/firestore_auth_service.dart';
import 'package:laundry_app/shared/data/repositories/users_repository.dart';
import 'package:laundry_app/shared/data/repositories/admin_repository.dart';
import 'package:laundry_app/shared/data/repositories/laundries_repository.dart';
import 'package:laundry_app/shared/data/repositories/services_repository.dart';
import 'package:laundry_app/shared/data/repositories/fragrances_repository.dart';

// Services
final authServiceProvider = Provider<AuthService>((ref) => AuthService());
final firestoreAuthServiceProvider = StateNotifierProvider<FirestoreAuthNotifier, FirestoreAuthState>((ref) => FirestoreAuthNotifier());

// Repositories
final usersRepositoryProvider =
    Provider<UsersRepository>((ref) => UsersRepository());

final adminRepositoryProvider =
    Provider<AdminRepository>((ref) => AdminRepository());

final laundriesRepositoryProvider =
    Provider<LaundriesRepository>((ref) => LaundriesRepository());

final servicesRepositoryProvider =
    Provider<ServicesRepository>((ref) => ServicesRepository());

final fragrancesRepositoryProvider =
    Provider<FragrancesRepository>((ref) => FragrancesRepository());

