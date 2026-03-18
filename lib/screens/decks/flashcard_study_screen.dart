import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';

class FlashcardStudyScreen extends StatefulWidget {
  const FlashcardStudyScreen({super.key});

  @override
  State<FlashcardStudyScreen> createState() => _FlashcardStudyScreenState();
}

class _FlashcardStudyScreenState extends State<FlashcardStudyScreen>
    with SingleTickerProviderStateMixin {
  int _currentCard = 5;
  final int _totalCards = 20;
  bool _isFlipped = false;
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;

  final List<Map<String, String>> _cards = const [
    {'term': 'Photosynthesis', 'def': 'The process by which green plants use sunlight to synthesize nutrients from carbon dioxide and water.'},
    {'term': 'Osmosis', 'def': 'Movement of solvent molecules through a semipermeable membrane from lower to higher solute concentration.'},
    {'term': 'Mitosis', 'def': 'A type of cell division resulting in two daughter cells each having the same number and kind of chromosomes as the parent nucleus.'},
  ];

  int _cardIndex = 0;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOutCubic),
    );
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  void _flipCard() {
    setState(() => _isFlipped = !_isFlipped);
    if (_isFlipped) {
      _flipController.forward();
    } else {
      _flipController.reverse();
    }
  }

  void _nextCard(BuildContext context, {bool knew = true}) {
    if (knew && _currentCard >= _totalCards) {
      context.go('/quiz_results');
      return;
    }

    setState(() {
      _isFlipped = false;
      _flipController.value = 0;
      _cardIndex = (_cardIndex + 1) % _cards.length;
      if (knew) _currentCard = (_currentCard + 1).clamp(1, _totalCards);
    });
  }

  @override
  Widget build(BuildContext context) {
    final card = _cards[_cardIndex];
    final progress = _currentCard / _totalCards;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.close), onPressed: () => context.canPop() ? context.pop() : context.go('/home')),
        title: const Text('Study Mode'),
        actions: [
          IconButton(icon: const Icon(Icons.quiz_outlined), onPressed: () => context.go('/quiz_challenge')),
        ],
      ),
      body: Column(
        children: [
          // Progress
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Card $_currentCard of $_totalCards',
                  style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 13)),
                Text('${(progress * 100).round()}%',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.white.withValues(alpha: 0.1),
                valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                minHeight: 8,
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Flashcard
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: GestureDetector(
                onTap: _flipCard,
                child: AnimatedBuilder(
                  animation: _flipAnimation,
                  builder: (context, child) {
                    final isBackShowing = _flipAnimation.value >= 0.5;
                    return Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.001)
                        ..rotateY(3.14159 * _flipAnimation.value),
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: isBackShowing
                                ? [const Color(0xFF134E5E), const Color(0xFF71B280)]
                                : [const Color(0xFF667eea), const Color(0xFF764ba2)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 20, offset: const Offset(0, 8)),
                          ],
                        ),
                        child: Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.identity()..rotateY(isBackShowing ? 3.14159 : 0),
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  isBackShowing ? Icons.psychology : Icons.school,
                                  size: 40, color: Colors.white.withValues(alpha: 0.8),
                                ).animate().fadeIn(duration: 200.ms),
                                const SizedBox(height: 24),
                                Text(
                                  isBackShowing ? card['def']! : card['term']!,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: isBackShowing ? 16 : 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    height: 1.4,
                                  ),
                                ),
                                const Spacer(),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.touch_app, color: Colors.white54, size: 16),
                                    const SizedBox(width: 4),
                                    Text(
                                      isBackShowing ? 'Tap to flip back' : 'Tap to flip',
                                      style: const TextStyle(color: Colors.white54, fontSize: 13),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          // Action Buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _nextCard(context, knew: false),
                    icon: const Icon(Icons.close),
                    label: const Text('Still Learning'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.withValues(alpha: 0.15),
                      foregroundColor: Colors.red,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: Colors.red.withValues(alpha: 0.3)),
                      shadowColor: Colors.transparent,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _nextCard(context, knew: true),
                    icon: const Icon(Icons.check),
                    label: const Text('Know it'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
