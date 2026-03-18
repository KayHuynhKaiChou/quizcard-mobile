import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../data/models/quiz_models.dart';
import '../../data/repositories/quiz_repository.dart';
import '../../data/services/auth_service.dart';
import '../../theme/app_theme.dart';

// ── Local result model (passed to QuizResultsScreen via extra) ──────────────

class LocalQuizResult {
  final int score;
  final int total;
  final int timeTakenSeconds;
  final List<WrongAnswer> wrongAnswers;
  final String studySetId;

  LocalQuizResult({
    required this.score,
    required this.total,
    required this.timeTakenSeconds,
    required this.wrongAnswers,
    required this.studySetId,
  });

  double get percentage => total == 0 ? 0 : (score / total) * 100;
}

class WrongAnswer {
  final String term;
  final String userAnswer;
  final String correctAnswer;
  WrongAnswer({required this.term, required this.userAnswer, required this.correctAnswer});
}

// ── Main Screen ─────────────────────────────────────────────────────────────

class QuizChallengeScreen extends StatefulWidget {
  final String studySetId;
  const QuizChallengeScreen({super.key, required this.studySetId});

  @override
  State<QuizChallengeScreen> createState() => _QuizChallengeScreenState();
}

class _QuizChallengeScreenState extends State<QuizChallengeScreen> {
  // ── State machine: setup | loading | quiz | submitting
  String _phase = 'setup';

  // Setup options
  String _quizType = 'MULTIPLE_CHOICE';
  int _questionCount = 10;

  // Quiz data
  GeneratedQuiz? _quiz;
  int _currentIndex = 0;
  String? _selectedAnswer;
  String _fillBlankAnswer = '';
  bool _isAnswered = false;
  int _correctCount = 0;
  final List<WrongAnswer> _wrongAnswers = [];
  final List<QuizAnswer> _allAnswers = [];

  // Timer
  Timer? _timer;
  int _timeLeft = 20;
  int _quizStartTimestamp = 0;

  String? _error;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  int get _timerMax => _quizType == 'FILL_BLANK' ? 30 : 20;

  // ── API calls ──────────────────────────────────────────────────────────

  Future<void> _startQuiz() async {
    setState(() { _phase = 'loading'; _error = null; });
    try {
      final repo = QuizRepository(context.read<AuthService>());
      final config = QuizConfig(
        studySetId: widget.studySetId,
        quizType: _quizType,
        questionCount: _questionCount,
      );
      final quiz = await repo.generateQuiz(config);
      setState(() {
        _quiz = quiz;
        _phase = 'quiz';
        _currentIndex = 0;
        _quizStartTimestamp = DateTime.now().millisecondsSinceEpoch;
      });
      _startTimer();
    } catch (e) {
      setState(() { _phase = 'setup'; _error = e.toString(); });
    }
  }

  Future<void> _finishQuiz() async {
    _timer?.cancel();
    final timeTaken = (DateTime.now().millisecondsSinceEpoch - _quizStartTimestamp) ~/ 1000;
    setState(() => _phase = 'submitting');

    try {
      final repo = QuizRepository(context.read<AuthService>());
      await repo.submitQuiz(QuizSubmission(
        quizId: _quiz!.quizId,
        answers: _allAnswers,
        timeSpentSeconds: timeTaken,
      ));
    } catch (_) {
      // Silently fail submit — still show results
    }

    final result = LocalQuizResult(
      score: _correctCount,
      total: _quiz!.questions.length,
      timeTakenSeconds: timeTaken,
      wrongAnswers: _wrongAnswers,
      studySetId: widget.studySetId,
    );

    if (mounted) {
      context.go('/quiz_results', extra: result);
    }
  }

  // ── Timer ──────────────────────────────────────────────────────────────

