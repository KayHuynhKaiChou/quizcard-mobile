import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../theme/app_theme.dart';

class ProgressTrackingScreen extends StatelessWidget {
  const ProgressTrackingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    color: AppTheme.textPrimaryColor,
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      }
                    },
                  ),
                ],
              ),
            ),
            
            // Illustration & Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 280,
                      height: 280,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: CachedNetworkImage(
                          imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuCHVfV2L5nqOYPQ8je0XuC44ELSGUGOR-GC-kKxeQT22SUQWNg2wGaVxh009cZIVOmVgbLyYcYKqJIN1I1IDrVoIpL9krFz0k-jQwBrbCuskUQBXxNWLC-RqYYU4dPldqtbjdOGre1-rvAyCjVAtwtpGiQn5fINVWHtVSm2Ry_2sEoHLWuuBtIJeiV8WhwDS77EmY7aQW97UVybVVeiXADeisix38KS9_WiedBdjvWOKMOtfA6EiwtIo5gNQVvveVImTbk6p81TG6NL',
                          fit: BoxFit.cover,
                          placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                          errorWidget: (context, url, error) => const Center(child: Icon(Icons.error, color: AppTheme.errorColor)),
                        ),
                      ).animate().fadeIn(duration: 800.ms).scale(begin: const Offset(0.95, 0.95)),
                    ),
                    const SizedBox(height: 40),
                    Text(
                      'Track Your Growth',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1, end: 0),
                    const SizedBox(height: 16),
                    Text(
                      'See your daily progress, earn achievement badges, and keep your learning streak alive.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppTheme.textSecondaryColor,
                          ),
                    ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1, end: 0),
                  ],
                ),
              ),
            ),
            
            // Bottom Action
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // Progress Dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(width: 8, height: 8, decoration: BoxDecoration(color: AppTheme.primaryColor.withValues(alpha: 0.3), shape: BoxShape.circle)),
                      const SizedBox(width: 8),
                      Container(width: 8, height: 8, decoration: BoxDecoration(color: AppTheme.primaryColor.withValues(alpha: 0.3), shape: BoxShape.circle)),
                      const SizedBox(width: 8),
                      Container(width: 32, height: 8, decoration: BoxDecoration(color: AppTheme.primaryColor, borderRadius: BorderRadius.circular(4))),
                    ],
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        context.go('/home'); // Finish onboarding
                      },
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Get Started', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ).animate().fadeIn(delay: 700.ms).scale(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
