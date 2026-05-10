import '../models/vocabulary_item.dart';

// SM-2 spaced repetition algorithm
// quality: 0=complete blackout, 3=difficult, 4=good, 5=perfect
class SrsService {
  static void processReview(VocabularyItem item, int quality) {
    assert(quality >= 0 && quality <= 5);
    final now = DateTime.now();
    item.lastReview = now;

    if (quality >= 3) {
      if (item.repetitions == 0) {
        item.interval = 1;
      } else if (item.repetitions == 1) {
        item.interval = 6;
      } else {
        item.interval = (item.interval * item.easeFactor).ceil();
      }
      item.easeFactor =
          item.easeFactor + 0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02);
      if (item.easeFactor < 1.3) item.easeFactor = 1.3;
      item.repetitions++;
    } else {
      item.repetitions = 0;
      item.interval = 1;
    }

    item.nextReview = DateTime(now.year, now.month, now.day)
        .add(Duration(days: item.interval));
  }

  static String nextReviewText(VocabularyItem item) {
    if (item.nextReview == null) return 'Due now';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final reviewDay = DateTime(
        item.nextReview!.year, item.nextReview!.month, item.nextReview!.day);
    final diff = reviewDay.difference(today).inDays;
    if (diff <= 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    if (diff < 7) return 'In $diff days';
    if (diff < 30) return 'In ${(diff / 7).ceil()} week(s)';
    return 'In ${(diff / 30).ceil()} month(s)';
  }

  static const Map<String, int> qualityMap = {
    'Again': 0,
    'Hard': 3,
    'Good': 4,
    'Easy': 5,
  };
}
