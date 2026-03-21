import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../data/models/quiz_models.dart';
import '../../data/repositories/quiz_repository.dart';
import '../../data/services/auth_service.dart';
import '../../theme/app_theme.dart';

// ── Local result model (passed to QuizResultsScreen via router extra) ───────

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
  final String questionText;
  final String userAnswer;
  final String correctAnswer;
  WrongAnswer({
    required this.questionText,
    required this.userAnswer,
    required this.correctAnswer,
  });
}

// ── Screen ──────────────────────────────────────────────────────────────────

class QuizChallengeScreen extends StatefulWidget {
  final String studySetId;
  const QuizChallengeScreen({super.key, required this.studySetId});

  @override
  State<QuizChallengeScreen> createState() => _QuizChallengeScreenState();
}

class _QuizChallengeScreenState extends State<QuizChallengeScreen> {
  // ── Phase: setup | loading | quiz | submitting
  String _phase = 'setup';
  String? _error;

  // ── Setup config
  String _quizType = 'multiple_choice';
  int _questionCount = 10;

  // ── Quiz runtime state
  GeneratedQuiz? _quiz;
  int _currentIndex = 0;
  String? _selectedAnswer;
  final TextEditingController _fillCtrl = TextEditingController();
  bool _isAnswered = false;
  bool _fillAnswerCorrect = false;
  int _correctCount = 0;
  final List<WrongAnswer> _wrongAnswers = [];
  final List<QuizAnswer> _allAnswers = [];

  // ── Timer
  Timer? _timer;
  int _timeLeft = 20;
  int _quizStartMs = 0;

  @override
  void dispose() {
    _timer?.cancel();
    _fillCtrl.dispose();
    super.dispose();
  }

  // ── Helpers ────────────────────────────────────────────────────────────

  int get _timerMax => _quizType == 'fill_blank' ? 30 : 20;

  QuizQuestion? get _currentQ =>
      _quiz != null && _currentIndex < _quiz!.questions.length
          ? _quiz!.questions[_currentIndex]
          : null;

  // ── API calls ──────────────────────────────────────────────────────────

  Future<void> _startQuiz() async {
    setState(() {
      _phase = 'loading';
      _error = null;
    });
    try {
      final repo = QuizRepository(context.read<AuthService>());
      final quiz = await repo.generateQuiz(QuizConfig(
        studySetId: widget.studySetId,
        quizType: _quizType,
        questionCount: _questionCount,
      ));
      setState(() {
        _quiz = quiz;
        _currentIndex = 0;
        _correctCount = 0;
        _wrongAnswers.clear();
        _allAnswers.clear();
        _phase = 'quiz';
        _quizStartMs = DateTime.now().millisecondsSinceEpoch;
      });
      _startTimer();
    } catch (e) {
      setState(() {
        _phase = 'setup';
        _error = 'Failed to generate quiz. Please try again.';
      });
    }
  }

  Future<void> _finishQuiz() async {
    _timer?.cancel();
    final timeTaken =
        (DateTime.now().millisecondsSinceEpoch - _quizStartMs) ~/ 1000;
    setState(() => _phase = 'submitting');

    try {
      final repo = QuizRepository(context.read<AuthService>());
      await repo.submitQuiz(QuizSubmission(
        quizId: _quiz!.quizId,
        answers: _allAnswers,
        timeSpentSeconds: timeTaken,
      ));
    } catch (_) {
      // silently fail — still navigate to results
    }

    if (mounted) {
      context.go('/quiz_results',
          extra: LocalQuizResult(
            score: _correctCount,
            total: _quiz!.questions.length,
            timeTakenSeconds: timeTaken,
            wrongAnswers: _wrongAnswers,
            studySetId: widget.studySetId,
          ));
    }
  }

  // ── Timer ──────────────────────────────────────────────────────────────

