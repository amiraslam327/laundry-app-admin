import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:laundry_app/shared/domain/models/laundry_model.dart';

class LaundriesRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'laundries';

  Stream<List<LaundryModel>> getAllLaundries() {
    return _firestore
        .collection(_collection)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) {
                try {
                  final data = doc.data();
                  return LaundryModel.fromMap(data);
                } catch (e) {
                  rethrow;
                }
              })
              .toList();
        })
        .handleError((error) {
          throw error;
        });
  }

  Future<List<LaundryModel>> getAllLaundriesOnce() async {
    final snapshot = await _firestore.collection(_collection).get();
    return snapshot.docs
        .map((doc) => LaundryModel.fromMap(doc.data()))
        .toList();
  }

  Future<LaundryModel?> getLaundry(String laundryId) async {
    final doc = await _firestore.collection(_collection).doc(laundryId).get();
    if (!doc.exists) return null;
    return LaundryModel.fromMap(doc.data()!);
  }

  Stream<LaundryModel?> getLaundryStream(String laundryId) {
    return _firestore
        .collection(_collection)
        .doc(laundryId)
        .snapshots()
        .map((doc) => doc.exists ? LaundryModel.fromMap(doc.data()!) : null);
  }

  Stream<List<LaundryModel>> searchLaundries(String query) {
    return _firestore
        .collection(_collection)
        .where('name', isGreaterThanOrEqualTo: query)
        .where('name', isLessThan: query + 'z')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => LaundryModel.fromMap(doc.data()))
            .toList());
  }
}

