import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_theme.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              flex: 5,
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: AppTheme.surfaceColor,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(48),
                    bottomRight: Radius.circular(48),
                  ),
                ),
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.topRight,
                      child: TextButton(
                        onPressed: () {
                          context.go('/home'); // Skip to home
                        },
                        child: const Text('Skip'),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: Container(
                          width: 280,
                          height: 280,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.primaryColor.withValues(alpha: 0.1),
                          ),
                          child: const Icon(
                            Icons.menu_book,
                            size: 100,
                            color: AppTheme.primaryColor,
                          ).animate().fadeIn(duration: 800.ms).scale(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      children: [
                        Text(
                          'Welcome to\nTerminology Master!',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1, end: 0),
                        const SizedBox(height: 16),
                        Text(
                          'Learn and master complex academic terms effortlessly with our smart flashcard system.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: AppTheme.textSecondaryColor,
                              ),
                        ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1, end: 0),
                      ],
                    ),
                    Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(width: 32, height: 8, decoration: BoxDecoration(color: AppTheme.primaryColor, borderRadius: BorderRadius.circular(4))),
                            const SizedBox(width: 8),
                            Container(width: 8, height: 8, decoration: BoxDecoration(color: AppTheme.primaryColor.withValues(alpha: 0.3), shape: BoxShape.circle)),
                            const SizedBox(width: 8),
                            Container(width: 8, height: 8, decoration: BoxDecoration(color: AppTheme.primaryColor.withValues(alpha: 0.3), shape: BoxShape.circle)),
                          ],
                        ),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              context.go('/features');
                            },
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('Next'),
                                SizedBox(width: 8),
                                Icon(Icons.arrow_forward),
                              ],
                            ),
                          ),
                        ).animate().fadeIn(delay: 700.ms).scale(),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
