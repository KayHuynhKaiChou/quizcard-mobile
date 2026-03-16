import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';

class QuizChallengeScreen extends StatefulWidget {
  const QuizChallengeScreen({super.key});

  @override
  State<QuizChallengeScreen> createState() => _QuizChallengeScreenState();
}

class _QuizChallengeScreenState extends State<QuizChallengeScreen>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 1; // Mimics "Onomatopoeia" selected
  final int _currentQuestion = 13;
  final int _totalQuestions = 20;
  int _timeSeconds = 30;
  final int _timeMins = 4;
  late AnimationController _timerController;

  final List<String> _options = ['Alliteration', 'Onomatopoeia', 'Simile', 'Metaphor'];

  @override
  void initState() {
    super.initState();
    _timerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..addListener(() {
      setState(() => _timeSeconds = 30 - (30 * _timerController.value).round());
    });
    _timerController.forward();
  }

  @override
  void dispose() {
    _timerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = _currentQuestion / _totalQuestions;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.close), onPressed: () => context.go('/home')),
        title: const Text('Quiz Challenge'),
      ),
      body: Column(
        children: [
          // Progress Section
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Question $_currentQuestion of $_totalQuestions',
                    style: const TextStyle(fontWeight: FontWeight.w500)),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.white.withValues(alpha: 0.1),
                    valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Timer
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('0$_timeMins', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const Text('Mins', style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.4)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _timeSeconds.toString().padLeft(2, '0'),
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                        ),
                        const Text('Secs', style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Question
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
              child: Column(
                children: [
                  Text(
                    'What is the term for a word that sounds like what it means?',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold, fontSize: 22, height: 1.4,
                    ),
                  ).animate().fadeIn(delay: 200.ms),
                  const SizedBox(height: 32),

                  // Options
                  ...List.generate(_options.length, (index) {
                    final isSelected = _selectedIndex == index;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedIndex = index),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: double.infinity,
                          height: 56,
                          decoration: BoxDecoration(
                            color: isSelected ? AppTheme.primaryColor : AppTheme.surfaceColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? AppTheme.primaryColor : Colors.white.withValues(alpha: 0.08),
                            ),
                            boxShadow: isSelected ? [BoxShadow(color: AppTheme.primaryColor.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))] : null,
                          ),
                          child: Center(
                            child: Text(
                              _options[index],
                              style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15,
                                color: isSelected ? Colors.white : AppTheme.textPrimaryColor,
                              ),
                            ),
                          ),
                        ),
                      ).animate().fadeIn(delay: Duration(milliseconds: 100 + 50 * index)).slideY(begin: 0.05, end: 0),
                    );
                  }),
                ],
              ),
            ),
          ),

          // Skip Button
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                TextButton(
                  onPressed: () => context.go('/quiz_results'),
                  child: const Text('Skip Question', style: TextStyle(color: AppTheme.textSecondaryColor)),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: () => context.go('/quiz_results'),
                  child: const Text('Submit'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
