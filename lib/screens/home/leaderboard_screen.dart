import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Global Leaderboard'),
        leading: const BackButton(),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Top 3 Podium
            Container(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppTheme.primaryColor.withValues(alpha: 0.1), Colors.transparent],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // 2nd Place
              _buildTopEntry(
                    context,
                    rank: 2,
                    name: 'Sarah M.',
                    xp: '10,500 XP',
                    avatarUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuDb-ybrEXM4q5c4dvHeZ3S7d9QCYcSFav6MGTzDAMt1rkFxJM0eBdUimNxS76kLCrkSLpIAm1t-Rh8Tqfi3a3KPLXY9TOj2rBUi4z5dlGNDglZW7auHKjz9alUWOnAhi-pQhNTnnKwteHc7Yck-1ZKFwXOmNWNcv5agUyCMxznnbyjsJRCQ-xmgZ7HWkZx-kA8Gl-QkjHOh0BpRfyeN3qSitRLHa1RQwPCpveID0gC08ie0V2FLBHC7RksF0X3qAXeKQ8QKso8RBjBV',
                    borderColor: const Color(0xFFA8C5DA),
                    badgeColor: const Color(0xFF6B8FA8),
                    avatarSize: 64,
                    extraBottomPadding: 16,
                  ),
                  const SizedBox(width: 16),
                  // 1st Place
              _buildTopEntry(
                    context,
                    rank: 1,
                    name: 'Alex D.',
                    xp: '12,450 XP',
                    avatarUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuDfzV4GJEpXXkZmnSInGTmJ7eWUidPeXUkWfLCOuClbI8_OgI8zYLaC-Vdgnu_e84UeiM2Sg4T_XT7Hj9N1Y_egeVRdUIo5OPPfTDQk-pBhU1BJ70Zu5HTQoJQzW9emNm8S3ciHy7i6Hk8qJYBs471-CkjQasDVCFBnZdfk1mGhCZyRiSSTP-XSZoXp-F9XZaxQ8__bgk_ReLhIbDG8fcGSlP6zqyjS70etMkMRuJ01B_uNQ8TDGCOJc1avndo-sNIWYYIoSm_aKQyZ',
                    borderColor: const Color(0xFFFBBF24),
                    badgeColor: const Color(0xFFF59E0B),
                    avatarSize: 96,
                    showCrown: true,
                  ),
                  const SizedBox(width: 16),
                  // 3rd Place
              _buildTopEntry(
                    context,
                    rank: 3,
                    name: 'John K.',
                    xp: '9,800 XP',
                    avatarUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuDCkscFBQFQpBCQ7EMYWKPfzJMrKNiab3cqIDbtklgoLfV9ep1QGNNxK0q_boQ5cv5ZHA2jkGDU_QulbKIFRW5U9W-8FUk8KxIfMtdSCfSwqvLV5DE5dA-ZlheG6XZxWTVYN-C2EwkrRRj8sTWJTf5P3s-YfgCxU8pQIbfW4TlD-2-KR4p-xpnHdWEeKCDQ_mgoRHDF62CwwbZrZrRsVoAevqwMXj8wdwiz6wfjc3BNIyzVdlWxTXC_2p9v2KBh5Ps5ImUcJAD6UsFP',
                    borderColor: const Color(0xFFB45309),
                    badgeColor: const Color(0xFF92400E),
                    avatarSize: 56,
                    extraBottomPadding: 32,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Current user rank
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 24, child: Text('42', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor))),
                    const SizedBox(width: 16),
                    CircleAvatar(radius: 20, backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.2), child: const Icon(Icons.person, color: AppTheme.primaryColor)),
                    const SizedBox(width: 12),
                    const Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('You', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('Current Rank', style: TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor)),
                      ],
                    )),
                    const Text('3,200 XP', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                  ],
                ),
              ).animate().fadeIn(delay: 400.ms),
            ),
            const SizedBox(height: 12),

            // Other entries
            ..._buildLeaderboardList(context),
          ],
        ),
      ),
    );
  }

  Widget _buildTopEntry(BuildContext context, {
    required int rank, required String name, required String xp,
    required String avatarUrl, required Color borderColor,
    required Color badgeColor, required double avatarSize,
    bool showCrown = false, double extraBottomPadding = 0,
  }) {
    return InkWell(
      onTap: () => context.go('/public_profile'),
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
        if (showCrown) const Icon(Icons.workspace_premium, color: Color(0xFFEAB308), size: 36),
        SizedBox(
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(avatarSize),
                child: CachedNetworkImage(
                  imageUrl: avatarUrl, width: avatarSize, height: avatarSize, fit: BoxFit.cover,
                  placeholder: (ctx, url) => CircleAvatar(radius: avatarSize / 2, backgroundColor: AppTheme.surfaceColor),
                  errorWidget: (ctx, url, err) => CircleAvatar(radius: avatarSize / 2, backgroundColor: AppTheme.surfaceColor, child: const Icon(Icons.person)),
                ),
              ),
              Container(
                width: avatarSize, height: avatarSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: borderColor, width: 3),
                ),
              ),
              Positioned(
                bottom: -12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(color: badgeColor, borderRadius: BorderRadius.circular(20)),
                  child: Text('$rank', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: extraBottomPadding + 20),
        Text(name, style: TextStyle(fontWeight: rank == 1 ? FontWeight.bold : FontWeight.w500, fontSize: rank == 1 ? 15 : 13)),
        Text(xp, style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 13)),
      ],
      ),
    );
  }

  List<Widget> _buildLeaderboardList(BuildContext context) {
    final entries = [
      {'rank': '4', 'name': 'Emily R.', 'xp': '9,500'},
      {'rank': '5', 'name': 'Michael T.', 'xp': '9,200'},
      {'rank': '6', 'name': 'Jessica L.', 'xp': '8,950'},
      {'rank': '7', 'name': 'David W.', 'xp': '8,700'},
    ];

    return entries.map((e) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: () => context.go('/public_profile'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              SizedBox(width: 28, child: Text(e['rank']!, style: const TextStyle(color: AppTheme.textSecondaryColor, fontWeight: FontWeight.w500))),
              const SizedBox(width: 12),
              CircleAvatar(radius: 20, backgroundColor: AppTheme.surfaceColor, child: const Icon(Icons.person, color: AppTheme.textSecondaryColor, size: 20)),
              const SizedBox(width: 12),
              Expanded(child: Text(e['name']!, style: const TextStyle(fontWeight: FontWeight.w500))),
              Text('${e['xp']} XP', style: const TextStyle(fontWeight: FontWeight.w500, color: AppTheme.textPrimaryColor)),
            ],
          ),
        ),
      ).animate().fadeIn(delay: Duration(milliseconds: 100 * int.parse(e['rank']!))).slideX(begin: 0.05, end: 0),
    )).toList();
  }
}
