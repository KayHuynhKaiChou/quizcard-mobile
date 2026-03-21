import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:quizcard_mobile/data/repositories/ai_repository.dart';
import 'package:quizcard_mobile/data/services/auth_service.dart';
import 'package:quizcard_mobile/theme/app_theme.dart';

/// Screen for extracting term/definition pairs from pasted text using AI.
class AiExtractTextScreen extends StatefulWidget {
  /// Called when the user taps "Thêm vào bộ thẻ" with extracted terms.
  final void Function(List<Map<String, dynamic>> terms)? onTermsGenerated;

  const AiExtractTextScreen({super.key, this.onTermsGenerated});

  @override
  State<AiExtractTextScreen> createState() => _AiExtractTextScreenState();
}

class _AiExtractTextScreenState extends State<AiExtractTextScreen> {
  final _textCtrl = TextEditingController();
  bool _isLoading = false;
  List<Map<String, dynamic>> _results = [];
  String? _errorMessage;

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  Future<void> _extract() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập văn bản.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _results = [];
    });

    try {
      final repo = AiRepository(context.read<AuthService>());
      final terms = await repo.extractFromText(text: text);
      if (mounted) {
        setState(() => _results = terms);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _addToStudySet() {
    widget.onTermsGenerated?.call(_results);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trích xuất thuật ngữ từ văn bản'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Multiline text input
            TextField(
              controller: _textCtrl,
              minLines: 5,
              maxLines: 15,
              decoration: const InputDecoration(
                hintText: 'Dán văn bản vào đây...',
                alignLabelWithHint: true,
              ),
            ).animate().fadeIn(duration: 400.ms),
            const SizedBox(height: 10),

            // Hint text
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Icon(Icons.info_outline, size: 15, color: AppTheme.textSecondaryColor),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'AI sẽ tự động tìm và trích xuất thuật ngữ quan trọng từ văn bản',
                    style: TextStyle(
                      color: AppTheme.textSecondaryColor,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ).animate().fadeIn(delay: 100.ms),
            const SizedBox(height: 20),

            // Extract button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _extract,
                child: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.document_scanner_outlined, size: 18),
                          SizedBox(width: 8),
                          Text('Trích xuất'),
                        ],
                      ),
              ),
            ).animate().fadeIn(delay: 150.ms),

            // Error message
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.errorColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: AppTheme.errorColor, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: AppTheme.errorColor, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(),
            ],

            // Results list
            if (_results.isNotEmpty) ...[
              const SizedBox(height: 24),
              Row(
                children: [
                  const Icon(Icons.check_circle, color: AppTheme.successColor, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    '${_results.length} thuật ngữ được trích xuất',
                    style: const TextStyle(
                      color: AppTheme.successColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ).animate().fadeIn(),
              const SizedBox(height: 12),
              ..._results.asMap().entries.map((entry) {
                final idx = entry.key;
                final item = entry.value;
                return _TermResultCard(
                  index: idx + 1,
                  term: item['term']?.toString() ?? '',
                  definition: item['definition']?.toString() ?? '',
                ).animate().fadeIn(delay: (idx * 40).ms);
              }),
              const SizedBox(height: 16),

              // Add to study set button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: widget.onTermsGenerated != null ? _addToStudySet : null,
                  icon: const Icon(Icons.add),
                  label: const Text('Thêm vào bộ thẻ'),
                ),
              ).animate().fadeIn(delay: 200.ms),
              const SizedBox(height: 32),
            ],
          ],
        ),
      ),
    );
  }
}

/// Single term/definition result card.
class _TermResultCard extends StatelessWidget {
  final int index;
  final String term;
  final String definition;

  const _TermResultCard({
    required this.index,
    required this.term,
    required this.definition,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Index badge
            Container(
              width: 26,
              height: 26,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '$index',
                style: const TextStyle(
                  color: AppTheme.primaryColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    term,
                    style: const TextStyle(
                      color: AppTheme.textPrimaryColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    definition,
                    style: const TextStyle(
                      color: AppTheme.textSecondaryColor,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
