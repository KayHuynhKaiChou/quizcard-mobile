import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/study_set_summary.dart';
import '../../data/repositories/explore_repository.dart';
import '../../theme/app_theme.dart';

class GlobalStatsScreen extends StatefulWidget {
  const GlobalStatsScreen({super.key});

  @override
  State<GlobalStatsScreen> createState() => _GlobalStatsScreenState();
}

class _GlobalStatsScreenState extends State<GlobalStatsScreen> {
  static const List<Map<String, dynamic>> _weeklyData = [
    {'day': 'M', 'value': 0.30},
    {'day': 'T', 'value': 0.10},
    {'day': 'W', 'value': 0.70},
    {'day': 'T', 'value': 0.20},
    {'day': 'F', 'value': 0.80},
    {'day': 'S', 'value': 1.00, 'isPeak': true},
    {'day': 'S', 'value': 0.90},
  ];

  final ExploreRepository _exploreRepository = ExploreRepository();
  late Future<_ExploreData> _exploreDataFuture;

  @override
  void initState() {
    super.initState();
    _exploreDataFuture = _loadExploreData();
  }

  Future<_ExploreData> _loadExploreData() async {
    final trending = await _exploreRepository.loadTrending(page: 0, size: 6);
    final categories = await _exploreRepository.loadCategories();
    return _ExploreData(
      trendingSets: trending.content,
      categories: categories,
    );
  }

  void _retry() {
    setState(() {
      _exploreDataFuture = _loadExploreData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Explore')),
      body: FutureBuilder<_ExploreData>(
        future: _exploreDataFuture,
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
                      'Khong tai duoc Explore data.',
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

          final data = snapshot.data ??
              const _ExploreData(
                trendingSets: <StudySetSummary>[],
                categories: <String>[],
              );

          return SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildGlobalActivityCard(context),
                if (data.categories.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: data.categories
                          .take(8)
                          .map(
                            (c) => Chip(
                              label: Text(c),
                              labelStyle: const TextStyle(
                                color: AppTheme.textPrimaryColor,
                              ),
                              backgroundColor: AppTheme.surfaceColor,
                              side: BorderSide(
                                color: Colors.white.withValues(alpha: 0.08),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Most Popular Decks',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      TextButton(
                        onPressed: () => context.go('/decks'),
                        child: const Text('View All'),
                      ),
                    ],
                  ),
                ),
                ..._buildTrendingDecks(context, data.trendingSets),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildGlobalActivityCard(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Text(
            'Global Learning Activity',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
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
                  'Active Learners',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text(
                      '1.2M',
                      style:
                          TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF064E3B).withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.trending_up,
                            color: Color(0xFF34D399),
                            size: 16,
                          ),
                          SizedBox(width: 4),
                          Text(
                            '+15%',
                            style: TextStyle(
                              color: Color(0xFF34D399),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 160,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: _weeklyData.map((data) {
                      final isPeak = data['isPeak'] == true;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (isPeak)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  margin: const EdgeInsets.only(bottom: 4),
                                  decoration: BoxDecoration(
                                    color: AppTheme.surfaceColor,
                                    borderRadius: BorderRadius.circular(4),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black
                                            .withValues(alpha: 0.2),
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                  child: const Text(
                                    'Peak',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              Expanded(
                                child: FractionallySizedBox(
                                  alignment: Alignment.bottomCenter,
                                  heightFactor: data['value'] as double,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: isPeak
                                          ? AppTheme.primaryColor
                                          : AppTheme.primaryColor
                                              .withValues(alpha: 0.25),
                                      borderRadius:
                                          const BorderRadius.vertical(
                                        top: Radius.circular(4),
                                      ),
                                      boxShadow: isPeak
                                          ? [
                                              BoxShadow(
                                                color: AppTheme.primaryColor
                                                    .withValues(alpha: 0.4),
                                                blurRadius: 8,
                                              ),
                                            ]
                                          : null,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                data['day'] as String,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isPeak
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                  color: isPeak
                                      ? AppTheme.textPrimaryColor
                                      : AppTheme.textSecondaryColor,
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
            ),
          ).animate().fadeIn(duration: 500.ms),
        ),
      ],
    );
  }

  List<Widget> _buildTrendingDecks(
    BuildContext context,
    List<StudySetSummary> decks,
  ) {
    if (decks.isEmpty) {
      return [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Text(
            'Khong co du lieu trending.',
            style: TextStyle(color: AppTheme.textSecondaryColor),
          ),
        ),
      ];
    }

    return decks.asMap().entries.map((entry) {
      final index = entry.key;
      final deck = entry.value;
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
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        deck.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            deck.authorDisplayName ?? 'Unknown author',
                            style: const TextStyle(
                              color: AppTheme.textSecondaryColor,
                              fontSize: 12,
                            ),
                          ),
                          Container(
                            width: 4,
                            height: 4,
                            margin: const EdgeInsets.symmetric(horizontal: 6),
                            decoration: const BoxDecoration(
                              color: AppTheme.textSecondaryColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          Text(
                            deck.category ?? 'General',
                            style: const TextStyle(
                              color: AppTheme.textSecondaryColor,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    const Icon(
                      Icons.favorite,
                      color: Colors.red,
                      size: 22,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      deck.cloneCount.toString(),
                      style: const TextStyle(
                        color: AppTheme.textSecondaryColor,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        )
            .animate()
            .fadeIn(delay: 100.ms * (index + 1))
            .slideY(begin: 0.05, end: 0),
      );
    }).toList();
  }
}

class _ExploreData {
  final List<StudySetSummary> trendingSets;
  final List<String> categories;

  const _ExploreData({
    required this.trendingSets,
    required this.categories,
  });
}
