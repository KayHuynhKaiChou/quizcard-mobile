import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/study_set_summary.dart';
import '../../data/repositories/explore_repository.dart';
import '../../theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ExploreRepository _exploreRepository = ExploreRepository();
  late Future<List<StudySetSummary>> _recentSetsFuture;

  @override
  void initState() {
    super.initState();
    _recentSetsFuture = _loadRecentSets();
  }

  Future<List<StudySetSummary>> _loadRecentSets() async {
    final page = await _exploreRepository.loadRecent(page: 0, size: 12);
    return page.content;
  }

  void _retry() {
    setState(() {
      _recentSetsFuture = _loadRecentSets();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {},
        ),
        title: const Text('Terminology App'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: FutureBuilder<List<StudySetSummary>>(
        future: _recentSetsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.cloud_off_outlined,
                      color: AppTheme.textSecondaryColor,
                      size: 52,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Khong tai duoc du lieu tu server.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _retry,
                      child: const Text('Thu lai'),
                    ),
                  ],
                ),
              ),
            );
          }

          final recentSets = snapshot.data ?? const <StudySetSummary>[];
          final continueSet = recentSets.isNotEmpty ? recentSets.first : null;

          return SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildGreetingCard(context),
                _buildContinueSection(context, continueSet),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                  child: Text(
                    'Explore Subjects',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                ..._buildDeckList(context, recentSets)
                    .animate(interval: 80.ms)
                    .fadeIn()
                    .slideY(begin: 0.05, end: 0),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildGreetingCard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(40),
              child: Container(
                width: 64,
                height: 64,
                color: AppTheme.primaryColor.withValues(alpha: 0.2),
                child: const Icon(Icons.person, color: AppTheme.primaryColor),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Good Morning, Student!',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.local_fire_department,
                        color: AppTheme.primaryColor,
                        size: 18,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Daily Streak',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.05, end: 0),
    );
  }

  Widget _buildContinueSection(
    BuildContext context,
    StudySetSummary? continueSet,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Text(
            'Continue Learning',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              continueSet?.category ?? 'General',
                              style: const TextStyle(
                                color: AppTheme.primaryColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            continueSet?.title ?? 'No study set yet',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            continueSet != null
                                ? '${continueSet.termsCount} Flashcards'
                                : 'Create or explore study sets',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.menu_book_outlined,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: continueSet == null ? 0 : 0.35,
                    backgroundColor: Colors.white.withValues(alpha: 0.1),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppTheme.primaryColor,
                    ),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => context.go('/decks'),
                    icon: const Icon(Icons.play_arrow, size: 18),
                    label: const Text('Resume Study'),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 200.ms, duration: 500.ms).slideY(
                begin: 0.05,
                end: 0,
              ),
        ),
      ],
    );
  }

  List<Widget> _buildDeckList(
    BuildContext context,
    List<StudySetSummary> sets,
  ) {
    if (sets.isEmpty) {
      return [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Text(
            'Chua co bo the cong khai.',
            style: TextStyle(color: AppTheme.textSecondaryColor),
          ),
        ),
      ];
    }

    return sets.map((set) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: InkWell(
          onTap: () => context.go('/decks'),
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
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: set.authorAvatarUrl ?? '',
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                    placeholder: (ctx, url) => Container(
                      width: 64,
                      height: 64,
                      color: AppTheme.backgroundColor,
                      child: const Icon(Icons.menu_book),
                    ),
                    errorWidget: (ctx, url, err) => Container(
                      width: 64,
                      height: 64,
                      color: AppTheme.backgroundColor,
                      child: const Icon(
                        Icons.image_not_supported,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        set.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${set.termsCount} Terms • ${set.category ?? 'General'}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppTheme.textSecondaryColor),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }
}
