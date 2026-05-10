import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import '../models/vocabulary_item.dart';
import '../services/storage_service.dart';
import '../utils/constants.dart';

class AddScreen extends StatefulWidget {
  final VocabularyItem? editItem;
  const AddScreen({super.key, this.editItem});

  @override
  State<AddScreen> createState() => _AddScreenState();
}

class _AddScreenState extends State<AddScreen> {
  final _formKey = GlobalKey<FormState>();
  final _contentCtrl = TextEditingController();
  final _meaningCtrl = TextEditingController();
  final _exampleCtrl = TextEditingController();
  final _videoCtrl = TextEditingController();
  final _sourceCtrl = TextEditingController();
  final _customCategoryCtrl = TextEditingController();
  final _ipaCtrl = TextEditingController();
  final _audioCtrl = TextEditingController();
  final _imageCtrl = TextEditingController();

  String _type = 'word';
  String _category = 'General';
  bool _saving = false;
  bool _showIpaPicker = false;

  static const _types = ['word', 'phrase', 'idiom', 'sentence'];
  static const _typeLabels = {
    'word': 'Word',
    'phrase': 'Phrase',
    'idiom': 'Idiom',
    'sentence': 'Sentence',
  };

  @override
  void initState() {
    super.initState();
    if (widget.editItem != null) {
      final item = widget.editItem!;
      _contentCtrl.text = item.content;
      _meaningCtrl.text = item.meaning;
      _exampleCtrl.text = item.example;
      _videoCtrl.text = item.videoLink;
      _sourceCtrl.text = item.source;
      _type = item.type;
      _category = item.category;
      _ipaCtrl.text = item.ipa;
      _audioCtrl.text = item.audioUrl;
      _imageCtrl.text = item.imageUrl;
    }
  }

