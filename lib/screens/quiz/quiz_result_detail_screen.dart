import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../data/models/quiz_models.dart';
import '../../data/repositories/quiz_repository.dart';
import '../../data/services/auth_service.dart';
import '../../theme/app_theme.dart';

class QuizResultDetailScreen extends StatefulWidget {
  final String resultId;
  const QuizResultDetailScreen({super.key, required this.resultId});

  @override
  State<QuizResultDetailScreen> createState() => _QuizResultDetailScreenState();
}

class _QuizResultDetailScreenState extends State<QuizResultDetailScreen> {
  late Future<QuizResultDetail> _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final repo = QuizRepository(context.read<AuthService>());
    _future = repo.getResultDetail(widget.resultId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quiz Result')),
      body: FutureBuilder<QuizResultDetail>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline,
                      color: AppTheme.errorColor, size: 48),
                  const SizedBox(height: 12),
                  const Text('Failed to load result'),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => context.pop(),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            );
          }

          final result = snapshot.data!;
          return _buildContent(context, result);
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, QuizResultDetail result) {
    final scoreColor = result.score >= 80
        ? AppTheme.successColor
        : result.score >= 50
            ? const Color(0xFFF59E0B)
            : AppTheme.errorColor;
    final mins = result.timeSpentSeconds ~/ 60;
    final secs = result.timeSpentSeconds % 60;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Score circle
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: scoreColor, width: 6),
            ),
            child: Center(
              child: Text('${result.score.round()}%',
                  style: TextStyle(
                      color: scoreColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 32)),
            ),
          ).animate().fadeIn().scale(begin: const Offset(0.8, 0.8)),
          const SizedBox(height: 8),
          Text(result.studySetTitle,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),

          // Stats row
          Row(
            children: [
              _StatChip(
                  label: 'Time',
                  value: '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}',
                  icon: Icons.timer_outlined),
              _StatChip(
                  label: 'Correct',
                  value: '${result.correctAnswers}',
                  icon: Icons.check_circle_outline,
                  color: AppTheme.successColor),
              _StatChip(
                  label: 'Wrong',
                  value: '${result.totalQuestions - result.correctAnswers}',
                  icon: Icons.cancel_outlined,
                  color: AppTheme.errorColor),
            ],
          ).animate().fadeIn(delay: 100.ms),
          const SizedBox(height: 24),

          // Question Breakdown
          Align(
            alignment: Alignment.centerLeft,
            child: Text('Question Breakdown',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 12),

          ...result.details.asMap().entries.map((entry) {
            final i = entry.key;
            final detail = entry.value;
            return _QuestionCard(index: i + 1, detail: detail)
                .animate(delay: Duration(milliseconds: 60 * i))
                .fadeIn()
                .slideY(begin: 0.02);
          }),
          const SizedBox(height: 16),

          // Retake button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.refresh),
              label: const Text('Retake Quiz'),
            ),
          ).animate().fadeIn(delay: 300.ms),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatChip({
    required this.label,
    required this.value,
    required this.icon,
    this.color = AppTheme.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(value,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text(label,
                style: const TextStyle(
                    color: AppTheme.textSecondaryColor, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  final int index;
  final QuestionDetail detail;

  const _QuestionCard({required this.index, required this.detail});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: detail.isCorrect
                    ? AppTheme.successColor.withValues(alpha: 0.15)
                    : AppTheme.errorColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                detail.isCorrect ? Icons.check : Icons.close,
                color: detail.isCorrect
                    ? AppTheme.successColor
                    : AppTheme.errorColor,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Q$index: ${detail.questionText}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Text('Your answer: ',
                          style: TextStyle(
                              color: AppTheme.textSecondaryColor,
                              fontSize: 12)),
                      Flexible(
                        child: Text(detail.userAnswer,
                            style: TextStyle(
                                color: detail.isCorrect
                                    ? AppTheme.successColor
                                    : AppTheme.errorColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                  if (!detail.isCorrect) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Text('Correct: ',
                            style: TextStyle(
                                color: AppTheme.textSecondaryColor,
                                fontSize: 12)),
                        Flexible(
                          child: Text(detail.correctAnswer,
                              style: const TextStyle(
                                  color: AppTheme.successColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
