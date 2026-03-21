import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../data/models/study_set_summary.dart';
import '../../data/repositories/explore_repository.dart';
import '../../data/repositories/study_set_repository.dart';
import '../../data/services/auth_service.dart';
import '../../theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late ExploreRepository _exploreRepo;
  late StudySetRepository _studySetRepo;

  Future<List<StudySetSummary>>? _mySetsFuture;
  Future<List<StudySetSummary>>? _trendingFuture;
  Future<List<StudySetSummary>>? _recentFuture;
  Future<List<String>>? _categoriesFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = context.read<AuthService>();
    _exploreRepo = ExploreRepository();
    _studySetRepo = StudySetRepository(auth);
    _loadAll();
  }

  void _loadAll() {
    _mySetsFuture ??=
        _studySetRepo.getMyStudySets(size: 3).then((p) => p.content);
    _trendingFuture ??=
        _exploreRepo.loadTrending(size: 3).then((p) => p.content);
    _recentFuture ??= _exploreRepo.loadRecent(size: 3).then((p) => p.content);
    _categoriesFuture ??= _exploreRepo.loadCategories().catchError((_) => <String>[]);
  }

  Future<void> _refresh() async {
    setState(() {
      _mySetsFuture =
          _studySetRepo.getMyStudySets(size: 3).then((p) => p.content);
      _trendingFuture =
          _exploreRepo.loadTrending(size: 3).then((p) => p.content);
      _recentFuture = _exploreRepo.loadRecent(size: 3).then((p) => p.content);
      _categoriesFuture = _exploreRepo.loadCategories().catchError((_) => <String>[]);
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().user;
    final displayName = user?.displayName ?? 'Student';
    // Mocks since actual User model might not have XP and streak directly mapped in currentUser getter
    final streakCount = 7;
    final xpPoints = 1250;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Terminology App'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHero(displayName, streakCount, xpPoints),
              const SizedBox(height: 16),
              _buildMySetsSection(),
              const SizedBox(height: 24),
              _buildTrendingSection(),
              const SizedBox(height: 24),
              _buildRecentSection(),
              const SizedBox(height: 24),
              _buildCategoriesSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHero(String displayName, int streak, int xp) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Chào mừng, $displayName!',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildStatBadge(Icons.bolt, '$streak', 'Streak', Colors.orange),
                const SizedBox(width: 12),
                _buildStatBadge(Icons.emoji_events, '$xp', 'XP', Colors.blue),
              ],
            ),
          ],
        ),
      ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0),
    );
  }

  Widget _buildStatBadge(
      IconData icon, String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: color)),
                Text(label,
                    style:
                        TextStyle(fontSize: 11, color: color.withValues(alpha: 0.8))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMySetsSection() {
    return _buildSection(
      title: 'Bộ thẻ của bạn',
      actionText: 'Xem tất cả',
      onAction: () => context.go('/studyset'),
      future: _mySetsFuture,
      emptyIcon: Icons.menu_book,
      emptyTitle: 'Chưa có bộ thẻ nào',
      emptyMessage: 'Hãy tạo bộ thẻ đầu tiên để bắt đầu học!',
      emptyAction: () => context.push('/create-set').then((_) => _refresh()),
      emptyActionText: 'Tạo bộ thẻ',
    );
  }

  Widget _buildTrendingSection() {
    return _buildSection(
      title: 'Bộ thẻ thịnh hành',
      titleIcon: Icons.bolt,
      titleIconColor: Colors.orange,
      future: _trendingFuture,
      emptyTitle: 'Chưa có bộ thẻ thịnh hành nào',
      showAuthor: true,
    );
  }

  Widget _buildRecentSection() {
    return _buildSection(
      title: 'Bộ thẻ mới nhất',
      titleIcon: Icons.schedule,
      titleIconColor: Colors.blue,
      future: _recentFuture,
      emptyTitle: 'Chưa có bộ thẻ mới nào',
      showAuthor: true,
    );
  }

  Widget _buildSection({
    required String title,
    IconData? titleIcon,
    Color? titleIconColor,
    String? actionText,
    VoidCallback? onAction,
    required Future<List<StudySetSummary>>? future,
    String? emptyTitle,
    String? emptyMessage,
    IconData? emptyIcon,
    VoidCallback? emptyAction,
    String? emptyActionText,
    bool showAuthor = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  if (titleIcon != null) ...[
                    Icon(titleIcon, color: titleIconColor, size: 20),
                    const SizedBox(width: 8),
                  ],
                  Text(title,
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold, fontSize: 18)),
                ],
              ),
              if (actionText != null && onAction != null)
                TextButton(
                  onPressed: onAction,
                  child: Row(
                    children: [
                      Text(actionText),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_forward, size: 16),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        FutureBuilder<List<StudySetSummary>>(
          future: future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                  height: 100,
                  child: Center(child: CircularProgressIndicator()));
            }
            if (snapshot.hasError) {
              return const SizedBox(
                  height: 100, child: Center(child: Text('Lỗi tải dữ liệu')));
            }

            final items = snapshot.data ?? [];
            if (items.isEmpty) {
              if (emptyAction != null) {
                // Return interactive empty state
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08)),
                    ),
                    child: Column(
                      children: [
                        if (emptyIcon != null)
                          Icon(emptyIcon,
                              size: 40, color: AppTheme.textSecondaryColor),
                        const SizedBox(height: 12),
                        Text(emptyTitle ?? 'Trống',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        if (emptyMessage != null) ...[
                          const SizedBox(height: 4),
                          Text(emptyMessage,
                              style: const TextStyle(
                                  color: AppTheme.textSecondaryColor),
                              textAlign: TextAlign.center),
                        ],
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: emptyAction,
                          icon: const Icon(Icons.add, size: 18),
                          label: Text(emptyActionText ?? 'Thêm'),
                        ),
                      ],
                    ),
                  ),
                );
              } else {
                // Simple empty text
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(emptyTitle ?? 'Trống',
                      style:
                          const TextStyle(color: AppTheme.textSecondaryColor)),
                );
              }
            }

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: items.map((set) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _StudySetCard(set: set, showAuthor: showAuthor),
                  );
                }).toList(),
              ).animate().fadeIn(duration: 300.ms),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCategoriesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Icon(Icons.category, color: Colors.purpleAccent, size: 20),
              const SizedBox(width: 8),
              Text('Danh mục phổ biến',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        FutureBuilder<List<String>>(
          future: _categoriesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: CircularProgressIndicator(),
              );
            }
            final categories = snapshot.data ?? [];
            if (categories.isEmpty) return const SizedBox();

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: categories.map((cat) {
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.bookmark_outline,
                            size: 14, color: AppTheme.textSecondaryColor),
                        const SizedBox(width: 6),
                        Text(cat, style: const TextStyle(fontSize: 13)),
                      ],
                    ),
                  );
                }).toList(),
              ).animate().fadeIn(duration: 400.ms),
            );
          },
        ),
      ],
    );
  }
}

class _StudySetCard extends StatelessWidget {
  final StudySetSummary set;
  final bool showAuthor;
  const _StudySetCard({required this.set, this.showAuthor = false});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.go('/study-set/${set.id}'),
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
            if (showAuthor)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: set.authorAvatarUrl ?? '',
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  placeholder: (ctx, url) => Container(
                    width: 56,
                    height: 56,
                    color: AppTheme.backgroundColor,
                  ),
                  errorWidget: (ctx, url, err) => Container(
                    width: 56,
                    height: 56,
                    color: AppTheme.backgroundColor,
                    child: const Icon(Icons.person,
                        color: AppTheme.textSecondaryColor),
                  ),
                ),
              )
            else
              Container(
                width: 56,
                height: 56,
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
                  Text(set.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  if (showAuthor && set.authorDisplayName != null) ...[
                    const SizedBox(height: 2),
                    Text(set.authorDisplayName!,
                        style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondaryColor,
                            fontWeight: FontWeight.w500)),
                  ],
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text('${set.termsCount} thẻ',
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
                          child: Text(set.category!,
                              style: const TextStyle(
                                  color: AppTheme.primaryColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600)),
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
