import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/ai_repository.dart';
import '../../data/services/auth_service.dart';
import '../../theme/app_theme.dart';
import 'user_profile_avatar_section.dart';
import 'user_profile_widgets.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  static const List<Map<String, dynamic>> _weeklyActivity = [
    {'day': 'M', 'value': 0.30},
    {'day': 'T', 'value': 0.50},
    {'day': 'W', 'value': 0.80},
    {'day': 'T', 'value': 0.45},
    {'day': 'F', 'value': 0.90, 'isPeak': true},
    {'day': 'S', 'value': 0.60},
    {'day': 'S', 'value': 0.70},
  ];

  late Future<Map<String, dynamic>> _usageFuture;

  // Change password state
  final _currentPasswordCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  bool _isChangingPassword = false;
  bool _showCurrentPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;
  String? _passwordError;

  @override
  void initState() {
    super.initState();
    _usageFuture = AiRepository(context.read<AuthService>()).getUsage();
  }

  @override
  void dispose() {
    _currentPasswordCtrl.dispose();
    _newPasswordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleChangePassword() async {
    final current = _currentPasswordCtrl.text.trim();
    final newPass = _newPasswordCtrl.text.trim();
    final confirm = _confirmPasswordCtrl.text.trim();

    if (current.isEmpty || newPass.isEmpty || confirm.isEmpty) {
      setState(() => _passwordError = 'Vui lòng điền đầy đủ thông tin');
      return;
    }
    if (newPass.length < 8) {
      setState(() => _passwordError = 'Mật khẩu mới phải có ít nhất 8 ký tự');
      return;
    }
    if (newPass != confirm) {
      setState(() => _passwordError = 'Mật khẩu xác nhận không khớp');
      return;
    }

    setState(() {
      _passwordError = null;
      _isChangingPassword = true;
    });

    try {
      await context.read<AuthService>().changePassword(
        currentPassword: current,
        newPassword: newPass,
      );
      if (mounted) {
        _currentPasswordCtrl.clear();
        _newPasswordCtrl.clear();
        _confirmPasswordCtrl.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đổi mật khẩu thành công'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final msg = e.toString().replaceFirst('Exception: ', '');
        setState(() => _passwordError = msg);
      }
    } finally {
      if (mounted) setState(() => _isChangingPassword = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthService>(context).user;

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
                  const AvatarSection(),
                  const SizedBox(height: 16),
                  Text(
                    user?.displayName ?? 'User',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
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
                        Text(
                          'Level 5 Terminology Learner',
                          style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
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
                  StatChip(label: 'Quizzes', value: '24'),
                  const SizedBox(width: 12),
                  StatChip(label: 'Terms', value: '150'),
                  const SizedBox(width: 12),
                  StatChip(
                    label: 'Day Streak',
                    value: '7',
                    icon: Icons.local_fire_department,
                    iconColor: Colors.orange,
                  ),
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
                      Text(
                        'Achievements',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.go('/leaderboard'),
                        child: const Text('View All'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      AchievementBadge(
                        icon: Icons.emoji_events,
                        label: 'Fast Learner',
                        bgColor: const Color(0xFFFEF9C3),
                        iconColor: const Color(0xFFCA8A04),
                        borderColor: const Color(0xFFFDE68A),
                      ),
                      const SizedBox(width: 12),
                      AchievementBadge(
                        icon: Icons.psychology,
                        label: 'Master Mind',
                        bgColor: const Color(0xFFDBEAFE),
                        iconColor: const Color(0xFF2563EB),
                        borderColor: const Color(0xFFBFDAFE),
                      ),
                      const SizedBox(width: 12),
                      AchievementBadge(
                        icon: Icons.lock_outlined,
                        label: 'Vocabulary',
                        bgColor: AppTheme.surfaceColor,
                        iconColor: AppTheme.textSecondaryColor,
                        borderColor: Colors.white.withValues(alpha: 0.08),
                        locked: true,
                      ),
                    ],
                  ),
                ],
              ).animate().fadeIn(delay: 300.ms),
            ),
            const SizedBox(height: 24),

            // Learning Activity Chart
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ActivityChart(weeklyActivity: _weeklyActivity),
            ).animate().fadeIn(delay: 400.ms),
            const SizedBox(height: 24),

            // AI Usage Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: FutureBuilder<Map<String, dynamic>>(
                future: _usageFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const _AiUsageCardSkeleton();
                  }
                  if (snapshot.hasError || !snapshot.hasData) {
                    return const SizedBox.shrink();
                  }
                  final data = snapshot.data!;
                  // Support both {used, limit} and {usedThisMonth, monthlyLimit} formats
                  final used = (data['used'] ?? data['usedThisMonth'] ?? 0) as num;
                  final limit = (data['limit'] ?? data['monthlyLimit'] ?? 0) as num;
                  final ratio = limit > 0 ? (used / limit).clamp(0.0, 1.0).toDouble() : 0.0;
                  return _AiUsageCard(used: used.toInt(), limit: limit.toInt(), ratio: ratio);
                },
              ),
            ).animate().fadeIn(delay: 500.ms),
            const SizedBox(height: 24),

            // Change Password Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _ChangePasswordCard(
                currentPasswordCtrl: _currentPasswordCtrl,
                newPasswordCtrl: _newPasswordCtrl,
                confirmPasswordCtrl: _confirmPasswordCtrl,
                isLoading: _isChangingPassword,
                showCurrentPassword: _showCurrentPassword,
                showNewPassword: _showNewPassword,
                showConfirmPassword: _showConfirmPassword,
                passwordError: _passwordError,
                onToggleCurrentPassword: () =>
                    setState(() => _showCurrentPassword = !_showCurrentPassword),
                onToggleNewPassword: () =>
                    setState(() => _showNewPassword = !_showNewPassword),
                onToggleConfirmPassword: () =>
                    setState(() => _showConfirmPassword = !_showConfirmPassword),
                onSubmit: _handleChangePassword,
              ),
            ).animate().fadeIn(delay: 600.ms),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

