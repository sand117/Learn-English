import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/vocabulary_item.dart';
import 'auth_service.dart';

class StorageService {
  static CollectionReference<Map<String, dynamic>> get _col =>
      FirebaseFirestore.instance
          .collection('users')
          .doc(AuthService.uid)
          .collection('vocabulary');

  static Stream<List<VocabularyItem>> get stream => _col
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snap) => snap.docs
          .map((d) => VocabularyItem.fromMap({...d.data(), 'id': d.id}))
          .toList());

  static Future<List<VocabularyItem>> getAll() async {
    final snap = await _col.orderBy('createdAt', descending: true).get();
    return snap.docs
        .map((d) => VocabularyItem.fromMap({...d.data(), 'id': d.id}))
        .toList();
  }

  static Future<List<VocabularyItem>> getDueItems() async {
    final all = await getAll();
    return all.where((item) => item.isDueForReview).toList();
  }

  static Future<void> save(VocabularyItem item) async {
    await _col.doc(item.id).set(item.toMap());
  }

  static Future<void> delete(String id) async {
    await _col.doc(id).delete();
  }

  static Future<int> get totalCount async => (await _col.count().get()).count ?? 0;

  static Future<int> get masteredCount async {
    final snap = await _col.where('mastered', isEqualTo: true).count().get();
    return snap.count ?? 0;
  }

  static Future<int> getDueCount() async =>
      (await getDueItems()).length;

  static Future<List<String>> getCategories() async {
    final all = await getAll();
    final cats = all.map((i) => i.category).toSet().toList();
    cats.sort();
    return cats;
  }
}
