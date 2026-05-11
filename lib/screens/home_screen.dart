import 'package:flutter/material.dart';
import '../models/vocabulary_item.dart';
import '../services/storage_service.dart';
import '../services/auth_service.dart';
import '../utils/constants.dart';
import '../widgets/vocabulary_card.dart';
import 'add_screen.dart';
import 'detail_screen.dart';
import 'review_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _search = '';
  String _typeFilter = 'all';
  String _categoryFilter = 'all';
  bool _showMastered = false;
  bool _showFavoritesOnly = false;
  int _sessionSize = 0;

  static const _types = ['all', 'word', 'phrase', 'idiom', 'sentence'];
  static const _typeLabels = {
    'all': 'All',
    'word': 'Word',
    'phrase': 'Phrase',
    'idiom': 'Idiom',
    'sentence': 'Sentence',
  };

  List<VocabularyItem> _filter(List<VocabularyItem> items) {
    return items.where((item) {
      if (!_showMastered && item.mastered) return false;
      if (_showFavoritesOnly && !item.favorite) return false;
      if (_typeFilter != 'all' && item.type != _typeFilter) return false;
      if (_categoryFilter != 'all' && item.category != _categoryFilter)
        return false;
      if (_search.isNotEmpty) {
        final q = _search.toLowerCase();
        return item.content.toLowerCase().contains(q) ||
            item.meaning.toLowerCase().contains(q);
      }
      return true;
    }).toList();
  }

  void _startReview(BuildContext context, int due) {
    final count = (_sessionSize == 0 || _sessionSize > due) ? due : _sessionSize;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ReviewScreen(maxCount: count)),
    );
  }

  void _confirmSignOut(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text('Your data is saved in the cloud and will be available when you sign back in.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await AuthService.signOut();
            },
            child: const Text('Sign out', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: StreamBuilder<List<VocabularyItem>>(
        stream: StorageService.stream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading data:\n${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red, fontSize: 13),
                    ),
                  ],
                ),
              ),
            );
          }

          final all = snapshot.data ?? [];
          final dueItems = all.where((i) => i.isDueForReview && !i.mastered).toList();
          final due = dueItems.length;
          final mastered = all.where((i) => i.mastered).length;
          final favorites = all.where((i) => i.favorite).length;
          final filtered = _filter(all);

          final usedCats = all.map((i) => i.category).toSet();
          final allCats = [
            ...kCategories,
            ...usedCats.where((c) => !kCategories.contains(c)),
          ];
          final categories = ['all', ...allCats];

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                expandedHeight: 140,
                backgroundColor: primary,
                foregroundColor: Colors.white,
                title: const Text('Learn English',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                flexibleSpace: FlexibleSpaceBar(
                  background: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(0, 56, 0, 8),
                      child: LayoutBuilder(
                        builder: (_, constraints) {
                          if (constraints.maxWidth < 100 || constraints.maxHeight < 55) {
                            return const SizedBox.shrink();
                          }
                          return Row(
                            children: [
                              Expanded(child: _StatItem('Total', '${all.length}', Icons.library_books, Colors.white)),
                              Expanded(child: _StatItem('Due', '$due', Icons.schedule, due > 0 ? Colors.orangeAccent : Colors.white70)),
                              Expanded(child: _StatItem('Mastered', '$mastered', Icons.check_circle, Colors.greenAccent)),
                              Expanded(child: _StatItem('Favorites', '$favorites', Icons.star, Colors.amberAccent)),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
                actions: [
                  IconButton(
                    icon: Icon(_showFavoritesOnly ? Icons.star : Icons.star_border),
                    tooltip: _showFavoritesOnly ? 'Favorites only' : 'Favorites',
                    color: _showFavoritesOnly ? Colors.amber : Colors.white,
                    onPressed: () => setState(() => _showFavoritesOnly = !_showFavoritesOnly),
                  ),
                  IconButton(
                    icon: Icon(_showMastered ? Icons.visibility : Icons.visibility_off),
                    tooltip: _showMastered ? 'Hide mastered' : 'Show mastered',
                    onPressed: () => setState(() => _showMastered = !_showMastered),
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout),
                    tooltip: 'Sign out',
                    onPressed: () => _confirmSignOut(context),
                  ),
                ],
              ),

              // Review banner
              if (due > 0)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => _startReview(context, due),
                          icon: const Icon(Icons.play_arrow),
                          label: Text(
                            'Review now — ${(_sessionSize == 0 || _sessionSize > due) ? due : _sessionSize} cards',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text('Cards/session:',
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                            const SizedBox(width: 8),
                            ...[5, 10, 20, 0].map((n) {
                              final label = n == 0 ? 'All' : '$n';
                              final selected = _sessionSize == n;
                              return Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: ChoiceChip(
                                  label: Text(label),
                                  selected: selected,
                                  onSelected: (_) => setState(() => _sessionSize = n),
                                  selectedColor: Colors.orange.shade100,
                                  labelStyle: TextStyle(
                                    fontSize: 12,
                                    fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                                    color: selected ? Colors.orange.shade800 : Colors.grey.shade700,
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 6),
                                ),
                              );
                            }),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

              // Search bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _search.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () => setState(() => _search = ''))
                          : null,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                    onChanged: (v) => setState(() => _search = v),
                  ),
                ),
              ),

              // Type filter
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 48,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                    itemCount: _types.length,
                    itemBuilder: (_, i) {
                      final t = _types[i];
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(_typeLabels[t]!),
                          selected: _typeFilter == t,
                          onSelected: (selected) => setState(
                              () => _typeFilter = selected ? t : 'all'),
                          selectedColor: Theme.of(context).colorScheme.primaryContainer,
                        ),
                      );
                    },
                  ),
                ),
              ),

              // Category filter
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 48,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                    itemCount: categories.length,
                    itemBuilder: (_, i) {
                      final c = categories[i];
                      final label = c == 'all' ? 'All topics' : c;
                      final hasItems = c == 'all' || usedCats.contains(c);
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(label),
                          selected: _categoryFilter == c,
                          onSelected: (selected) => setState(
                              () => _categoryFilter = selected ? c : 'all'),
                          selectedColor: Colors.teal.shade100,
                          labelStyle: TextStyle(
                            fontSize: 12,
                            color: _categoryFilter == c
                                ? Colors.teal.shade800
                                : hasItems
                                    ? null
                                    : Colors.grey.shade400,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // List
              filtered.isEmpty
                  ? SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.library_books_outlined,
                                size: 64, color: Colors.grey.shade300),
                            const SizedBox(height: 16),
                            Text(
                              all.isEmpty
                                  ? 'No words yet\nTap + to add a new word'
                                  : 'No words found',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: Colors.grey.shade500, height: 1.6),
                            ),
                          ],
                        ),
                      ),
                    )
                  : SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (_, i) => VocabularyCard(
                            item: filtered[i],
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => DetailScreen(item: filtered[i])),
                            ),
                          ),
                          childCount: filtered.length,
                        ),
                      ),
                    ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const AddScreen())),
        icon: const Icon(Icons.add),
        label: const Text('Add word'),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatItem(this.label, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(height: 2),
        Text(value,
            style: TextStyle(
                color: color, fontWeight: FontWeight.bold, fontSize: 18)),
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 10)),
      ],
    );
  }
}
