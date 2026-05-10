import 'dart:math';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/vocabulary_item.dart';
import '../services/srs_service.dart';
import '../services/storage_service.dart';

class ReviewScreen extends StatefulWidget {
  final int? maxCount;
  const ReviewScreen({super.key, this.maxCount});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen>
    with SingleTickerProviderStateMixin {
  List<VocabularyItem> _queue = [];
  bool _loaded = false;
  int _currentIndex = 0;
  bool _flipped = false;
  int _reviewed = 0;

  late AnimationController _flipCtrl;
  late Animation<double> _flipAnim;

  @override
  void initState() {
    super.initState();
    _flipCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));
    _flipAnim = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _flipCtrl, curve: Curves.easeInOut));
    _loadQueue();
  }

  Future<void> _loadQueue() async {
    final items = await StorageService.getDueItems();
    items.shuffle(Random());
    if (widget.maxCount != null && widget.maxCount! < items.length) {
      items.removeRange(widget.maxCount!, items.length);
    }
    if (mounted) setState(() { _queue = items; _loaded = true; });
  }

  @override
  void dispose() {
    _flipCtrl.dispose();
    super.dispose();
  }

  VocabularyItem? get _current =>
      _currentIndex < _queue.length ? _queue[_currentIndex] : null;

  void _flip() {
    if (_flipped) return;
    setState(() => _flipped = true);
    _flipCtrl.forward();
  }

  Future<void> _rate(String label) async {
    final quality = SrsService.qualityMap[label]!;
    final item = _current!;
    SrsService.processReview(item, quality);
    await StorageService.save(item);

    setState(() {
      _reviewed++;
      _currentIndex++;
      _flipped = false;
    });
    _flipCtrl.reset();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_queue.isEmpty) {
      return _DoneScreen(message: 'Nothing to review today!');
    }
    if (_current == null) {
      return _DoneScreen(
          message: 'Done! Reviewed $_reviewed/${_queue.length} cards.');
    }

    final item = _current!;
    final progress = _currentIndex / _queue.length;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text('Review — ${_currentIndex + 1}/${_queue.length}'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white30,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 24),

          Expanded(
            child: GestureDetector(
              onTap: _flip,
              child: AnimatedBuilder(
                animation: _flipAnim,
                builder: (context, child) {
                  final angle = _flipAnim.value * pi;
                  final isBack = angle > pi / 2;
                  return Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001)
                      ..rotateX(angle),
                    child: isBack
                        ? _CardBack(item: item)
                        : _CardFront(item: item),
                  );
                },
              ),
            ),
          ),

          if (!_flipped)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text('Tap the card to reveal',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
            ),

          if (_flipped)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              child: Column(
                children: [
                  Text('How well did you remember?',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                  const SizedBox(height: 12),
                  Row(
                    children: SrsService.qualityMap.keys
                        .map((label) => Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                child: _RatingButton(
                                    label: label, onTap: () => _rate(label)),
                              ),
                            ))
                        .toList(),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _CardFront extends StatelessWidget {
  final VocabularyItem item;
  const _CardFront({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: SizedBox(
          width: double.infinity,
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _TypeChip(type: item.type),
                const SizedBox(height: 24),
                Text(
                  item.content,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                if (item.ipa.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text('/${item.ipa}/',
                      style: TextStyle(
                          fontSize: 15,
                          color: Colors.indigo.shade300,
                          letterSpacing: 0.5)),
                ],
                if (item.source.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text('📖 ${item.source}',
                      style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
                ],
                const Spacer(),
                Icon(Icons.touch_app, color: Colors.grey.shade300, size: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CardBack extends StatelessWidget {
  final VocabularyItem item;
  const _CardBack({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: SizedBox(
          width: double.infinity,
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()..rotateX(pi),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: Column(
                children: [
                  Text(
                    item.content,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary),
                  ),
                  const Divider(height: 28),
                  if (item.meaning.isNotEmpty) ...[
                    Text(item.meaning,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 17, height: 1.5)),
                    const SizedBox(height: 16),
                  ],
                  if (item.example.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '"${item.example}"',
                        style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                            fontStyle: FontStyle.italic,
                            height: 1.5),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (item.imageUrl.isNotEmpty) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        item.imageUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: 140,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (item.audioUrl.isNotEmpty)
                    TextButton.icon(
                      onPressed: () => launchUrl(Uri.parse(item.audioUrl)),
                      icon: const Icon(Icons.volume_up),
                      label: const Text('Listen'),
                    ),
                  if (item.videoLink.isNotEmpty)
                    TextButton.icon(
                      onPressed: () => launchUrl(Uri.parse(item.videoLink)),
                      icon: const Icon(Icons.play_circle_outline),
                      label: const Text('Watch video'),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RatingButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _RatingButton({required this.label, required this.onTap});

  static const _colors = {
    'Again': Color(0xFFE53935),
    'Hard': Color(0xFFFF7043),
    'Good': Color(0xFF43A047),
    'Easy': Color(0xFF1E88E5),
  };

  @override
  Widget build(BuildContext context) {
    final color = _colors[label] ?? Colors.grey;
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String type;
  const _TypeChip({required this.type});

  static const _labels = {
    'word': 'Word',
    'phrase': 'Phrase',
    'idiom': 'Idiom',
    'sentence': 'Sentence',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _labels[type] ?? type,
        style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.primary),
      ),
    );
  }
}

class _DoneScreen extends StatelessWidget {
  final String message;
  const _DoneScreen({required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.celebration, size: 72, color: Colors.amber),
              const SizedBox(height: 24),
              Text(message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Back to Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
