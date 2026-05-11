class VocabularyItem {
  final String id;
  String content;
  String type; // word | phrase | idiom | sentence
  String meaning;
  String example;
  String videoLink;
  String source;
  String category;
  String ipa;
  String audioUrl;
  String imageUrl;
  DateTime createdAt;

  // SM-2 spaced repetition fields
  double easeFactor; // difficulty multiplier, min 1.3, default 2.5
  int interval;      // days until next review
  int repetitions;   // successful review count
  DateTime? nextReview;
  DateTime? lastReview;
  bool mastered;
  bool favorite;

  VocabularyItem({
    required this.id,
    required this.content,
    this.type = 'word',
    this.meaning = '',
    this.example = '',
    this.videoLink = '',
    this.source = '',
    this.category = 'Tổng hợp',
    this.ipa = '',
    this.audioUrl = '',
    this.imageUrl = '',
    required this.createdAt,
    this.easeFactor = 2.5,
    this.interval = 1,
    this.repetitions = 0,
    this.nextReview,
    this.lastReview,
    this.mastered = false,
    this.favorite = false,
  });

  bool get isDueForReview {
    if (mastered) return false;
    if (nextReview == null) return true;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final reviewDay = DateTime(nextReview!.year, nextReview!.month, nextReview!.day);
    return !reviewDay.isAfter(today);
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'content': content,
        'type': type,
        'meaning': meaning,
        'example': example,
        'videoLink': videoLink,
        'source': source,
        'category': category,
        'ipa': ipa,
        'audioUrl': audioUrl,
        'imageUrl': imageUrl,
        'createdAt': createdAt.toIso8601String(),
        'easeFactor': easeFactor,
        'interval': interval,
        'repetitions': repetitions,
        'nextReview': nextReview?.toIso8601String(),
        'lastReview': lastReview?.toIso8601String(),
        'mastered': mastered,
        'favorite': favorite,
      };

  static DateTime _parseDate(dynamic v) {
    if (v is String) return DateTime.parse(v);
    if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
    return DateTime.now();
  }

  factory VocabularyItem.fromMap(Map<String, dynamic> map) => VocabularyItem(
        id: map['id'] as String? ?? '',
        content: map['content'] as String? ?? '',
        type: map['type'] as String? ?? 'word',
        meaning: map['meaning'] as String? ?? '',
        example: map['example'] as String? ?? '',
        videoLink: map['videoLink'] as String? ?? '',
        source: map['source'] as String? ?? '',
        category: map['category'] as String? ?? 'Tổng hợp',
        ipa: map['ipa'] as String? ?? '',
        audioUrl: map['audioUrl'] as String? ?? '',
        imageUrl: map['imageUrl'] as String? ?? '',
        createdAt: _parseDate(map['createdAt']),
        easeFactor: (map['easeFactor'] as num?)?.toDouble() ?? 2.5,
        interval: map['interval'] as int? ?? 1,
        repetitions: map['repetitions'] as int? ?? 0,
        nextReview: map['nextReview'] != null
            ? DateTime.parse(map['nextReview'] as String)
            : null,
        lastReview: map['lastReview'] != null
            ? DateTime.parse(map['lastReview'] as String)
            : null,
        mastered: map['mastered'] as bool? ?? false,
        favorite: map['favorite'] as bool? ?? false,
      );

  VocabularyItem copyWith({
    String? content,
    String? type,
    String? meaning,
    String? example,
    String? videoLink,
    String? source,
    String? category,
    String? ipa,
    String? audioUrl,
    String? imageUrl,
    double? easeFactor,
    int? interval,
    int? repetitions,
    DateTime? nextReview,
    DateTime? lastReview,
    bool? mastered,
    bool? favorite,
  }) =>
      VocabularyItem(
        id: id,
        content: content ?? this.content,
        type: type ?? this.type,
        meaning: meaning ?? this.meaning,
        example: example ?? this.example,
        videoLink: videoLink ?? this.videoLink,
        source: source ?? this.source,
        category: category ?? this.category,
        ipa: ipa ?? this.ipa,
        audioUrl: audioUrl ?? this.audioUrl,
        imageUrl: imageUrl ?? this.imageUrl,
        createdAt: createdAt,
        easeFactor: easeFactor ?? this.easeFactor,
        interval: interval ?? this.interval,
        repetitions: repetitions ?? this.repetitions,
        nextReview: nextReview ?? this.nextReview,
        lastReview: lastReview ?? this.lastReview,
        mastered: mastered ?? this.mastered,
        favorite: favorite ?? this.favorite,
      );
}
