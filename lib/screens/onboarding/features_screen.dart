import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../theme/app_theme.dart';

class FeaturesScreen extends StatelessWidget {
  const FeaturesScreen({super.key});

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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    color: AppTheme.textPrimaryColor,
                    onPressed: () {
                      context.go('/home'); // Skip mapping
                    },
                  ),
                  TextButton(
                    onPressed: () {
                      context.go('/home'); // Skip mapping
                    },
                    child: const Text('Skip', style: TextStyle(color: AppTheme.textSecondaryColor, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            
            // Illustration Area
            Expanded(
              flex: 5,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: AppTheme.surfaceColor,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CachedNetworkImage(
                          imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuAMeScS1PHkhn8YVcEBZOhC6OFImOBSPrV9cvHYfggUwSrQlyHGlkOW46A0X8plgIZhCaYojx6kqWoKolgwLOz-VmW5gI_Nwo-MC1xBbD3_GAEQebqrBeVeH3NnXifMhdRVDD_EF7QiR7XEmUQ0q-TPcfCCsbRbKWmFmMAU1X_czozVD2Xa8RmnPJpenrq0IpTb9DIqX9ow6L_2_gTqPLXZjNkjfhcjxwbjNGiteUKpBVril9s3LH6ddYCzYX4c-bH2hgDanQ3jCb9d',
                          fit: BoxFit.cover,
                          placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                          errorWidget: (context, url, error) => const Center(child: Icon(Icons.error, color: AppTheme.errorColor)),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                AppTheme.backgroundColor.withValues(alpha: 0.8),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 800.ms).scale(begin: const Offset(0.95, 0.95)),
                ),
              ),
            ),
            
            // Content
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'Challenge Yourself',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1, end: 0),
                    const SizedBox(height: 16),
                    Text(
                      'Test your knowledge with interactive quizzes and climb the global leaderboard to compete with others.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppTheme.textSecondaryColor,
                          ),
                    ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1, end: 0),
                    const Spacer(),
                    
                    // Progress Dots
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(width: 8, height: 8, decoration: BoxDecoration(color: AppTheme.primaryColor.withValues(alpha: 0.3), shape: BoxShape.circle)),
                        const SizedBox(width: 8),
                        Container(width: 32, height: 8, decoration: BoxDecoration(color: AppTheme.primaryColor, borderRadius: BorderRadius.circular(4))),
                        const SizedBox(width: 8),
                        Container(width: 8, height: 8, decoration: BoxDecoration(color: AppTheme.primaryColor.withValues(alpha: 0.3), shape: BoxShape.circle)),
                      ],
                    ),
                    const SizedBox(height: 32),
                    
                    // Action Button
                    SizedBox(
                      width: double.infinity,
                      child: ActionChip(
                        onPressed: () {
                          context.go('/progress');
                        },
                        label: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Next', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                          ],
                        ),
                        backgroundColor: AppTheme.primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ).animate().fadeIn(delay: 700.ms).scale(),
                    const SizedBox(height: 16),
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