/// Skeleton placeholder while AI usage is loading.
class _AiUsageCardSkeleton extends StatelessWidget {
  const _AiUsageCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryColor),
        ),
      ),
    );
  }
}

/// Card showing AI usage with a progress indicator.
class _AiUsageCard extends StatelessWidget {
  final int used;
  final int limit;
  final double ratio;

  const _AiUsageCard({required this.used, required this.limit, required this.ratio});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppTheme.surfaceColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.auto_awesome, color: AppTheme.primaryColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Tính năng AI',
                    style: TextStyle(
                      color: AppTheme.textPrimaryColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    limit > 0
                        ? '$used/$limit lần đã dùng tháng này'
                        : '$used lần đã dùng tháng này',
                    style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 12),
                  ),
                  if (limit > 0) ...[
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: ratio,
                        backgroundColor: AppTheme.backgroundColor,
                        color: ratio >= 0.9 ? AppTheme.errorColor : AppTheme.primaryColor,
                        minHeight: 5,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Card widget for changing password, displayed in the profile screen.
class _ChangePasswordCard extends StatelessWidget {
  final TextEditingController currentPasswordCtrl;
  final TextEditingController newPasswordCtrl;
  final TextEditingController confirmPasswordCtrl;
  final bool isLoading;
  final bool showCurrentPassword;
  final bool showNewPassword;
  final bool showConfirmPassword;
  final String? passwordError;
  final VoidCallback onToggleCurrentPassword;
  final VoidCallback onToggleNewPassword;
  final VoidCallback onToggleConfirmPassword;
  final VoidCallback onSubmit;

  const _ChangePasswordCard({
    required this.currentPasswordCtrl,
    required this.newPasswordCtrl,
    required this.confirmPasswordCtrl,
    required this.isLoading,
    required this.showCurrentPassword,
    required this.showNewPassword,
    required this.showConfirmPassword,
    required this.passwordError,
    required this.onToggleCurrentPassword,
    required this.onToggleNewPassword,
    required this.onToggleConfirmPassword,
    required this.onSubmit,
  });

  InputDecoration _fieldDecoration(
    String label,
    bool obscured,
    VoidCallback onToggle,
  ) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: AppTheme.surfaceColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
      ),
      suffixIcon: IconButton(
        icon: Icon(
          obscured ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          color: AppTheme.textSecondaryColor,
          size: 20,
        ),
        onPressed: onToggle,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'BẢO MẬT',
            style: TextStyle(
              color: AppTheme.textSecondaryColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: currentPasswordCtrl,
            obscureText: !showCurrentPassword,
            decoration: _fieldDecoration(
              'Mật khẩu hiện tại',
              !showCurrentPassword,
              onToggleCurrentPassword,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: newPasswordCtrl,
            obscureText: !showNewPassword,
            decoration: _fieldDecoration(
              'Mật khẩu mới (ít nhất 8 ký tự)',
              !showNewPassword,
              onToggleNewPassword,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: confirmPasswordCtrl,
            obscureText: !showConfirmPassword,
            decoration: _fieldDecoration(
              'Xác nhận mật khẩu mới',
              !showConfirmPassword,
              onToggleConfirmPassword,
            ),
          ),
          if (passwordError != null) ...[
            const SizedBox(height: 10),
            Text(
              passwordError!,
              style: const TextStyle(color: AppTheme.errorColor, fontSize: 13),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isLoading ? null : onSubmit,
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Đổi mật khẩu'),
            ),
          ),
        ],
      ),
    );
  }
}
