import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:laundry_app/shared/domain/models/admin_model.dart';

/// Helper class to check admin status
class AdminSetupHelper {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Check if current user is admin
  Future<bool> isCurrentUserAdmin() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      final adminDoc = await _firestore.collection('admin').doc(user.uid).get();
      return adminDoc.exists;
    } catch (e) {
      return false;
    }
  }

  /// Check if a user ID is admin
  Future<bool> isUserAdmin(String userId) async {
    try {
      final adminDoc = await _firestore.collection('admin').doc(userId).get();
      return adminDoc.exists;
    } catch (e) {
      return false;
    }
  }
}

