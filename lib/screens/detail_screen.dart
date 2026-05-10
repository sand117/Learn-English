import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/vocabulary_item.dart';
import '../services/srs_service.dart';
import '../services/storage_service.dart';
import 'add_screen.dart';

class DetailScreen extends StatefulWidget {
  final VocabularyItem item;
  const DetailScreen({super.key, required this.item});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  late VocabularyItem _item;
  final _dateFmt = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    _item = widget.item;
  }

  Future<void> _toggleMastered() async {
    _item.mastered = !_item.mastered;
    await StorageService.save(_item);
    setState(() {});
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete?'),
        content: Text('Remove "${_item.content}" from your list?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await StorageService.delete(_item.id);
      Navigator.pop(context);
    }
  }

  Future<void> _edit() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddScreen(editItem: _item)),
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Detail'),
        backgroundColor: primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(
              _item.favorite ? Icons.star : Icons.star_border,
              color: _item.favorite ? Colors.amber : Colors.white,
            ),
            tooltip: _item.favorite ? 'Remove from favorites' : 'Add to favorites',
            onPressed: () async {
              _item.favorite = !_item.favorite;
              await StorageService.save(_item);
              setState(() {});
            },
          ),
          IconButton(icon: const Icon(Icons.edit), onPressed: _edit),
          IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _delete),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header card
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey.shade200)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            _item.content,
                            style: const TextStyle(
                                fontSize: 26, fontWeight: FontWeight.bold),
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            _TypeBadge(type: _item.type),
                            const SizedBox(height: 4),
                            _CategoryBadge(category: _item.category),
                          ],
                        ),
                      ],
                    ),
                    if (_item.mastered) ...[
                      const SizedBox(height: 8),
                      Row(children: [
                        Icon(Icons.check_circle,
                            color: Colors.green.shade400, size: 16),
                        const SizedBox(width: 4),
                        Text('Mastered',
                            style: TextStyle(
                                color: Colors.green.shade600,
                                fontWeight: FontWeight.w600)),
                      ]),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            if (_item.ipa.isNotEmpty)
              _Section(
                icon: Icons.record_voice_over,
                title: 'IPA',
                child: Text(
                  '/${_item.ipa}/',
                  style: const TextStyle(
                      fontSize: 18,
                      letterSpacing: 1,
                      fontWeight: FontWeight.w500),
                ),
              ),

            if (_item.imageUrl.isNotEmpty)
              _Section(
                icon: Icons.image_outlined,
                title: 'Image',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    _item.imageUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: 180,
                    errorBuilder: (_, __, ___) => Container(
                      height: 60,
                      color: Colors.grey.shade100,
                      child: Center(
                        child: Text('Failed to load image',
                            style:
                                TextStyle(color: Colors.grey.shade500)),
                      ),
                    ),
                  ),
                ),
              ),

            if (_item.meaning.isNotEmpty)
              _Section(
                  icon: Icons.translate,
                  title: 'Meaning',
                  child: Text(_item.meaning,
                      style:
                          const TextStyle(fontSize: 16, height: 1.5))),

            if (_item.example.isNotEmpty)
              _Section(
                icon: Icons.format_quote,
                title: 'Example',
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10)),
                  child: Text('"${_item.example}"',
                      style: TextStyle(
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                          color: Colors.grey.shade700,
                          height: 1.5)),
                ),
              ),

            if (_item.audioUrl.isNotEmpty)
              _Section(
                icon: Icons.volume_up,
                title: 'Audio',
                child: OutlinedButton.icon(
                  onPressed: () => launchUrl(Uri.parse(_item.audioUrl)),
                  icon: const Icon(Icons.play_circle_outline),
                  label: const Text('Listen'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),

            if (_item.videoLink.isNotEmpty)
              _Section(
                icon: Icons.play_circle_outline,
                title: 'Video',
                child: InkWell(
                  onTap: () => launchUrl(Uri.parse(_item.videoLink)),
                  child: Text(_item.videoLink,
                      style: TextStyle(
                          color: primary,
                          decoration: TextDecoration.underline,
                          fontSize: 13)),
                ),
              ),

            if (_item.source.isNotEmpty)
              _Section(
                  icon: Icons.source,
                  title: 'Source',
                  child: Text(_item.source,
                      style: const TextStyle(fontSize: 14))),

            _Section(
              icon: Icons.analytics_outlined,
              title: 'Review Schedule',
              child: Column(
                children: [
                  _StatRow('Added',
                      _dateFmt.format(_item.createdAt)),
                  _StatRow('Next Review',
                      SrsService.nextReviewText(_item)),
                  _StatRow('Reviewed',
                      '${_item.repetitions}x'),
                  _StatRow('Ease Factor',
                      _item.easeFactor.toStringAsFixed(2)),
                  _StatRow('Interval',
                      '${_item.interval} day(s)'),
                  if (_item.lastReview != null)
                    _StatRow('Last Review',
                        _dateFmt.format(_item.lastReview!)),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Toggle mastered
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _toggleMastered,
                icon: Icon(_item.mastered
                    ? Icons.remove_circle_outline
                    : Icons.check_circle_outline),
                label: Text(_item.mastered
                    ? 'Unmark as Mastered'
                    : 'Mark as Mastered'),
                style: OutlinedButton.styleFrom(
                  foregroundColor:
                      _item.mastered ? Colors.red : Colors.green,
                  side: BorderSide(
                      color: _item.mastered ? Colors.red : Colors.green),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;
  const _Section(
      {required this.icon, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: Colors.grey.shade200)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(icon,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 6),
                Text(title,
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.primary,
                        letterSpacing: 0.5)),
              ]),
              const SizedBox(height: 10),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  const _StatRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style:
                  TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  final String category;
  const _CategoryBadge({required this.category});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.teal.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.teal.shade100),
      ),
      child: Text(category,
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.teal.shade700)),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  final String type;
  const _TypeBadge({required this.type});

  static const _labels = {
    'word': 'Word',
    'phrase': 'Phrase',
    'idiom': 'Idiom',
    'sentence': 'Sentence',
  };
  static const _colors = {
    'word': Color(0xFF3F51B5),
    'phrase': Color(0xFF009688),
    'idiom': Color(0xFF9C27B0),
    'sentence': Color(0xFFE91E63),
  };

  @override
  Widget build(BuildContext context) {
    final color = _colors[type] ?? const Color(0xFF3F51B5);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10)),
      child: Text(_labels[type] ?? type,
          style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w700, color: color)),
    );
  }
}
