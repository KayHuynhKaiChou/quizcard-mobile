import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../data/models/quiz_models.dart';
import '../../data/models/page_response.dart';
import '../../data/repositories/quiz_repository.dart';
import '../../data/services/auth_service.dart';
import '../../theme/app_theme.dart';

class QuizHistoryScreen extends StatefulWidget {
  const QuizHistoryScreen({super.key});

  @override
  State<QuizHistoryScreen> createState() => _QuizHistoryScreenState();
}

class _QuizHistoryScreenState extends State<QuizHistoryScreen> {
  late QuizRepository _repo;
  late Future<PageResponse<QuizResult>> _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _repo = QuizRepository(context.read<AuthService>());
    _future = _repo.getHistory();
  }

  void _refresh() => setState(() => _future = _repo.getHistory());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quiz History')),
      body: FutureBuilder<PageResponse<QuizResult>>(
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
                  const Icon(Icons.cloud_off_outlined,
                      color: AppTheme.textSecondaryColor, size: 48),
                  const SizedBox(height: 12),
                  const Text('Failed to load quiz history'),
                  const SizedBox(height: 12),
                  ElevatedButton(
                      onPressed: _refresh, child: const Text('Retry')),
                ],
              ),
            );
          }

          final items = snapshot.data?.content ?? [];
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.quiz_outlined,
                      color: AppTheme.textSecondaryColor.withValues(alpha: 0.5),
                      size: 64),
                  const SizedBox(height: 16),
                  Text('No quiz results yet',
                      style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final result = items[index];
              return _QuizResultCard(result: result)
                  .animate(delay: Duration(milliseconds: 50 * index))
                  .fadeIn()
                  .slideY(begin: 0.03);
            },
          );
        },
      ),
    );
  }
}

class _QuizResultCard extends StatelessWidget {
  final QuizResult result;
  const _QuizResultCard({required this.result});

  Color get _scoreColor {
    if (result.score >= 80) return AppTheme.successColor;
    if (result.score >= 50) return const Color(0xFFF59E0B);
    return AppTheme.errorColor;
  }

  @override
  Widget build(BuildContext context) {
    final mins = result.timeSpentSeconds ~/ 60;
    final secs = result.timeSpentSeconds % 60;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => context.go('/quiz-history/${result.id}'),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Score circle
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: _scoreColor, width: 3),
                ),
                child: Center(
                  child: Text('${result.score.round()}%',
                      style: TextStyle(
                          color: _scoreColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 14)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(result.studySetTitle,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text(
                      '${result.correctAnswers}/${result.totalQuestions} correct • ${mins}m ${secs}s',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatDate(result.createdAt),
                      style: const TextStyle(
                          color: AppTheme.textSecondaryColor, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right,
                  color: AppTheme.textSecondaryColor),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
