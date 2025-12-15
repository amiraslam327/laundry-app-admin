import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:laundry_app/shared/domain/models/fragrance_model.dart';

class FragrancesRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'fragrances';

  Stream<List<FragranceModel>> getAllFragrances() {
    return _firestore
        .collection(_collection)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return FragranceModel.fromMap(data);
            })
            .toList());
  }

  Future<List<FragranceModel>> getAllFragrancesOnce() async {
    final snapshot = await _firestore.collection(_collection).get();
    return snapshot.docs
        .map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return FragranceModel.fromMap(data);
        })
        .toList();
  }

  Future<FragranceModel?> getFragrance(String fragranceId) async {
    final doc =
        await _firestore.collection(_collection).doc(fragranceId).get();
    if (!doc.exists) return null;
    final data = doc.data()!;
    data['id'] = doc.id;
    return FragranceModel.fromMap(data);
  }

  Future<void> createFragrance(FragranceModel fragrance) async {
    await _firestore
        .collection(_collection)
        .doc(fragrance.id)
        .set(fragrance.toMap());
  }

  Future<void> updateFragrance(FragranceModel fragrance) async {
    await _firestore
        .collection(_collection)
        .doc(fragrance.id)
        .update(fragrance.toMap());
  }

  Future<void> deleteFragrance(String fragranceId) async {
    await _firestore.collection(_collection).doc(fragranceId).delete();
  }
}

