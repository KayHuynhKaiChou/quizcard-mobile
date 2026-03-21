import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:quizcard_mobile/data/repositories/ai_repository.dart';
import 'package:quizcard_mobile/data/services/auth_service.dart';
import 'package:quizcard_mobile/theme/app_theme.dart';

/// Screen that allows the user to generate flashcard terms via AI given a topic.
class AiGenerateTermsScreen extends StatefulWidget {
  /// Called when the user taps "Thêm vào bộ thẻ" with the generated list.
  final void Function(List<Map<String, dynamic>> terms)? onTermsGenerated;

  const AiGenerateTermsScreen({super.key, this.onTermsGenerated});

  @override
  State<AiGenerateTermsScreen> createState() => _AiGenerateTermsScreenState();
}

class _AiGenerateTermsScreenState extends State<AiGenerateTermsScreen> {
  final _topicCtrl = TextEditingController();
  double _termCount = 20;
  bool _isLoading = false;
  List<Map<String, dynamic>> _results = [];
  String? _errorMessage;

  @override
  void dispose() {
    _topicCtrl.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    final topic = _topicCtrl.text.trim();
    if (topic.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập chủ đề.')),
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
      final terms = await repo.generateTerms(
        topic: topic,
        count: _termCount.toInt(),
      );
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
        title: const Column(
          children: [
            Text('Tạo thuật ngữ bằng AI'),
            Text(
              'Nhập chủ đề, AI sẽ tạo các thuật ngữ',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondaryColor,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Topic input
            TextField(
              controller: _topicCtrl,
              decoration: const InputDecoration(
                labelText: 'Chủ đề',
                hintText: 'VD: Lịch sử Việt Nam, Toán đại số...',
                prefixIcon: Icon(Icons.auto_awesome, color: AppTheme.primaryColor),
              ),
            ).animate().fadeIn(duration: 400.ms),
            const SizedBox(height: 24),

            // Term count slider
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Số lượng thuật ngữ',
                  style: TextStyle(
                    color: AppTheme.textPrimaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${_termCount.toInt()}',
                    style: const TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ).animate().fadeIn(delay: 100.ms),
            Slider(
              value: _termCount,
              min: 5,
              max: 50,
              divisions: 9, // steps of 5
              activeColor: AppTheme.primaryColor,
              inactiveColor: AppTheme.surfaceColor,
              onChanged: (val) => setState(() => _termCount = val),
            ).animate().fadeIn(delay: 150.ms),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text('5', style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 12)),
                Text('50', style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 24),

            // Generate button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _generate,
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
                          Icon(Icons.auto_awesome, size: 18),
                          SizedBox(width: 8),
                          Text('Tạo với AI'),
                        ],
                      ),
              ),
            ).animate().fadeIn(delay: 200.ms),

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
                    '${_results.length} thuật ngữ đã được tạo',
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
