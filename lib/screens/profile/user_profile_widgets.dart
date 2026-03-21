import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Weekly bar chart for learning activity.
class ActivityChart extends StatelessWidget {
  final List<Map<String, dynamic>> weeklyActivity;

  const ActivityChart({super.key, required this.weeklyActivity});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Learning Activity',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
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
            children: weeklyActivity.map((data) {
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
                              color: isPeak
                                  ? AppTheme.primaryColor
                                  : AppTheme.primaryColor.withValues(alpha: 0.25),
                              borderRadius:
                                  const BorderRadius.vertical(top: Radius.circular(4)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        data['day'] as String,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isPeak ? FontWeight.bold : FontWeight.w400,
                          color: isPeak ? AppTheme.primaryColor : AppTheme.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

/// Compact stat display chip used in profile screen.
class StatChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;
  final Color? iconColor;

  const StatChip({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.iconColor,
  });

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
                Text(value,
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor)),
              ])
            else
              Text(value,
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor)),
            const SizedBox(height: 4),
            Text(
              label.toUpperCase(),
              style: const TextStyle(
                color: AppTheme.textSecondaryColor,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Achievement badge tile used in the achievements section.
class AchievementBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color bgColor;
  final Color iconColor;
  final Color borderColor;
  final bool locked;

  const AchievementBadge({
    super.key,
    required this.icon,
    required this.label,
    required this.bgColor,
    required this.iconColor,
    required this.borderColor,
    this.locked = false,
  });

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
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: iconColor.withValues(alpha: 0.15),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(height: 8),
              Text(label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}
