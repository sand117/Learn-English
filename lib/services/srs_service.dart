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
    if (item.nextReview == null) return 'Ôn ngay';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final reviewDay = DateTime(
        item.nextReview!.year, item.nextReview!.month, item.nextReview!.day);
    final diff = reviewDay.difference(today).inDays;
    if (diff <= 0) return 'Hôm nay';
    if (diff == 1) return 'Ngày mai';
    if (diff < 7) return '$diff ngày nữa';
    if (diff < 30) return '${(diff / 7).ceil()} tuần nữa';
    return '${(diff / 30).ceil()} tháng nữa';
  }

  static const Map<String, int> qualityMap = {
    'Lại': 0,
    'Khó': 3,
    'Tốt': 4,
    'Dễ': 5,
  };
}
