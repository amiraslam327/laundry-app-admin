import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:laundry_app/shared/presentation/providers/providers.dart';
import 'package:laundry_app/shared/presentation/providers/app_providers.dart';
import 'package:laundry_app/shared/domain/models/admin_model.dart';

// Global persistent cache - survives everything
final _adminCache = <String, AdminModel>{};
String? _cachedUserId;

/// Notifier that manages admin data - updates on login/logout and Firestore changes
class AdminNotifier extends StateNotifier<AsyncValue<AdminModel?>> {
  AdminNotifier(this.ref) : super(const AsyncValue.loading()) {
    // Immediately restore from global cache (synchronous)
    // _restoreFromCache();
    // Then set up listeners
    _initialize();
  }

  final Ref ref;
  StreamSubscription<AdminModel?>? _adminStreamSubscription;

  void _restoreFromCache() {
    // Get current admin from FirestoreAuthService
    final firestoreAuthState = ref.watch(firestoreAuthServiceProvider);
    final currentAdmin = firestoreAuthState.admin;
    final userId = firestoreAuthState.adminId;
    
    if (userId != null && currentAdmin != null && _cachedUserId == userId && _adminCache.containsKey(userId)) {
      final cachedAdmin = _adminCache[userId]!;
      state = AsyncValue.data(cachedAdmin);
    } else if (userId == null) {
      state = const AsyncValue.data(null);
    }
  }

  Future<void> _initialize() async {
    // Get current admin from FirestoreAuthService
    final firestoreAuthState = ref.watch(firestoreAuthServiceProvider);
    final userId = firestoreAuthState.adminId;
    final currentAdmin = firestoreAuthState.admin;
    
    // If we have current admin from FirestoreAuthService, use it
    if (currentAdmin != null && userId != null) {
      _adminCache[userId] = currentAdmin;
      _cachedUserId = userId;
      state = AsyncValue.data(currentAdmin);
      // Still set up stream listener for real-time updates
      _setupStreamListener(userId);
      return;
    }
    
    // If we already have cached data, ensure state is set
    if (userId != null && _cachedUserId == userId && _adminCache.containsKey(userId)) {
      state = AsyncValue.data(_adminCache[userId]!);
      // Still set up stream listener for real-time updates
      _setupStreamListener(userId);
      return;
    }
    
    // Listen to auth changes - only update when userId actually changes
    // ref.listen(authProvider, (previous, next) {
    //   final newUserId = next.valueOrNull?.uid;
    //
    //   // Only update if userId actually changed (login/logout)
    //   if (newUserId != _cachedUserId) {
    //     // Cancel previous stream subscription
    //     _adminStreamSubscription?.cancel();
    //     _adminStreamSubscription = null;
    //
    //     if (newUserId == null) {
    //       // Logout - clear global cache
    //       _adminCache.clear();
    //       _cachedUserId = null;
    //       state = const AsyncValue.data(null);
    //     } else {
    //       // Login - fetch new data and set up stream
    //       _loadAdmin(newUserId);
    //     }
    //   }
    // });

    // Load initial data if not cached
    if (userId != null && (_cachedUserId != userId || !_adminCache.containsKey(userId))) {
      _loadAdmin(userId);
    } else if (userId == null) {
      state = const AsyncValue.data(null);
    }
  }

  void _setupStreamListener(String userId) {
    // Cancel existing subscription if any
    _adminStreamSubscription?.cancel();
    
    final repository = ref.read(adminRepositoryProvider);
    _adminStreamSubscription = repository.getAdminStream(userId).listen(
      (admin) {
        if (admin != null) {
          // Update cache and state when admin data changes
          _adminCache[userId] = admin;
          _cachedUserId = userId;
          state = AsyncValue.data(admin);
        } else {
          // Admin document was deleted
          if (_cachedUserId == userId) {
            _adminCache.remove(userId);
            _cachedUserId = null;
            state = const AsyncValue.data(null);
          }
        }
      },
      onError: (error) {
        // Keep existing cached data on stream error
        if (_cachedUserId == userId && _adminCache.containsKey(userId)) {
          state = AsyncValue.data(_adminCache[userId]!);
        }
      },
    );
  }

  Future<void> _loadAdmin(String userId) async {
    // Check global cache first
    if (_cachedUserId == userId && _adminCache.containsKey(userId)) {
      state = AsyncValue.data(_adminCache[userId]!);
      // Set up stream listener for real-time updates
      _setupStreamListener(userId);
      return;
    }

    // Set loading state
    state = const AsyncValue.loading();
    
    try {
      final repository = ref.read(adminRepositoryProvider);
      final admin = await repository.getAdmin(userId);
      
      if (admin != null) {
        // Store in global cache
        _adminCache[userId] = admin;
        _cachedUserId = userId;
        state = AsyncValue.data(admin);
        // Set up stream listener for real-time updates
        _setupStreamListener(userId);
      } else {
        // Admin not found - but keep existing cache if available
        if (_cachedUserId == userId && _adminCache.containsKey(userId)) {
          state = AsyncValue.data(_adminCache[userId]!);
          _setupStreamListener(userId);
        } else {
          _adminCache.remove(userId);
          if (_cachedUserId == userId) _cachedUserId = null;
          state = const AsyncValue.data(null);
          // Still set up stream listener in case admin is created later
          _setupStreamListener(userId);
        }
      }
    } catch (e, stack) {
      // Always return cached data if available, even on error
      if (_cachedUserId == userId && _adminCache.containsKey(userId)) {
        state = AsyncValue.data(_adminCache[userId]!);
        _setupStreamListener(userId);
      } else {
        state = AsyncValue.error(e, stack);
        // Set up stream listener anyway to catch when admin is created
        _setupStreamListener(userId);
      }
    }
  }

  /// Public method to manually refresh admin data
  Future<void> refresh() async {
    final firestoreAuthState = ref.watch(firestoreAuthServiceProvider);
    final userId = firestoreAuthState.adminId;
    if (userId != null) {
      await _loadAdmin(userId);
    }
  }

  @override
  void dispose() {
    _adminStreamSubscription?.cancel();
    super.dispose();
  }
}

// StateNotifierProvider - keeps notifier alive across navigation
final adminNotifierProvider = StateNotifierProvider<AdminNotifier, AsyncValue<AdminModel?>>((ref) {
  return AdminNotifier(ref);
});

// Admin Provider - Exposes the notifier's state for the current logged-in admin
final adminProvider = Provider<AsyncValue<AdminModel?>>((ref) {
  return ref.watch(adminNotifierProvider);
});
