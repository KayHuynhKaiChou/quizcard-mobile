import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';

class UserProfileScreen extends StatelessWidget {
  const UserProfileScreen({super.key});

  static const List<Map<String, dynamic>> _weeklyActivity = [
    {'day': 'M', 'value': 0.30},
    {'day': 'T', 'value': 0.50},
    {'day': 'W', 'value': 0.80},
    {'day': 'T', 'value': 0.45},
    {'day': 'F', 'value': 0.90, 'isPeak': true},
    {'day': 'S', 'value': 0.60},
    {'day': 'S', 'value': 0.70},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(icon: const Icon(Icons.notifications_outlined), onPressed: () {}),
          IconButton(icon: const Icon(Icons.settings_outlined), onPressed: () {}),
        ],
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          children: [
            // User Info
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () => context.go('/public_profile'),
                    child: Stack(
                      children: [
                      Container(
                        width: 110, height: 110,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3), width: 4),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(60),
                          child: CachedNetworkImage(
                            imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuCho5b1G7fhL7UJEri0J3IfJU3WAleagj6NTilBLx9j0h867sJCICVEmiDMLlstpJRwnqHeROBs0aqCwT6XDT3AJvYaFkPt-RX9Bu6YzAN4U5-rQFkqOkaj_X3UZIva-3HUOr_ZFe0ahMWENhPpi85dvULeyb6QigcJyogZF3RfA2sU-Y91V3NfFiQJq8xkg0-YHDvxgAeueQ4NbnObhOPn62fErsz_sEOHLq-mc7SRwu4OiBpTc3UMactmHlAqyxlgJHGdvyigM7Dq',
                            width: 110, height: 110, fit: BoxFit.cover,
                            placeholder: (ctx, url) => Container(color: AppTheme.surfaceColor),
                            errorWidget: (ctx, url, err) => const Icon(Icons.person, size: 60, color: AppTheme.textSecondaryColor),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0, right: 0,
                        child: Container(
                          width: 32, height: 32,
                          decoration: const BoxDecoration(color: AppTheme.primaryColor, shape: BoxShape.circle),
                          child: const Icon(Icons.edit, size: 16, color: Colors.white),
                        ),
                      ),
                    ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Jane Doe', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.school, color: AppTheme.primaryColor, size: 16),
                        SizedBox(width: 4),
                        Text('Level 5 Terminology Learner', style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.w500, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ).animate().fadeIn(duration: 500.ms),
            ),

            // Stats
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _StatChip(label: 'Quizzes', value: '24'),
                  const SizedBox(width: 12),
                  _StatChip(label: 'Terms', value: '150'),
                  const SizedBox(width: 12),
                  _StatChip(label: 'Day Streak', value: '7', icon: Icons.local_fire_department, iconColor: Colors.orange),
                ],
              ).animate().fadeIn(delay: 200.ms),
            ),
            const SizedBox(height: 24),

            // Achievements
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Achievements', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                      TextButton(onPressed: () => context.go('/leaderboard'), child: const Text('View All')),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _AchievementBadge(icon: Icons.emoji_events, label: 'Fast Learner', bgColor: const Color(0xFFFEF9C3), iconColor: const Color(0xFFCA8A04), borderColor: const Color(0xFFFDE68A)),
                      const SizedBox(width: 12),
                      _AchievementBadge(icon: Icons.psychology, label: 'Master Mind', bgColor: const Color(0xFFDBEAFE), iconColor: const Color(0xFF2563EB), borderColor: const Color(0xFFBFDAFE)),
                      const SizedBox(width: 12),
                      _AchievementBadge(icon: Icons.lock_outlined, label: 'Vocabulary', bgColor: AppTheme.surfaceColor, iconColor: AppTheme.textSecondaryColor, borderColor: Colors.white.withValues(alpha: 0.08), locked: true),
                    ],
                  ),
                ],
              ).animate().fadeIn(delay: 300.ms),
            ),
            const SizedBox(height: 24),

            // Learning Activity Chart
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Learning Activity', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Container(
                    height: 150,
                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 24),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: _weeklyActivity.map((data) {
                        final isPeak = data['isPeak'] == true;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 3),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Expanded(
                                  child: FractionallySizedBox(
                                    alignment: Alignment.bottomCenter,
                                    heightFactor: data['value'] as double,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: isPeak ? AppTheme.primaryColor : AppTheme.primaryColor.withValues(alpha: 0.25),
                                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(data['day'] as String,
                                  style: TextStyle(
                                    fontSize: 11, fontWeight: isPeak ? FontWeight.bold : FontWeight.w400,
                                    color: isPeak ? AppTheme.primaryColor : AppTheme.textSecondaryColor,
                                  )),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 400.ms),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;
  final Color? iconColor;

  const _StatChip({required this.label, required this.value, this.icon, this.iconColor});

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
            if (icon != null)
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(icon, color: iconColor, size: 20),
                const SizedBox(width: 4),
                Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
              ])
            else
              Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
            const SizedBox(height: 4),
            Text(label.toUpperCase(), style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
          ],
        ),
      ),
    );
  }
}

class _AchievementBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color bgColor;
  final Color iconColor;
  final Color borderColor;
  final bool locked;

  const _AchievementBadge({required this.icon, required this.label, required this.bgColor, required this.iconColor, required this.borderColor, this.locked = false});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Opacity(
        opacity: locked ? 0.5 : 1.0,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(shape: BoxShape.circle, color: iconColor.withValues(alpha: 0.15)),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(height: 8),
              Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}
