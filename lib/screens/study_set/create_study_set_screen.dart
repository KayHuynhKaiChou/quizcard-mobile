import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/study_set_repository.dart';
import '../../data/services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../ai/ai_generate_terms_screen.dart';
import '../ai/ai_extract_text_screen.dart';

class _TermData {
  TextEditingController termCtrl = TextEditingController();
  TextEditingController defCtrl = TextEditingController();

  void dispose() {
    termCtrl.dispose();
    defCtrl.dispose();
  }
}

class CreateStudySetScreen extends StatefulWidget {
  const CreateStudySetScreen({super.key});

  @override
  State<CreateStudySetScreen> createState() => _CreateStudySetScreenState();
}

class _CreateStudySetScreenState extends State<CreateStudySetScreen> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final List<_TermData> _terms = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Start with 2 empty terms
    _terms.add(_TermData());
    _terms.add(_TermData());
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    for (var t in _terms) {
      t.dispose();
    }
    super.dispose();
  }

  void _addTerm() {
    setState(() {
      _terms.add(_TermData());
    });
  }

  void _removeTerm(int index) {
    if (_terms.length > 2) {
      setState(() {
        final removed = _terms.removeAt(index);
        removed.dispose();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Một bộ thẻ cần có ít nhất hai thuật ngữ.')),
      );
    }
  }

  /// Adds AI-generated/extracted terms to the terms list.
  void _addTermsFromAi(List<Map<String, dynamic>> aiTerms) {
    if (aiTerms.isEmpty) return;
    setState(() {
      for (final item in aiTerms) {
        final td = _TermData();
        td.termCtrl.text = item['term']?.toString() ?? '';
        td.defCtrl.text = item['definition']?.toString() ?? '';
        _terms.add(td);
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Đã thêm ${aiTerms.length} thuật ngữ từ AI.')),
    );
  }

  Future<void> _save() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập tiêu đề.')),
      );
      return;
    }

    final validTerms = <Map<String, dynamic>>[];
    for (var t in _terms) {
      final termText = t.termCtrl.text.trim();
      final defText = t.defCtrl.text.trim();
      if (termText.isNotEmpty && defText.isNotEmpty) {
        validTerms.add({'term': termText, 'definition': defText});
      }
    }

    if (validTerms.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Vui lòng nhập ít nhất hai thẻ hoàn chỉnh (thuật ngữ + định nghĩa).')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final repo = StudySetRepository(context.read<AuthService>());
      final newSet = await repo.create(
        title: title,
        description: _descCtrl.text.trim(),
        terms: validTerms,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tạo bộ thẻ thành công!')),
        );
        context.pop(); // Pop this screen, `StudySetsScreen` will refresh
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi tạo bộ thẻ: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Widget _buildQuizletInput({
    required TextEditingController controller,
    required String labelText,
    Widget? trailingLabel,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          maxLines: null,
          style: const TextStyle(fontSize: 18, color: Colors.white),
          decoration: const InputDecoration(
            filled: false,
            fillColor: Colors.transparent,
            isDense: true,
            contentPadding: EdgeInsets.symmetric(vertical: 8),
            border: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white, width: 2),
            ),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white, width: 2),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white, width: 3),
            ),
            // Override margins forced by appTheme
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              labelText,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white70),
            ),
            if (trailingLabel != null) trailingLabel,
          ],
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tạo bộ thẻ mới'),
        actions: [
          _isSaving
              ? const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2)),
                )
              : TextButton(
                  onPressed: _save,
                  child: const Text('Hoàn tất',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title & Desc
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Tiêu đề',
                hintText: 'Nhập tiêu đề bộ thẻ...',
              ),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descCtrl,
              maxLength: 250,
              decoration: const InputDecoration(
                labelText: 'Mô tả',
                hintText: 'Thêm mô tả cho bộ thẻ...',
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Thuật ngữ',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold)),
                Text('${_terms.length} thuật ngữ',
                    style: const TextStyle(color: AppTheme.textSecondaryColor)),
              ],
            ),
            const SizedBox(height: 16),
            // Terms List
            ..._terms.asMap().entries.map((entry) {
              final index = entry.key;
              final t = entry.value;
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                child: Slidable(
                  key: ObjectKey(t),
                  endActionPane: ActionPane(
                    motion: const ScrollMotion(),
                    extentRatio: 0.2,
                    children: [
                      CustomSlidableAction(
                        onPressed: (_) {
                          if (_terms.length > 2) {
                            _removeTerm(index);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Một bộ thẻ cần có ít nhất hai thuật ngữ.')),
                            );
                          }
                        },
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.redAccent,
                        child: const Icon(Icons.delete, size: 28),
                      ),
                    ],
                  ),
                  child: Card(
                    elevation: 0,
                    color: AppTheme.surfaceColor,
                    margin: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildQuizletInput(
                            controller: t.termCtrl,
                            labelText: 'Thuật ngữ',
                          ),
                          const SizedBox(height: 24),
                          _buildQuizletInput(
                            controller: t.defCtrl,
                            labelText: 'Nghĩa / Định nghĩa',
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 16),
            // AI helper buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => AiGenerateTermsScreen(
                            onTermsGenerated: _addTermsFromAi,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.auto_awesome, size: 16),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    label: const Text('Tạo bằng AI'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => AiExtractTextScreen(
                            onTermsGenerated: _addTermsFromAi,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.article_outlined, size: 16),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    label: const Text('Trích từ văn bản'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton.icon(
                onPressed: _addTerm,
                icon: const Icon(Icons.add),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  side: const BorderSide(color: AppTheme.primaryColor),
                ),
                label: const Text('Thêm thuật ngữ',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}