  void _startTimer() {
    _timer?.cancel();
    setState(() => _timeLeft = _timerMax);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_timeLeft > 0) {
        setState(() => _timeLeft--);
      } else {
        _handleTimeout();
      }
    });
  }

  void _handleTimeout() {
    if (_isAnswered) return;
    final q = _currentQ;
    if (q == null) return;
    _recordAnswer(q, '', isTimeout: true);
  }

  // ── Answer logic ───────────────────────────────────────────────────────

  /// For MC: tap once to immediately submit
  void _onMCOptionTap(String option) {
    if (_isAnswered) return;
    setState(() => _selectedAnswer = option);
    _recordAnswer(_currentQ!, option);
  }

  /// For TF: tap True or False button
  void _onTFTap(String value) {
    if (_isAnswered) return;
    setState(() => _selectedAnswer = value);
    _recordAnswer(_currentQ!, value);
  }

  /// For Fill-blank: explicit Submit button
  void _onFillSubmit() {
    if (_isAnswered) return;
    final answer = _fillCtrl.text.trim();
    if (answer.isEmpty) return;
    _recordAnswer(_currentQ!, answer);
  }

  void _recordAnswer(QuizQuestion q, String userAnswer,
      {bool isTimeout = false}) {
    _timer?.cancel();
    final isCorrect = q.type == 'fill_blank'
        ? _fuzzyMatch(userAnswer, q.correctAnswer)
        : userAnswer == q.correctAnswer;

    _allAnswers
        .add(QuizAnswer(questionId: q.id, selectedAnswer: userAnswer));

    if (isCorrect) {
      _correctCount++;
    } else {
      _wrongAnswers.add(WrongAnswer(
        questionText: q.questionText,
        userAnswer: isTimeout
            ? '(Time out)'
            : userAnswer.isEmpty
                ? '(Skipped)'
                : userAnswer,
        correctAnswer: q.correctAnswer,
      ));
    }

    setState(() {
      _isAnswered = true;
      _fillAnswerCorrect = isCorrect;
    });

    // Auto-advance after feedback delay
    Future.delayed(const Duration(milliseconds: 1600), () {
      if (!mounted) return;
      if (_currentIndex < _quiz!.questions.length - 1) {
        setState(() {
          _currentIndex++;
          _selectedAnswer = null;
          _fillCtrl.clear();
          _isAnswered = false;
          _fillAnswerCorrect = false;
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

  // ── Build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/home'),
        ),
        title: const Text('Quiz Challenge'),
      ),
      body: switch (_phase) {
        'loading' || 'submitting' => const Center(
            child: CircularProgressIndicator()),
        'quiz' => _buildQuizPhase(),
        _ => _buildSetupPhase(),
      },
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SETUP PHASE
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildSetupPhase() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_error != null) ...[
            _ErrorBanner(message: _error!),
            const SizedBox(height: 16),
          ],

          // Quiz type selector
          Text('Quiz Type',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),

          for (final tp in [
            ('multiple_choice', 'Multiple Choice', Icons.list_outlined),
            ('true_false', 'True / False', Icons.check_circle_outline),
            ('fill_blank', 'Fill in the Blank', Icons.edit_outlined),
          ])
            _TypeTile(
              label: tp.$2,
              icon: tp.$3,
              subtitle: tp.$1 == 'fill_blank' ? '30s per question' : '20s per question',
              isSelected: _quizType == tp.$1,
              onTap: () => setState(() => _quizType = tp.$1),
            ),

          const SizedBox(height: 24),

          // Question count
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Questions',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              _CountBadge(count: _questionCount),
            ],
          ),
          Slider(
            value: _questionCount.toDouble(),
            min: 1,
            max: 20,
            divisions: 19,
            activeColor: AppTheme.primaryColor,
            onChanged: (v) => setState(() => _questionCount = v.round()),
          ),

          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _startQuiz,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Start Quiz',
                  style:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16)),
            ),
          ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.05),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // QUIZ PHASE
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildQuizPhase() {
    final q = _currentQ;
    if (q == null) return const SizedBox();
    final total = _quiz!.questions.length;
    final timerRatio = _timeLeft / _timerMax;
    final timerColor = timerRatio > 0.4
        ? AppTheme.primaryColor
        : timerRatio > 0.2
            ? const Color(0xFFF59E0B)
            : AppTheme.errorColor;

    return Column(
      children: [
        // ─ Header: question counter + timer ─
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Question ${_currentIndex + 1} of $total',
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 14),
              ),
              _TimerBadge(timeLeft: _timeLeft, color: timerColor),
            ],
          ),
        ),
        // Timer progress bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: timerRatio,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              valueColor: AlwaysStoppedAnimation(timerColor),
              minHeight: 5,
            ),
          ),
        ),
        // Question progress bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (_currentIndex + 1) / total,
              backgroundColor: Colors.white.withValues(alpha: 0.05),
              valueColor:
                  const AlwaysStoppedAnimation(AppTheme.primaryColor),
              minHeight: 3,
            ),
          ),
        ),

        const SizedBox(height: 16),

        // ─ Question card ─
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: [
                AnimatedSwitcher(
                  duration: 180.ms,
                  child:
                      _buildQuestionContent(q, key: ValueKey(_currentIndex)),
                ),
              ],
            ),
          ),
        ),

        // ─ Action bar ─
        _buildActionBar(q),
      ],
    );
  }

  Widget _buildQuestionContent(QuizQuestion q, {Key? key}) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        switch (q.type) {
          'true_false' => _buildTrueFalseContent(q),
          'fill_blank' => _buildFillBlankContent(q),
          _ => _buildMultiChoiceContent(q),
        },
      ],
    );
  }

  // ─ Multiple Choice ─────────────────────────────────────────────────────

  Widget _buildMultiChoiceContent(QuizQuestion q) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Question prompt
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              const Text('TERM',
                  style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2)),
              const SizedBox(height: 8),
              Text(
                q.questionText,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ).animate().fadeIn(duration: 180.ms),
        const SizedBox(height: 8),
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 8),
          child: Text('Choose the correct definition:',
              style: TextStyle(
                  color: AppTheme.textSecondaryColor, fontSize: 13)),
        ),
        // Options
        ...q.options.asMap().entries.map((entry) {
          final option = entry.value;
          final idx = entry.key;
          final isSelected = _selectedAnswer == option;
          final isCorrect = _isAnswered && option == q.correctAnswer;
          final isWrong =
              _isAnswered && isSelected && option != q.correctAnswer;

          Color bg = AppTheme.surfaceColor;
          Color border = Colors.white.withValues(alpha: 0.08);
          if (isCorrect) {
            bg = AppTheme.successColor.withValues(alpha: 0.12);
            border = AppTheme.successColor;
          } else if (isWrong) {
            bg = AppTheme.errorColor.withValues(alpha: 0.12);
            border = AppTheme.errorColor;
          } else if (isSelected) {
            bg = AppTheme.primaryColor.withValues(alpha: 0.1);
            border = AppTheme.primaryColor;
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GestureDetector(
              onTap: () => _onMCOptionTap(option),
              child: AnimatedContainer(
                duration: 200.ms,
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: border,
                      width: (isCorrect || isWrong) ? 1.5 : 1),
                ),
                child: Row(
                  children: [
                    // Option letter badge
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: isCorrect
                            ? AppTheme.successColor
                            : isWrong
                                ? AppTheme.errorColor
                                : isSelected
                                    ? AppTheme.primaryColor
                                    : Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(
                        child: isCorrect
                            ? const Icon(Icons.check,
                                color: Colors.white, size: 16)
                            : isWrong
                                ? const Icon(Icons.close,
                                    color: Colors.white, size: 16)
                                : Text(
                                    String.fromCharCode(65 + idx),
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12),
                                  ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        option,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: (isSelected || isCorrect)
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate(delay: Duration(milliseconds: 60 * idx))
                  .fadeIn(duration: 150.ms)
                  .slideY(begin: 0.04, end: 0),
            ),
          );
        }),
      ],
    );
  }

  // ─ True / False ────────────────────────────────────────────────────────

  Widget _buildTrueFalseContent(QuizQuestion q) {
    // correctAnswer is 'true' or 'false'
    // questionText shows the term; options[0] is the displayed definition statement
    final statement =
        q.options.isNotEmpty ? q.options.first : q.questionText;

    final selectedTrue = _selectedAnswer == 'true';
    final selectedFalse = _selectedAnswer == 'false';
    final answeredCorrect = q.correctAnswer;

    Color trueColor = const Color(0xFF22C55E);
    Color falseColor = AppTheme.errorColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Term
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              const Text('TERM',
                  style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2)),
              const SizedBox(height: 8),
              Text(
                q.questionText,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ).animate().fadeIn(duration: 180.ms),
        const SizedBox(height: 16),

        // Statement to evaluate
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(12),
            border:
                Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Column(
            children: [
              const Text('Is this definition correct?',
                  style: TextStyle(
                      color: AppTheme.textSecondaryColor, fontSize: 12)),
              const SizedBox(height: 8),
              Text(
                '"$statement"',
                style: const TextStyle(
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                    height: 1.4),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // True / False big buttons
        Row(
          children: [
            // TRUE
            Expanded(
              child: GestureDetector(
                onTap: () => _onTFTap('true'),
                child: AnimatedContainer(
                  duration: 200.ms,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  decoration: BoxDecoration(
                    color: _isAnswered
                        ? answeredCorrect == 'true'
                            ? trueColor.withValues(alpha: 0.2)
                            : (selectedTrue
                                ? AppTheme.errorColor.withValues(alpha: 0.15)
                                : AppTheme.surfaceColor)
                        : selectedTrue
                            ? trueColor.withValues(alpha: 0.15)
                            : AppTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _isAnswered
                          ? answeredCorrect == 'true'
                              ? trueColor
                              : (selectedTrue
                                  ? AppTheme.errorColor
                                  : Colors.white.withValues(alpha: 0.08))
                          : selectedTrue
                              ? trueColor
                              : Colors.white.withValues(alpha: 0.08),
                      width: selectedTrue || (_isAnswered && answeredCorrect == 'true') ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        color: _isAnswered && answeredCorrect == 'true'
                            ? trueColor
                            : selectedTrue && _isAnswered
                                ? AppTheme.errorColor
                                : trueColor,
                        size: 32,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'TRUE',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: _isAnswered && answeredCorrect == 'true'
                              ? trueColor
                              : selectedTrue && _isAnswered
                                  ? AppTheme.errorColor
                                  : trueColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // FALSE
            Expanded(
              child: GestureDetector(
                onTap: () => _onTFTap('false'),
                child: AnimatedContainer(
                  duration: 200.ms,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  decoration: BoxDecoration(
                    color: _isAnswered
                        ? answeredCorrect == 'false'
                            ? falseColor.withValues(alpha: 0.2)
                            : (selectedFalse
                                ? AppTheme.errorColor.withValues(alpha: 0.15)
                                : AppTheme.surfaceColor)
                        : selectedFalse
                            ? falseColor.withValues(alpha: 0.15)
                            : AppTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _isAnswered
                          ? answeredCorrect == 'false'
                              ? falseColor
                              : (selectedFalse
                                  ? AppTheme.errorColor
                                  : Colors.white.withValues(alpha: 0.08))
                          : selectedFalse
                              ? falseColor
                              : Colors.white.withValues(alpha: 0.08),
                      width: selectedFalse || (_isAnswered && answeredCorrect == 'false') ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.cancel_outlined,
                        color: _isAnswered && answeredCorrect == 'false'
                            ? falseColor
                            : selectedFalse && _isAnswered
                                ? AppTheme.errorColor
                                : falseColor,
                        size: 32,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'FALSE',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: _isAnswered && answeredCorrect == 'false'
                              ? falseColor
                              : selectedFalse && _isAnswered
                                  ? AppTheme.errorColor
                                  : falseColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.05, end: 0),
      ],
    );
  }

  // ─ Fill in the Blank ───────────────────────────────────────────────────

  Widget _buildFillBlankContent(QuizQuestion q) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('What term matches this definition?',
            style:
                TextStyle(color: AppTheme.textSecondaryColor, fontSize: 13)),
        const SizedBox(height: 12),
        // Definition prompt
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              const Text('DEFINITION',
                  style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2)),
              const SizedBox(height: 8),
              Text(
                q.questionText,
                style: const TextStyle(
                    color: Colors.white, fontSize: 18, height: 1.4),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ).animate().fadeIn(duration: 180.ms),
        const SizedBox(height: 20),

        // Input
        TextField(
          controller: _fillCtrl,
          enabled: !_isAnswered,
          onSubmitted: (_) => _onFillSubmit(),
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            hintText: 'Type the term...',
            suffixIcon: _isAnswered
                ? Icon(
                    _fillAnswerCorrect
                        ? Icons.check_circle
                        : Icons.cancel,
                    color: _fillAnswerCorrect
                        ? AppTheme.successColor
                        : AppTheme.errorColor,
                  )
                : null,
          ),
        ),

        // Feedback after answering
        if (_isAnswered) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (_fillAnswerCorrect
                      ? AppTheme.successColor
                      : AppTheme.errorColor)
                  .withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _fillAnswerCorrect
                    ? AppTheme.successColor
                    : AppTheme.errorColor,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _fillAnswerCorrect ? Icons.check_circle : Icons.info_outline,
                  color: _fillAnswerCorrect
                      ? AppTheme.successColor
                      : AppTheme.errorColor,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _fillAnswerCorrect
                      ? const Text('Correct! Well done.',
                          style: TextStyle(
                              color: AppTheme.successColor,
                              fontWeight: FontWeight.w600))
                      : RichText(
                          text: TextSpan(
                            style: const TextStyle(
                                color: AppTheme.errorColor, fontSize: 13),
                            children: [
                              const TextSpan(text: 'Correct answer: '),
                              TextSpan(
                                text: q.correctAnswer,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 200.ms),
        ],
      ],
    );
  }

  // ─ Action bar ──────────────────────────────────────────────────────────

  Widget _buildActionBar(QuizQuestion q) {
    // MC and TF: auto-submit on tap — no action bar needed (auto-advances)
    // Fill-blank: show Submit button
    if (q.type != 'FILL_BLANK') return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        border: Border(
            top:
                BorderSide(color: Colors.white.withValues(alpha: 0.08))),
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _isAnswered ? null : _onFillSubmit,
          style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14)),
          child: const Text('Submit',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ),
      ),
    );
  }
}

// ── Helper sub-widgets ──────────────────────────────────────────────────────

class _TypeTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _TypeTile({
    required this.label,
    required this.icon,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.primaryColor.withValues(alpha: 0.1)
                : AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? AppTheme.primaryColor
                  : Colors.white.withValues(alpha: 0.08),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(icon,
                  size: 22,
                  color: isSelected
                      ? AppTheme.primaryColor
                      : AppTheme.textSecondaryColor),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: TextStyle(
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isSelected
                              ? AppTheme.primaryColor
                              : AppTheme.textPrimaryColor,
                        )),
                    Text(subtitle,
                        style: const TextStyle(
                            color: AppTheme.textSecondaryColor,
                            fontSize: 12)),
                  ],
                ),
              ),
              if (isSelected)
                const Icon(Icons.check_circle,
                    color: AppTheme.primaryColor, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  final int count;
  const _CountBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text('$count',
          style: const TextStyle(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.bold,
              fontSize: 16)),
    );
  }
}

class _TimerBadge extends StatelessWidget {
  final int timeLeft;
  final Color color;
  const _TimerBadge({required this.timeLeft, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(children: [
        Icon(Icons.timer_outlined, size: 14, color: color),
        const SizedBox(width: 4),
        Text('${timeLeft}s',
            style: TextStyle(
                color: color, fontWeight: FontWeight.bold, fontSize: 13)),
      ]),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.errorColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.errorColor.withValues(alpha: 0.4)),
      ),
      child: Row(children: [
        const Icon(Icons.error_outline, color: AppTheme.errorColor, size: 18),
        const SizedBox(width: 8),
        Expanded(
            child: Text(message,
                style: const TextStyle(
                    color: AppTheme.errorColor, fontSize: 13))),
      ]),
    );
  }
}