  @override
  void dispose() {
    _contentCtrl.dispose();
    _meaningCtrl.dispose();
    _exampleCtrl.dispose();
    _videoCtrl.dispose();
    _sourceCtrl.dispose();
    _customCategoryCtrl.dispose();
    _ipaCtrl.dispose();
    _audioCtrl.dispose();
    _imageCtrl.dispose();
    super.dispose();
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && data!.text!.trim().isNotEmpty) {
      _contentCtrl.text = data.text!.trim();
      final wordCount = data.text!.trim().split(' ').length;
      setState(() {
        if (wordCount == 1) _type = 'word';
        else if (wordCount <= 5) _type = 'phrase';
        else _type = 'sentence';
      });
    }
  }

  Future<void> _addCustomCategory() async {
    _customCategoryCtrl.clear();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add new topic'),
        content: TextField(
          controller: _customCategoryCtrl,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Topic name...'),
          textCapitalization: TextCapitalization.sentences,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () =>
                  Navigator.pop(ctx, _customCategoryCtrl.text.trim()),
              child: const Text('Add')),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      setState(() => _category = result);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final isEdit = widget.editItem != null;
    final item = isEdit
        ? widget.editItem!
        : VocabularyItem(
            id: const Uuid().v4(),
            content: _contentCtrl.text.trim(),
            createdAt: DateTime.now(),
          );

    item.content = _contentCtrl.text.trim();
    item.type = _type;
    item.category = _category;
    item.ipa = _type == 'word' ? _ipaCtrl.text.trim() : '';
    item.audioUrl = _audioCtrl.text.trim();
    item.imageUrl = _imageCtrl.text.trim();
    item.meaning = _meaningCtrl.text.trim();
    item.example = _exampleCtrl.text.trim();
    item.videoLink = _videoCtrl.text.trim();
    item.source = _sourceCtrl.text.trim();

    await StorageService.save(item);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.editItem != null;
    final allCategories = [
      ...kCategories,
      if (!kCategories.contains(_category) && _category != 'General')
        _category,
    ];

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(isEdit ? 'Edit' : 'Add Word'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (!isEdit)
              OutlinedButton.icon(
                onPressed: _pasteFromClipboard,
                icon: const Icon(Icons.content_paste),
                label: const Text('Paste from Clipboard'),
                style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12)),
              ),
            if (!isEdit) const SizedBox(height: 16),

            // Type selector
            const _Label('Type'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _types.map((t) {
                final selected = _type == t;
                return ChoiceChip(
                  label: Text(_typeLabels[t]!),
                  selected: selected,
                  onSelected: (_) => setState(() => _type = t),
                  selectedColor:
                      Theme.of(context).colorScheme.primaryContainer,
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Category selector
            const _Label('Topic'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                ...allCategories.map((c) => ChoiceChip(
                      label: Text(c),
                      selected: _category == c,
                      onSelected: (_) => setState(() => _category = c),
                      selectedColor: Colors.teal.shade100,
                      labelStyle: TextStyle(
                        color: _category == c
                            ? Colors.teal.shade800
                            : null,
                      ),
                    )),
                ActionChip(
                  label: const Text('+ Add topic'),
                  onPressed: _addCustomCategory,
                  backgroundColor: Colors.grey.shade100,
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (_type == 'word') ...[
              const _Label('IPA (pronunciation)'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _ipaCtrl,
                style: const TextStyle(fontSize: 15, letterSpacing: 0.5),
                decoration: InputDecoration(
                  hintText: '/ˈwɜːd/',
                  hintStyle:
                      TextStyle(color: Colors.grey.shade400, fontSize: 14),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey.shade300)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey.shade300)),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _showIpaPicker
                          ? Icons.keyboard_hide
                          : Icons.keyboard,
                      size: 20,
                      color: Colors.indigo.shade400,
                    ),
                    tooltip: 'IPA symbols',
                    onPressed: () =>
                        setState(() => _showIpaPicker = !_showIpaPicker),
                  ),
                ),
              ),
              if (_showIpaPicker) ...[
                const SizedBox(height: 6),
                _IpaPickerPanel(controller: _ipaCtrl),
              ],
              const SizedBox(height: 16),
            ],

            _Field(
              controller: _contentCtrl,
              label: 'Word / Phrase / Sentence *',
              hint: 'Enter or paste content to save',
              maxLines: 2,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),

            _Field(
              controller: _meaningCtrl,
              label: 'Meaning',
              hint: 'Meaning of the word/phrase...',
              maxLines: 3,
            ),
            const SizedBox(height: 12),

            _Field(
              controller: _exampleCtrl,
              label: 'Example',
              hint: 'Example sentence, context...',
              maxLines: 4,
            ),
            const SizedBox(height: 12),

            _Field(
              controller: _videoCtrl,
              label: 'Video Link (YouTube, etc.)',
              hint: 'https://youtube.com/...',
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 12),

            _Field(
              controller: _sourceCtrl,
              label: 'Source',
              hint: 'Document name, video, website...',
            ),
            const SizedBox(height: 12),

            _Field(
              controller: _audioCtrl,
              label: 'Audio URL',
              hint: 'https://dictionary.cambridge.org/...',
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 12),

            _Field(
              controller: _imageCtrl,
              label: 'Image URL',
              hint: 'https://example.com/image.jpg',
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 32),

            ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : Text(isEdit ? 'Update' : 'Save',
                      style: const TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13));
}

class _IpaPickerPanel extends StatelessWidget {
  final TextEditingController controller;
  const _IpaPickerPanel({required this.controller});

  static const _symbols = [
    'iː', 'ɪ', 'e', 'æ', 'ɑː', 'ɒ', 'ɔː', 'ʊ', 'uː', 'ʌ', 'ɜː', 'ə',
    'eɪ', 'aɪ', 'ɔɪ', 'əʊ', 'aʊ', 'ɪə', 'eə', 'ʊə',
    'θ', 'ð', 'ʃ', 'ʒ', 'ŋ', 'tʃ', 'dʒ',
    'ˈ', 'ˌ', 'ː', '/', '[', ']',
  ];

  void _insert(String symbol) {
    final text = controller.text;
    final sel = controller.selection;
    final start = sel.start < 0 ? text.length : sel.start;
    final end = sel.end < 0 ? text.length : sel.end;
    final newText = text.replaceRange(start, end, symbol);
    controller.value = controller.value.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: start + symbol.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.indigo.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.indigo.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tap a symbol to insert',
              style: TextStyle(fontSize: 11, color: Colors.indigo.shade400)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _symbols
                .map((s) => GestureDetector(
                      onTap: () => _insert(s),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.indigo.shade200),
                        ),
                        child: Text(s,
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.indigo.shade700)),
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final int maxLines;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _Field({
    required this.controller,
    required this.label,
    required this.hint,
    this.maxLines = 1,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Label(label),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300)),
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }
}
