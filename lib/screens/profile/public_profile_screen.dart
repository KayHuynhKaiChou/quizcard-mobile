import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../data/models/public_profile_model.dart';
import '../../data/models/study_set_summary.dart';
import '../../data/repositories/user_repository.dart';
import '../../data/services/auth_service.dart';
import '../../theme/app_theme.dart';

class PublicProfileScreen extends StatefulWidget {
  final String userId;

  const PublicProfileScreen({super.key, required this.userId});

  @override
  State<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen> {
  late UserRepository _userRepo;

  PublicProfileModel? _profile;
  final List<StudySetSummary> _studySets = [];
  bool _isLoadingProfile = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _errorMessage;
  int _currentPage = 0;
  static const int _pageSize = 12;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _userRepo = UserRepository(context.read<AuthService>());
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoadingProfile = true;
      _errorMessage = null;
    });
    try {
      final profile = await _userRepo.getPublicProfile(widget.userId);
      final setsPage = await _userRepo.getUserPublicStudySets(
        widget.userId,
        page: 0,
        size: _pageSize,
      );
      if (mounted) {
        setState(() {
          _profile = profile;
          _studySets
            ..clear()
            ..addAll(setsPage.content);
          _currentPage = 0;
          _hasMore = setsPage.number < setsPage.totalPages - 1;
          _isLoadingProfile = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load profile. Please try again.';
          _isLoadingProfile = false;
        });
      }
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);
    try {
      final nextPage = _currentPage + 1;
      final setsPage = await _userRepo.getUserPublicStudySets(
        widget.userId,
        page: nextPage,
        size: _pageSize,
      );
      if (mounted) {
        setState(() {
          _studySets.addAll(setsPage.content);
          _currentPage = nextPage;
          _hasMore = setsPage.number < setsPage.totalPages - 1;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go('/home'),
        ),
        title: Text(_profile?.displayName ?? 'Profile'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadInitialData,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoadingProfile) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppTheme.textSecondaryColor),
              const SizedBox(height: 16),
              Text(_errorMessage!, textAlign: TextAlign.center,
                  style: const TextStyle(color: AppTheme.textSecondaryColor)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadInitialData,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    if (_profile == null) return const SizedBox();

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProfileHeader(_profile!),
          const SizedBox(height: 24),
          _buildStatsRow(_profile!),
          const SizedBox(height: 24),
          _buildStudySetsSection(),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(PublicProfileModel profile) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
      ),
      child: Column(
        children: [
          // Avatar
          ClipRRect(
            borderRadius: BorderRadius.circular(64),
            child: profile.avatarUrl != null
                ? CachedNetworkImage(
                    imageUrl: profile.avatarUrl!,
                    width: 96,
                    height: 96,
                    fit: BoxFit.cover,
                    placeholder: (ctx, url) => _avatarPlaceholder(),
                    errorWidget: (ctx, url, err) => _avatarPlaceholder(),
                  )
                : _avatarPlaceholder(),
          ),
          const SizedBox(height: 16),
          Text(
            profile.displayName,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          if (profile.bio != null && profile.bio!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              profile.bio!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 14),
            ),
          ],
          const SizedBox(height: 6),
          Text(
            'Joined ${_formatJoinDate(profile.createdAt)}',
            style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 13),
          ),
          const SizedBox(height: 20),
          // Follow / Message — disabled placeholders (deferred)
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    disabledBackgroundColor: AppTheme.primaryColor.withValues(alpha: 0.3),
                    disabledForegroundColor: Colors.white.withValues(alpha: 0.4),
                  ),
                  child: const Text('Follow', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: null,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(
                      color: AppTheme.primaryColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Text('Message', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ).animate().fadeIn(duration: 400.ms),
    );
  }

  Widget _avatarPlaceholder() {
    return Container(
      width: 96,
      height: 96,
      color: AppTheme.backgroundColor,
      child: const Icon(Icons.person, size: 48, color: AppTheme.textSecondaryColor),
    );
  }

  Widget _buildStatsRow(PublicProfileModel profile) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _StatCard(
            icon: Icons.bolt,
            label: 'Streak',
            value: '${profile.streakCount}',
            color: Colors.orange,
          ),
          const SizedBox(width: 12),
          _StatCard(
            icon: Icons.emoji_events,
            label: 'XP',
            value: '${profile.xpPoints}',
            color: Colors.blue,
          ),
          const SizedBox(width: 12),
          _StatCard(
            icon: Icons.trending_up,
            label: 'Level',
            value: '${profile.level}',
            color: AppTheme.primaryColor,
          ),
        ],
      ).animate().fadeIn(delay: 200.ms),
    );
  }

  Widget _buildStudySetsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Public Study Sets (${_profile!.publicStudySetCount})',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (_studySets.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('No public study sets yet.',
                    style: TextStyle(color: AppTheme.textSecondaryColor)),
              ),
            )
          else
            ..._studySets.asMap().entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _ProfileStudySetCard(set: entry.value)
                    .animate()
                    .fadeIn(delay: Duration(milliseconds: 50 * entry.key))
                    .slideY(begin: 0.04, end: 0),
              );
            }),
          if (_hasMore)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: _isLoadingMore
                    ? const CircularProgressIndicator()
                    : OutlinedButton.icon(
                        onPressed: _loadMore,
                        icon: const Icon(Icons.expand_more, size: 18),
                        label: const Text('Load more'),
                      ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatJoinDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
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
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: AppTheme.textSecondaryColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileStudySetCard extends StatelessWidget {
  final StudySetSummary set;

  const _ProfileStudySetCard({required this.set});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/study-set/${set.id}'),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.style, color: AppTheme.primaryColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    set.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text('${set.termsCount} terms',
                          style: Theme.of(context).textTheme.bodyMedium),
                      if (set.category != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            set.category!,
                            style: const TextStyle(
                                color: AppTheme.primaryColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppTheme.textSecondaryColor),
          ],
        ),
      ),
    );
  }
}
