import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:laundry_app/shared/data/repositories/admin_repository.dart';
import 'package:laundry_app/shared/domain/models/admin_model.dart';
import 'package:laundry_app/shared/utils/password_hasher.dart';
import 'package:flutter/foundation.dart';

/// State class for Firestore authentication
class FirestoreAuthState {
  final AdminModel? admin;
  final String? adminId;
  final bool isLoggedIn;
  final bool isRestoring;

  const FirestoreAuthState({
    this.admin,
    this.adminId,
    this.isLoggedIn = false,
    this.isRestoring = true, // Start with true to show loading initially
  });

  FirestoreAuthState copyWith({
    AdminModel? admin,
    String? adminId,
    bool? isLoggedIn,
    bool? isRestoring,
  }) {
    return FirestoreAuthState(
      admin: admin ?? this.admin,
      adminId: adminId ?? this.adminId,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      isRestoring: isRestoring ?? this.isRestoring,
    );
  }
}

/// Custom authentication service that uses Firestore instead of Firebase Auth
class FirestoreAuthNotifier extends StateNotifier<FirestoreAuthState> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AdminRepository _adminRepository = AdminRepository();
  
  static const String _prefAdminIdKey = 'logged_in_admin_id';
  static const String _prefAdminEmailKey = 'logged_in_admin_email';

  bool _isRestoring = false;
  
  FirestoreAuthNotifier() : super(const FirestoreAuthState()) {
    // Restore login state on initialization
    _restoreLoginState();
  }
  
  /// Restore login state from SharedPreferences
  Future<void> _restoreLoginState() async {
    if (_isRestoring) return; // Prevent multiple simultaneous restorations
    _isRestoring = true;
    
    // Set restoring state to true
    state = state.copyWith(isRestoring: true);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedAdminId = prefs.getString(_prefAdminIdKey);
      final savedEmail = prefs.getString(_prefAdminEmailKey);
      
      if (savedAdminId != null && savedAdminId.isNotEmpty) {
        // Try to load admin from Firestore
        final admin = await _adminRepository.getAdmin(savedAdminId);
        
        if (admin != null && admin.visible == true) {
          // Admin exists and is visible, restore login state
          state = FirestoreAuthState(
            admin: admin,
            adminId: admin.id,
            isLoggedIn: true,
            isRestoring: false, // Restoration complete
          );
        } else {
          // Admin not found or not visible, clear saved state
          await _clearSavedLoginState();
          state = const FirestoreAuthState(isRestoring: false); // Restoration complete, not logged in
        }
      } else {
        state = const FirestoreAuthState(isRestoring: false); // Restoration complete, not logged in
      }
    } catch (e, stackTrace) {
      // Clear saved state on error
      await _clearSavedLoginState();
      state = const FirestoreAuthState(isRestoring: false); // Restoration complete, not logged in
    } finally {
      _isRestoring = false;
    }
  }
  
  /// Save login state to SharedPreferences
  Future<void> _saveLoginState(String adminId, String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefAdminIdKey, adminId);
      await prefs.setString(_prefAdminEmailKey, email);
    } catch (e) {
      // Error saving login state
    }
  }
  
  /// Clear saved login state from SharedPreferences
  Future<void> _clearSavedLoginState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefAdminIdKey);
      await prefs.remove(_prefAdminEmailKey);
    } catch (e) {
      // Error clearing saved login state
    }
  }

  /// Get current logged-in admin
  AdminModel? get currentAdmin => state.admin;
  String? get currentAdminId => state.adminId;
  bool get isLoggedIn => state.isLoggedIn;
  
  /// Manually trigger restoration (useful for debugging or manual refresh)
  Future<void> restoreLoginState() => _restoreLoginState();

  /// Sign in with email and password (checks Firestore)
  Future<AdminModel> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      // Find admin by email
      final admin = await _adminRepository.getAdminByEmail(email.trim().toLowerCase());
      
      if (admin == null) {
        throw Exception('No admin found with this email');
      }

      // Get password hash from Firestore
      final adminDoc = await _firestore.collection('admin').doc(admin.id).get();
      final data = adminDoc.data();
      
      if (data == null || !data.containsKey('passwordHash')) {
        throw Exception('Admin account not properly configured');
      }

      final storedHash = data['passwordHash'] as String;

      // Verify password
      if (!PasswordHasher.verifyPassword(password, storedHash)) {
        throw Exception('Invalid password');
      }

      // Update state
      state = FirestoreAuthState(
        admin: admin,
        adminId: admin.id,
        isLoggedIn: true,
        isRestoring: false, // Not restoring, user just logged in
      );

      // Save login state to SharedPreferences for persistence
      await _saveLoginState(admin.id, admin.email);

      return admin;
    } catch (e) {
      throw Exception('Login failed: ${e.toString()}');
    }
  }

  /// Sign out
  Future<void> signOut() async {
    // Clear saved login state
    await _clearSavedLoginState();
    // Clear in-memory state
    state = const FirestoreAuthState(isRestoring: false); // Not restoring, user logged out
  }
}

