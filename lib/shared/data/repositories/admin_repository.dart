import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:laundry_app/shared/domain/models/admin_model.dart';

class AdminRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'admin';

  /// Check if admin exists by ID
  Future<bool> adminExists(String adminId) async {
    final doc = await _firestore.collection(_collection).doc(adminId).get();
    return doc.exists;
  }

  /// Check if admin exists by email
  Future<bool> adminExistsByEmail(String email) async {
    final query = await _firestore
        .collection(_collection)
        .where('email', isEqualTo: email)
        .limit(1)
        .get();
    return query.docs.isNotEmpty;
  }

  /// Get admin by email
  Future<AdminModel?> getAdminByEmail(String email) async {
    final query = await _firestore
        .collection(_collection)
        .where('email', isEqualTo: email)
        .limit(1)
        .get();
    
    if (query.docs.isEmpty) return null;
    final doc = query.docs.first;
    final data = doc.data();
    // Ensure uid and id fields are set
    if (!data.containsKey('uid')) {
      data['uid'] = doc.id;
    }
    if (!data.containsKey('id')) {
      data['id'] = doc.id;
    }
    return AdminModel.fromMap(data);
  }

  Future<AdminModel?> getAdmin(String adminId) async {
    final doc = await _firestore.collection(_collection).doc(adminId).get();
    if (!doc.exists) return null;
    final data = doc.data()!;
    // Ensure uid and id fields are set
    if (!data.containsKey('uid')) {
      data['uid'] = doc.id;
    }
    if (!data.containsKey('id')) {
      data['id'] = doc.id;
    }
    return AdminModel.fromMap(data);
  }

  Stream<AdminModel?> getAdminStream(String adminId) {
    return _firestore
        .collection(_collection)
        .doc(adminId)
        .snapshots(includeMetadataChanges: true) // Include metadata changes for better updates
        .map((doc) {
          if (!doc.exists) return null;
          try {
            final data = doc.data()!;
            // Ensure uid and id fields are set
            if (!data.containsKey('uid')) {
              data['uid'] = doc.id;
            }
            if (!data.containsKey('id')) {
              data['id'] = doc.id;
            }
            return AdminModel.fromMap(data);
          } catch (e) {
            // Log error but return null to prevent crashes
            return null;
          }
        });
  }

  Future<void> updateAdmin(String adminId, Map<String, dynamic> updates) async {
    await _firestore.collection(_collection).doc(adminId).update(updates);
  }

  Future<void> updateAdminModel(AdminModel admin) async {
    await _firestore.collection(_collection).doc(admin.id).update(admin.toMap());
  }

  Future<bool> isAdmin(String adminId) async {
    final doc = await _firestore.collection(_collection).doc(adminId).get();
    return doc.exists;
  }

  /// Get all admins as a stream
  /// Only returns admins where visible is true
  Stream<List<AdminModel>> getAllAdmins() {
    return _firestore
        .collection(_collection)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) {
              try {
                final data = doc.data();
                // Always use doc.id as the source of truth for admin ID
                // The document ID should match the Firebase Auth UID
                data['uid'] = doc.id;
                data['id'] = doc.id;
                
                // Ensure visible field exists (default to true if not set)
                if (!data.containsKey('visible')) {
                  data['visible'] = true;
                }
                
                return AdminModel.fromMap(data);
              } catch (e) {
                // Log error and skip this document
                return null;
              }
            })
            .whereType<AdminModel>()
            .where((admin) => admin.visible == true) // Only show visible admins
            .toList());
  }

  /// Create a new admin document in Firestore
  /// Prevents overwriting existing admin data - throws exception if document exists
  /// Note: Firebase Auth user should be created separately before calling this
  Future<void> createAdmin(AdminModel admin) async {
    // Check if document already exists
    final docRef = _firestore.collection(_collection).doc(admin.id);
    final docSnapshot = await docRef.get();
    
    if (docSnapshot.exists) {
      throw Exception('Admin document already exists with ID: ${admin.id}. Cannot overwrite existing admin data.');
    }
    
    // Use the admin's id (uid) as the document ID
    // Set with merge: false to ensure we don't overwrite existing data
    await docRef.set(admin.toMap(), SetOptions(merge: false));
  }

  /// Create a new admin document in Firestore with password hash
  /// Prevents overwriting existing admin data - throws exception if document exists
  /// Saves all fields: id, uid, fullName, name, email, phoneNumber, phone, role, createdAt, visible, passwordHash
  Future<void> createAdminWithPassword(AdminModel admin, String passwordHash) async {
    // Check if document already exists
    final docRef = _firestore.collection(_collection).doc(admin.id);
    final docSnapshot = await docRef.get();
    
    if (docSnapshot.exists) {
      throw Exception('Admin document already exists with ID: ${admin.id}. Cannot overwrite existing admin data.');
    }
    
    // Create document with admin data and password hash
    // Include all fields: id, uid, fullName, name, email, phoneNumber, phone, role, createdAt, visible, passwordHash
    final data = admin.toMap();
    data['passwordHash'] = passwordHash; // Add password hash
    data['uid'] = admin.id; // Ensure uid field is set (same as id)
    
    // Set with merge: false to ensure we don't overwrite existing data
    await docRef.set(data, SetOptions(merge: false));
  }

  /// Delete an admin document from Firestore
  /// Note: This does NOT delete the Firebase Auth user - that should be done via Cloud Function
  Future<void> deleteAdmin(String adminId) async {
    await _firestore.collection(_collection).doc(adminId).delete();
  }
}

