import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/study_set_repository.dart';
import '../../data/services/auth_service.dart';
import '../../theme/app_theme.dart';

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
        const SnackBar(content: Text('A study set needs at least two terms.')),
      );
    }
  }

  Future<void> _save() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title is required.')),
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
            content: Text('Please provide at least two complete terms (term + definition).')),
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
          const SnackBar(content: Text('Study set created successfully!')),
        );
        context.pop(); // Pop this screen, `StudySetsScreen` will refresh
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating study set: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Study Set'),
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
                  child: const Text('Done',
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
                labelText: 'Title',
                hintText: 'e.g., Biology 101, French Vocabulary...',
              ),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descCtrl,
              maxLength: 250,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Terms',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold)),
                Text('${_terms.length} terms',
                    style: const TextStyle(color: AppTheme.textSecondaryColor)),
              ],
            ),
            const SizedBox(height: 16),
            // Terms List
            ..._terms.asMap().entries.map((entry) {
              final index = entry.key;
              final t = entry.value;
              return Card(
                elevation: 0,
                color: AppTheme.surfaceColor,
                margin: const EdgeInsets.only(bottom: 16),
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${index + 1}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 20),
                            onPressed: () => _removeTerm(index),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          )
                        ],
                      ),
                      const Divider(height: 24),
                      TextField(
                        controller: t.termCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Term',
                          border: UnderlineInputBorder(),
                          enabledBorder: UnderlineInputBorder(
                              borderSide:
                                  BorderSide(color: Colors.white24)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: t.defCtrl,
                        maxLines: null,
                        decoration: const InputDecoration(
                          labelText: 'Definition',
                          border: UnderlineInputBorder(),
                          enabledBorder: UnderlineInputBorder(
                              borderSide:
                                  BorderSide(color: Colors.white24)),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 16),
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
                label: const Text('Add Term',
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
