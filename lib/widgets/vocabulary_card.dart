import 'package:flutter/material.dart';
import '../models/vocabulary_item.dart';
import '../services/srs_service.dart';
import '../services/storage_service.dart';

const _typeColor = {
  'word': Color(0xFF3F51B5),
  'phrase': Color(0xFF009688),
  'idiom': Color(0xFF9C27B0),
  'sentence': Color(0xFFE91E63),
};

const _typeLabel = {
  'word': 'Word',
  'phrase': 'Phrase',
  'idiom': 'Idiom',
  'sentence': 'Sentence',
};

class VocabularyCard extends StatelessWidget {
  final VocabularyItem item;
  final VoidCallback onTap;

  const VocabularyCard({super.key, required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = _typeColor[item.type] ?? const Color(0xFF3F51B5);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      item.content,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: item.mastered
                            ? Colors.grey.shade400
                            : Colors.grey.shade900,
                        decoration:
                            item.mastered ? TextDecoration.lineThrough : null,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () async {
                      item.favorite = !item.favorite;
                      await StorageService.save(item);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        item.favorite ? Icons.star : Icons.star_border,
                        size: 18,
                        color: item.favorite
                            ? Colors.amber
                            : Colors.grey.shade300,
                      ),
                    ),
                  ),
                  _TypeBadge(type: item.type, color: color),
                ],
              ),
              if (item.meaning.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  item.meaning.length > 80
                      ? '${item.meaning.substring(0, 80)}…'
                      : item.meaning,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    height: 1.4,
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  _ReviewBadge(item: item),
                  const Spacer(),
                  _CategoryBadge(category: item.category),
                  const SizedBox(width: 6),
                  if (item.audioUrl.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Icon(Icons.volume_up,
                        size: 16, color: Colors.grey.shade400),
                  ],
                  if (item.imageUrl.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Icon(Icons.image_outlined,
                        size: 16, color: Colors.grey.shade400),
                  ],
                  if (item.videoLink.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Icon(Icons.play_circle_outline,
                        size: 16, color: Colors.grey.shade400),
                  ],
                  if (item.example.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Icon(Icons.format_quote,
                        size: 16, color: Colors.grey.shade400),
                  ],
                  if (item.mastered) ...[
                    const SizedBox(width: 6),
                    Icon(Icons.check_circle,
                        size: 16, color: Colors.green.shade400),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  final String type;
  final Color color;
  const _TypeBadge({required this.type, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        _typeLabel[type] ?? type,
        style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}

class _ReviewBadge extends StatelessWidget {
  final VocabularyItem item;
  const _ReviewBadge({required this.item});

  @override
  Widget build(BuildContext context) {
    final isDue = item.isDueForReview;
    final text = SrsService.nextReviewText(item);
    final color = isDue ? Colors.orange : Colors.grey.shade400;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(isDue ? Icons.schedule : Icons.event,
            size: 13, color: color),
        const SizedBox(width: 3),
        Text(text,
            style: TextStyle(
                fontSize: 11, color: color, fontWeight: FontWeight.w500)),
      ],
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  final String category;
  const _CategoryBadge({required this.category});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.teal.shade50,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.teal.shade100),
      ),
      child: Text(
        category,
        style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: Colors.teal.shade700),
      ),
    );
  }
}

Future<void> toggleMastered(
    BuildContext context, VocabularyItem item) async {
  item.mastered = !item.mastered;
  await StorageService.save(item);
}
