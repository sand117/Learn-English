import 'package:hive_flutter/hive_flutter.dart';
import '../models/vocabulary_item.dart';

class StorageService {
  static const _boxName = 'vocabulary';

  static Box get _box => Hive.box(_boxName);

  static List<VocabularyItem> getAll() {
    return _box.values
        .map((e) => VocabularyItem.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  static List<VocabularyItem> getDueItems() {
    return getAll().where((item) => item.isDueForReview).toList();
  }

  static Future<void> save(VocabularyItem item) async {
    await _box.put(item.id, item.toMap());
  }

  static Future<void> delete(String id) async {
    await _box.delete(id);
  }

  static int get totalCount => _box.length;

  static int get masteredCount =>
      getAll().where((item) => item.mastered).length;

  static int get dueCount => getDueItems().length;

  static List<String> getCategories() {
    final cats = getAll().map((i) => i.category).toSet().toList();
    cats.sort();
    return cats;
  }

  static Map<String, int> get typeCounts {
    final items = getAll();
    return {
      'word': items.where((i) => i.type == 'word').length,
      'phrase': items.where((i) => i.type == 'phrase').length,
      'idiom': items.where((i) => i.type == 'idiom').length,
      'sentence': items.where((i) => i.type == 'sentence').length,
    };
  }
}