  void _startTimer() {
    _timer?.cancel();
    setState(() => _timeLeft = _timerMax);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_timeLeft > 0) {
        setState(() => _timeLeft--);
      } else {
        _handleTimeout();
      }
    });
  }

  void _handleTimeout() {
    if (_isAnswered) return;
    final q = _quiz!.questions[_currentIndex];
    _recordAnswer(q, '', isTimeout: true);
  }

  // ── Answer logic ───────────────────────────────────────────────────────

  void _selectAnswer(String answer) {
    if (_isAnswered) return;
    setState(() => _selectedAnswer = answer);
  }

  void _submitAnswer() {
    if (_isAnswered) return;
    final q = _quiz!.questions[_currentIndex];
    final answer = q.type == 'FILL_BLANK'
        ? _fillBlankAnswer.trim()
        : (_selectedAnswer ?? '');
    if (answer.isEmpty) return;
    _recordAnswer(q, answer);
  }

  void _recordAnswer(QuizQuestion q, String userAnswer, {bool isTimeout = false}) {
    _timer?.cancel();
    setState(() => _isAnswered = true);

    final isCorrect = q.type == 'FILL_BLANK'
        ? _fuzzyMatch(userAnswer, q.correctAnswer)
        : userAnswer == q.correctAnswer;

    _allAnswers.add(QuizAnswer(questionId: q.id, selectedAnswer: userAnswer));

    if (isCorrect) {
      _correctCount++;
    } else {
      _wrongAnswers.add(WrongAnswer(
        term: q.questionText,
        userAnswer: isTimeout ? '(Time out)' : (userAnswer.isEmpty ? '(Skipped)' : userAnswer),
        correctAnswer: q.correctAnswer,
      ));
    }

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      if (_currentIndex < _quiz!.questions.length - 1) {
        setState(() {
          _currentIndex++;
          _selectedAnswer = null;
          _fillBlankAnswer = '';
          _isAnswered = false;
        });
        _startTimer();
      } else {
        _finishQuiz();
      }
    });
  }

  bool _fuzzyMatch(String input, String correct) {
    normalize(String s) => s.toLowerCase().trim();
    return normalize(input) == normalize(correct);
  }

  // ── Builds ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.canPop() ? context.pop() : context.go('/home'),
        ),
        title: const Text('Quiz Challenge'),
      ),
      body: switch (_phase) {
        'setup'      => _buildSetup(),
        'loading'    => const Center(child: CircularProgressIndicator()),
        'submitting' => const Center(child: CircularProgressIndicator()),
        'quiz'       => _buildQuiz(),
        _            => _buildSetup(),
      },
    );
  }

  // ── Setup phase ────────────────────────────────────────────────────────

  Widget _buildSetup() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_error != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.errorColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(children: [
                const Icon(Icons.error_outline, color: AppTheme.errorColor, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(_error!, style: const TextStyle(color: AppTheme.errorColor, fontSize: 13))),
              ]),
            ),
            const SizedBox(height: 16),
          ],

          Text('Quiz Type', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),

          ...[
            ('MULTIPLE_CHOICE', 'Multiple Choice', Icons.list_outlined),
            ('TRUE_FALSE',      'True / False',    Icons.check_circle_outline),
            ('FILL_BLANK',      'Fill in the Blank', Icons.edit_outlined),
          ].map((tp) {
            final isSelected = _quizType == tp.$1;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GestureDetector(
                onTap: () => setState(() => _quizType = tp.$1),
                child: AnimatedContainer(
                  duration: 200.ms,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.primaryColor.withValues(alpha: 0.12) : AppTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppTheme.primaryColor : Colors.white.withValues(alpha: 0.08),
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(children: [
                    Icon(tp.$3, size: 20, color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondaryColor),
                    const SizedBox(width: 12),
                    Text(tp.$2, style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? AppTheme.primaryColor : AppTheme.textPrimaryColor,
                    )),
                    const Spacer(),
                    if (isSelected) const Icon(Icons.check_circle, color: AppTheme.primaryColor, size: 18),
                  ]),
                ),
              ).animate().fadeIn(delay: Duration(milliseconds: 60 * ['MULTIPLE_CHOICE', 'TRUE_FALSE', 'FILL_BLANK'].indexOf(tp.$1))),
            );
          }),

          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Questions', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('$_questionCount', style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ],
          ),
          Slider(
            value: _questionCount.toDouble(),
            min: 1, max: 20,
            divisions: 19,
            activeColor: AppTheme.primaryColor,
            onChanged: (v) => setState(() => _questionCount = v.round()),
          ),
          Text(
            'Up to 20 questions. Actual count depends on how many terms the study set has.',
            style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 12),
          ),

          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _startQuiz,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Start Quiz', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
            ),
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.05),
        ],
      ),
    );
  }

  // ── Quiz phase ─────────────────────────────────────────────────────────

  Widget _buildQuiz() {
    final quiz = _quiz!;
    if (quiz.questions.isEmpty) {
      return const Center(child: Text('No questions available.'));
    }
    final q = quiz.questions[_currentIndex];
    final progress = (_currentIndex + 1) / quiz.questions.length;
    final timerProgress = _timeLeft / _timerMax;
    final timerColor = timerProgress > 0.5
        ? AppTheme.primaryColor
        : timerProgress > 0.25
            ? const Color(0xFFF59E0B)
            : AppTheme.errorColor;

    return Column(
      children: [
        // Progress + timer
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Column(children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Question ${_currentIndex + 1} of ${quiz.questions.length}',
                    style: const TextStyle(fontWeight: FontWeight.w500)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: timerColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(children: [
                    Icon(Icons.timer_outlined, size: 14, color: timerColor),
                    const SizedBox(width: 4),
                    Text('${_timeLeft}s', style: TextStyle(color: timerColor, fontWeight: FontWeight.bold, fontSize: 13)),
                  ]),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.white.withValues(alpha: 0.1),
                valueColor: const AlwaysStoppedAnimation(AppTheme.primaryColor),
                minHeight: 6,
              ),
            ),
          ]),
        ),
        const SizedBox(height: 4),
        // Timer progress bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: timerProgress,
              backgroundColor: Colors.white.withValues(alpha: 0.05),
              valueColor: AlwaysStoppedAnimation(timerColor),
              minHeight: 3,
            ),
          ),
        ),

        // Question text
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
            child: Column(
              children: [
                // Question
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  child: Text(
                    q.questionText,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold, height: 1.4,
                    ),
                  ),
                ).animate(key: ValueKey('q_$_currentIndex')).fadeIn(duration: 180.ms),
                const SizedBox(height: 20),

                // Answers
                Expanded(
                  child: q.type == 'FILL_BLANK'
                      ? _buildFillBlank()
                      : _buildChoices(q),
                ),
              ],
            ),
          ),
        ),

        // Bottom bar
        _buildBottomBar(q),
      ],
    );
  }

  Widget _buildChoices(QuizQuestion q) {
    return ListView(
      children: q.options.asMap().entries.map((entry) {
        final option = entry.value;
        final isSelected = _selectedAnswer == option;
        final isCorrect = _isAnswered && option == q.correctAnswer;
        final isWrong = _isAnswered && isSelected && option != q.correctAnswer;

        Color borderColor = Colors.white.withValues(alpha: 0.08);
        Color bgColor = AppTheme.surfaceColor;
        if (isCorrect) { bgColor = AppTheme.successColor.withValues(alpha: 0.12); borderColor = AppTheme.successColor; }
        else if (isWrong) { bgColor = AppTheme.errorColor.withValues(alpha: 0.12); borderColor = AppTheme.errorColor; }
        else if (isSelected) { bgColor = AppTheme.primaryColor.withValues(alpha: 0.10); borderColor = AppTheme.primaryColor; }

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: GestureDetector(
            onTap: () => _selectAnswer(option),
            child: AnimatedContainer(
              duration: 200.ms,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor, width: isCorrect || isWrong ? 1.5 : 1),
              ),
              child: Row(children: [
                Expanded(child: Text(option, style: TextStyle(
                  fontWeight: isSelected || isCorrect ? FontWeight.bold : FontWeight.normal,
                ))),
                if (isCorrect) const Icon(Icons.check_circle, color: AppTheme.successColor, size: 18),
                if (isWrong)   const Icon(Icons.cancel, color: AppTheme.errorColor, size: 18),
              ]),
            ),
          ).animate(key: ValueKey('opt_${_currentIndex}_${entry.key}')).fadeIn(delay: Duration(milliseconds: 50 * entry.key)).slideY(begin: 0.04, end: 0),
        );
      }).toList(),
    );
  }

  Widget _buildFillBlank() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Type your answer:', style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 13)),
        const SizedBox(height: 8),
        TextField(
          enabled: !_isAnswered,
          onChanged: (v) => _fillBlankAnswer = v,
          onSubmitted: (_) => _submitAnswer(),
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Enter the term...'),
        ),
      ],
    );
  }

  Widget _buildBottomBar(QuizQuestion q) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
      ),
      child: Row(children: [
        if (q.type == 'TRUE_FALSE') ...[
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _isAnswered ? null : () { setState(() => _selectedAnswer = 'false'); _submitAnswer(); },
              icon: const Icon(Icons.close, color: AppTheme.errorColor),
              label: const Text('False', style: TextStyle(color: AppTheme.errorColor)),
              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: AppTheme.errorColor)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _isAnswered ? null : () { setState(() => _selectedAnswer = 'true'); _submitAnswer(); },
              icon: const Icon(Icons.check),
              label: const Text('True'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.successColor,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ] else ...[
          Expanded(
            child: ElevatedButton(
              onPressed: _isAnswered ? null : _submitAnswer,
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
              child: const Text('Submit', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ),
          ),
        ],
      ]),
    );
  }
}
