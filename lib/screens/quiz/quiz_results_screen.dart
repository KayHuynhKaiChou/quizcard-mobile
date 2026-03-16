import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_theme.dart';

class QuizResultsScreen extends StatelessWidget {
  const QuizResultsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.close), onPressed: () => context.go('/home')),
        title: const Text('Quiz Results'),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Score Section
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Decorative floating icons
                        const Positioned(top: 0, left: 20, child: Icon(Icons.star, color: Color(0xFFEAB308), size: 28)),
                        const Positioned(top: 20, right: 30, child: Icon(Icons.celebration, color: Color(0xFFEC4899), size: 22)),
                        const Positioned(bottom: 20, left: 40, child: Icon(Icons.hotel_class, color: Color(0xFF22C55E), size: 18)),
                        const Positioned(bottom: 10, right: 50, child: Icon(Icons.stars, color: AppTheme.primaryColor, size: 28)),
                        Column(
                          children: [
                            SizedBox(
                              width: 180, height: 180,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  SizedBox.expand(
                                    child: CircularProgressIndicator(
                                      value: 0.85,
                                      strokeWidth: 12,
                                      backgroundColor: Colors.white.withValues(alpha: 0.08),
                                      valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                                      strokeCap: StrokeCap.round,
                                    ),
                                  ),
                                  const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text('85%', style: TextStyle(fontSize: 44, fontWeight: FontWeight.bold)),
                                      Text('Score', style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 14)),
                                    ],
                                  ),
                                ],
                              ),
                            ).animate().scale(delay: 300.ms, duration: 600.ms, curve: Curves.elasticOut),
                            const SizedBox(height: 20),
                            const Text('Outstanding!',
                              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                            ).animate().fadeIn(delay: 500.ms),
                            const SizedBox(height: 8),
                            const Text('You mastered most of the terminology.',
                              style: TextStyle(color: AppTheme.textSecondaryColor),
                            ).animate().fadeIn(delay: 600.ms),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Stats Grid
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        _StatCard(icon: Icons.check_circle, count: '17', label: 'Correct',
                          color: const Color(0xFF22C55E), bgColor: const Color(0xFF22C55E).withValues(alpha: 0.1)),
                        const SizedBox(width: 12),
                        _StatCard(icon: Icons.cancel, count: '3', label: 'Incorrect',
                          color: const Color(0xFFEF4444), bgColor: const Color(0xFFEF4444).withValues(alpha: 0.1)),
                        const SizedBox(width: 12),
                        _StatCard(icon: Icons.timer_outlined, count: '04:12', label: 'Time',
                          color: AppTheme.textSecondaryColor, bgColor: AppTheme.surfaceColor),
                      ],
                    ),
                  ).animate().fadeIn(delay: 700.ms).slideY(begin: 0.1, end: 0),

                  // Review Mistakes
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Review Mistakes',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  ..._buildMistakeList().animate(interval: 100.ms).fadeIn().slideY(begin: 0.05, end: 0),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),

          // Footer Buttons
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            decoration: BoxDecoration(
              color: AppTheme.backgroundColor,
              border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
            ),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => context.go('/quiz_challenge'),
                    icon: const Icon(Icons.replay),
                    label: const Text('Try Again', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => context.go('/home'),
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                    child: const Text('Back to Home', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildMistakeList() {
    const mistakes = [
      {'term': 'Epistemology', 'def': 'The theory of knowledge, especially with regard to its methods, validity, and scope.'},
      {'term': 'Heuristic', 'def': 'A practical approach to problem-solving or learning that is not guaranteed to be optimal or perfect.'},
      {'term': 'Ontology', 'def': 'The branch of metaphysics dealing with the nature of being.'},
    ];

    return mistakes.map((m) => Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.red, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(m['term']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 4),
                  Text(m['def']!, style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 13, height: 1.4)),
                ],
              ),
            ),
          ],
        ),
      ),
    )).toList();
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String count;
  final String label;
  final Color color;
  final Color bgColor;

  const _StatCard({required this.icon, required this.count, required this.label, required this.color, required this.bgColor});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(count, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(label.toUpperCase(), style: TextStyle(color: color.withValues(alpha: 0.8), fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
          ],
        ),
      ),
    );
  }
}
