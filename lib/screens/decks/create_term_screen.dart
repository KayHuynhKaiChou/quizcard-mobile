import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../data/models/study_set_models.dart';
import '../../data/repositories/study_set_repository.dart';
import '../../theme/app_theme.dart';

class CreateTermScreen extends StatefulWidget {
  final String studySetId;
  final Term? term;

  const CreateTermScreen({
    super.key,
    required this.studySetId,
    this.term,
  });

  @override
  State<CreateTermScreen> createState() => _CreateTermScreenState();
}

class _CreateTermScreenState extends State<CreateTermScreen> {
  late final TextEditingController _termController;
  late final TextEditingController _definitionController;
  late final TextEditingController _exampleController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _termController = TextEditingController(text: widget.term?.term ?? '');
    _definitionController = TextEditingController(text: widget.term?.definition ?? '');
    _exampleController = TextEditingController(text: widget.term?.exampleSentence ?? '');
  }

  @override
  void dispose() {
    _termController.dispose();
    _definitionController.dispose();
    _exampleController.dispose();
    super.dispose();
  }

  Future<void> _saveTerm() async {
    final term = _termController.text.trim();
    final definition = _definitionController.text.trim();
    if (term.isEmpty || definition.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Term and definition are required')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final repo = context.read<StudySetRepository>();
      final example = _exampleController.text.trim();
      final exampleSentence = example.isNotEmpty ? example : null;

      if (widget.term == null) {
        // Create
        await repo.addTerm(
          widget.studySetId,
          term: term,
          definition: definition,
          exampleSentence: exampleSentence,
        );
      } else {
        // Update
        await repo.updateTerm(
          widget.term!.id,
          term: term,
          definition: definition,
          exampleSentence: exampleSentence,
        );
      }
      if (mounted) context.pop(true); // Return true to indicate success
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save term: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteTerm() async {
    if (widget.term == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Term'),
        content: const Text('Are you sure you want to delete this term?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      final repo = context.read<StudySetRepository>();
      await repo.deleteTerm(widget.term!.id);
      if (mounted) context.pop(true); // Return true to indicate success
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete term: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.term != null;
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: Text(isEditing ? 'Edit Term' : 'Thêm thuật ngữ'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Term Name
                        const Text('Thuật ngữ', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: AppTheme.textSecondaryColor)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _termController,
                          decoration: const InputDecoration(
                            hintText: 'Nhập thuật ngữ',
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Definition
                        const Text('Định nghĩa', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: AppTheme.textSecondaryColor)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _definitionController,
                          minLines: 4, maxLines: 6,
                          decoration: const InputDecoration(hintText: 'Nhập định nghĩa'),
                        ),
                        const SizedBox(height: 20),

                        // Example Sentence
                        Row(children: [
                          const Text('Ví dụ', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: AppTheme.textSecondaryColor)),
                          const SizedBox(width: 6),
                          Text('(Tùy chọn)', style: TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor.withValues(alpha: 0.7))),
                        ]),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _exampleController,
                          minLines: 3, maxLines: 5,
                          decoration: const InputDecoration(hintText: 'Nhập câu ví dụ'),
                        ),
                        const SizedBox(height: 20),

                        // Upload Image
                        InkWell(
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Image upload coming soon')));
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.15), style: BorderStyle.solid, width: 1.5),
                              color: AppTheme.surfaceColor,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 40, height: 40,
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryColor.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.image_outlined, color: AppTheme.primaryColor),
                                ),
                                const SizedBox(width: 16),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Tải ảnh lên', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                                      SizedBox(height: 2),
                                      Text('PNG, JPG lên đến 5MB', style: TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor)),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right, color: AppTheme.textSecondaryColor),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Delete
                        if (isEditing)
                          SizedBox(
                            width: double.infinity,
                            child: TextButton.icon(
                              onPressed: _deleteTerm,
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              label: const Text('Xóa thuật ngữ', style: TextStyle(color: Colors.red)),
                              style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                            ),
                          ),
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ),
                // Sticky Save Button
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundColor,
                    border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _saveTerm,
                      icon: const Icon(Icons.save_outlined),
                      label: Text(isEditing ? 'Lưu thay đổi' : 'Tạo thuật ngữ', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
