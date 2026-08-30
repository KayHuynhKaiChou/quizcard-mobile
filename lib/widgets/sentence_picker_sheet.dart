import 'package:flutter/material.dart';

import '../data/models/sentence_models.dart';
import '../theme/app_theme.dart';

/// Opens the example-sentence picker for [term].
///
/// [cached] is the caller's per-screen cache: when non-null the sheet renders
/// immediately without hitting the API. [onGenerated] hands freshly generated
/// sentences back so the caller can cache them.
///
/// Returns `true` when the user saved at least one sentence.
Future<bool?> showSentencePickerSheet({
  required BuildContext context,
  required String termLabel,
  required List<AiSentence>? cached,
  required Future<List<AiSentence>> Function() onGenerate,
  required Future<void> Function(List<AiSentence>) onSave,
  required void Function(List<AiSentence>) onGenerated,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppTheme.surfaceColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _SentencePickerSheet(
      termLabel: termLabel,
      cached: cached,
      onGenerate: onGenerate,
      onSave: onSave,
      onGenerated: onGenerated,
    ),
  );
}

class _SentencePickerSheet extends StatefulWidget {
  final String termLabel;
  final List<AiSentence>? cached;
  final Future<List<AiSentence>> Function() onGenerate;
  final Future<void> Function(List<AiSentence>) onSave;
  final void Function(List<AiSentence>) onGenerated;

  const _SentencePickerSheet({
    required this.termLabel,
    required this.cached,
    required this.onGenerate,
    required this.onSave,
    required this.onGenerated,
  });

  @override
  State<_SentencePickerSheet> createState() => _SentencePickerSheetState();
}

class _SentencePickerSheetState extends State<_SentencePickerSheet> {
  List<AiSentence>? _sentences;
  final Set<int> _selected = {};
  bool _isLoading = false;
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _sentences = widget.cached;
    if (_sentences == null) _generate();
  }

  Future<void> _generate() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _selected.clear();
    });
    try {
      final list = await widget.onGenerate();
      widget.onGenerated(list);
      if (!mounted) return;
      setState(() {
        _sentences = list;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Không tạo được câu ví dụ. Vui lòng thử lại.';
      });
    }
  }

  bool get _allSelected {
    final list = _sentences;
    return list != null && list.isNotEmpty && _selected.length == list.length;
  }

  void _toggle(int index) {
    setState(() {
      if (!_selected.remove(index)) _selected.add(index);
    });
  }

  void _toggleAll() {
    final list = _sentences;
    if (list == null) return;
    setState(() {
      if (_allSelected) {
        _selected.clear();
      } else {
        _selected
          ..clear()
          ..addAll(List.generate(list.length, (i) => i));
      }
    });
  }

  Future<void> _save() async {
    final list = _sentences;
    if (list == null || _selected.isEmpty) return;

    setState(() => _isSaving = true);
    try {
      final picked = [
        for (var i = 0; i < list.length; i++)
          if (_selected.contains(i)) list[i],
      ];
      await widget.onSave(picked);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _error = 'Không lưu được câu. Vui lòng thử lại.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildGrabHandle(),
            _buildHeader(),
            const Divider(height: 1, color: Colors.white24),
            Expanded(child: _buildBody(scrollController)),
            _buildFooter(),
          ],
        );
      },
    );
  }

  Widget _buildGrabHandle() => Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(2),
        ),
      );

  Widget _buildHeader() => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.chat_bubble_outline,
                    color: AppTheme.primaryColor, size: 20),
                SizedBox(width: 8),
                Text('Câu ví dụ',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              widget.termLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: AppTheme.textSecondaryColor, fontSize: 13),
            ),
          ],
        ),
      );

  Widget _buildBody(ScrollController scrollController) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 14),
            Text('Đang tạo câu ví dụ...',
                style: TextStyle(color: AppTheme.textSecondaryColor)),
          ],
        ),
      );
    }

    final list = _sentences;
    if (list == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_outlined,
                color: AppTheme.textSecondaryColor, size: 44),
            const SizedBox(height: 12),
            Text(_error ?? 'Không tạo được câu ví dụ',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.textSecondaryColor)),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              onPressed: _generate,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        _buildSelectBar(list.length),
        Expanded(
          child: ListView.separated(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) =>
                _buildSentenceTile(list[index], index),
          ),
        ),
      ],
    );
  }

  Widget _buildSelectBar(int total) => Padding(
        padding: const EdgeInsets.fromLTRB(8, 4, 20, 0),
        child: Row(
          children: [
            Checkbox(
              value: _allSelected,
              onChanged: (_) => _toggleAll(),
            ),
            const Text('Chọn tất cả',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            const Spacer(),
            Text('Đã chọn ${_selected.length}/$total',
                style: const TextStyle(
                    color: AppTheme.textSecondaryColor, fontSize: 13)),
          ],
        ),
      );

  Widget _buildSentenceTile(AiSentence s, int index) {
    final isSelected = _selected.contains(index);

    return InkWell(
      onTap: () => _toggle(index),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.fromLTRB(4, 10, 12, 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor.withValues(alpha: 0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryColor.withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: isSelected,
              onChanged: (_) => _toggle(index),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.sentence,
                      style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          height: 1.35)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _WordChip(word: s.word),
                      if (s.translation != null)
                        Text(s.translation!,
                            style: const TextStyle(
                                color: AppTheme.textSecondaryColor,
                                fontSize: 13,
                                height: 1.35)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Colors.white24)),
        ),
        child: Row(
          children: [
            TextButton.icon(
              onPressed: (_isLoading || _isSaving) ? null : _generate,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Tạo lại'),
            ),
            const Spacer(),
            TextButton(
              onPressed:
                  _isSaving ? null : () => Navigator.of(context).pop(false),
              child: const Text('Hủy'),
            ),
            const SizedBox(width: 6),
            FilledButton.icon(
              onPressed:
                  (_selected.isEmpty || _isSaving) ? null : _save,
              icon: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check, size: 18),
              label: Text('Lưu (${_selected.length})'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Marks which vocabulary word a sentence belongs to — matters when one card
/// holds several words separated by " - ".
class _WordChip extends StatelessWidget {
  final String word;

  const _WordChip({required this.word});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        word,
        style: const TextStyle(
          color: AppTheme.primaryColor,
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
