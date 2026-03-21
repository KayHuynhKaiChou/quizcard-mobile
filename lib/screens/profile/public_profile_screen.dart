import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';

class PublicProfileScreen extends StatelessWidget {
  const PublicProfileScreen({super.key});

  static const List<Map<String, dynamic>> _decks = [
    {'title': 'Anatomy 101', 'terms': '120 Terms', 'progress': 0.45},
    {'title': 'Pharmacology Basics', 'terms': '85 Terms', 'progress': 0.12},
    {'title': 'Cardiology Definitions', 'terms': '50 Terms', 'progress': 0.80},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go('/home'),
        ),
        title: const Text('Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          children: [
            // Profile Header
            Container(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
              ),
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(64),
                    child: CachedNetworkImage(
                      imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuBwgenvTOgRgrX82eEydbN3gozjs-aOc4iGtch3U0W9TguzpiPLNCHY7jwty8nniw-s19r2UJDU_rptqMXoUeRfGVaI9hF8SU67eOtVJzA5wnrBPcqIQtR7ZmBhhpNOocqPdT3pKfc5XqJejHDQjbiXJCCluQs9kobs5Fov6mt9oy4zMws6f9Wz7wQn1-FngR8Rhupx9V-U5dlq_OdzqJC3SUnnUcjrkpBJAfn-r2xsxw8tYGsPYrFPoGZaJGUjw3dDx90juCzBsiUz',
                      width: 128, height: 128, fit: BoxFit.cover,
                      placeholder: (ctx, url) => Container(width: 128, height: 128, color: AppTheme.backgroundColor),
                      errorWidget: (ctx, url, err) => Container(width: 128, height: 128, color: AppTheme.backgroundColor, child: const Icon(Icons.person, size: 64, color: AppTheme.textSecondaryColor)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Alex Johnson', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Text('Medical Student', style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 15)),
                  const SizedBox(height: 4),
                  const Text('Joined in 2021', style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 13)),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => context.go('/home'),
                          style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                          child: const Text('Follow', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => context.go('/home'),
                          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                          child: const Text('Message', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ).animate().fadeIn(duration: 500.ms),
            ),

            // Achievements
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Top Achievements', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _AchievementStat(icon: Icons.menu_book, label: 'Terms Learned', value: '1.2k', color: AppTheme.primaryColor),
                      const SizedBox(width: 12),
                      _AchievementStat(icon: Icons.emoji_events, label: 'Quizzes Won', value: '45', color: Colors.green),
                      const SizedBox(width: 12),
                      _AchievementStat(icon: Icons.style, label: 'Flashcards', value: '300', color: Colors.purple),
                    ],
                  ),
                ],
              ).animate().fadeIn(delay: 200.ms),
            ),

            // Public Decks
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Public Decks', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  ..._decks.asMap().entries.map((entry) {
                    final deck = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(deck['title'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                    const SizedBox(height: 4),
                                    Row(children: [
                                      const Icon(Icons.style_outlined, size: 14, color: AppTheme.textSecondaryColor),
                                      const SizedBox(width: 4),
                                      Text(deck['terms'] as String, style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 13)),
                                    ]),
                                  ],
                                ),
                                TextButton(
                                  onPressed: () => context.go('/home'),
                                  style: TextButton.styleFrom(
                                    backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                                    foregroundColor: AppTheme.primaryColor,
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  child: const Text('Study', style: TextStyle(fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: deck['progress'] as double,
                                backgroundColor: Colors.white.withValues(alpha: 0.08),
                                valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                                minHeight: 6,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                '${((deck['progress'] as double) * 100).round()}% mastered',
                                style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 11),
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: Duration(milliseconds: 100 * entry.key)).slideY(begin: 0.05, end: 0),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AchievementStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _AchievementStat({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(label, textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 10, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
