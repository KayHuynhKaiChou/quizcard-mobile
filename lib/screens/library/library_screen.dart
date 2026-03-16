import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../data/models/page_response.dart';
import '../../data/models/study_set_summary.dart';
import '../../data/repositories/study_set_repository.dart';
import '../../data/repositories/user_repository.dart';
import '../../data/services/auth_service.dart';
import '../../theme/app_theme.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  late StudySetRepository _studySetRepo;
  late UserRepository _userRepo;

  Future<PageResponse<StudySetSummary>>? _mySetsFuture;
  Future<PageResponse<StudySetSummary>>? _bookmarksFuture;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = context.read<AuthService>();
    _studySetRepo = StudySetRepository(auth);
    _userRepo = UserRepository(auth);
    _mySetsFuture ??= _studySetRepo.getMyStudySets();
    _bookmarksFuture ??= _userRepo.getBookmarks();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  void _refresh() {
    setState(() {
      _mySetsFuture = _studySetRepo.getMyStudySets();
      _bookmarksFuture = _userRepo.getBookmarks();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Library'),
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: AppTheme.primaryColor,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: AppTheme.textSecondaryColor,
          tabs: const [
            Tab(text: 'My Sets'),
            Tab(text: 'Bookmarked'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _buildSetList(_mySetsFuture),
          _buildSetList(_bookmarksFuture),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.primaryColor,
        onPressed: () {
          // TODO: Navigate to create study set
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildSetList(Future<PageResponse<StudySetSummary>>? future) {
    if (future == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return FutureBuilder<PageResponse<StudySetSummary>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.cloud_off_outlined,
                    color: AppTheme.textSecondaryColor, size: 48),
                const SizedBox(height: 12),
                const Text('Failed to load data'),
                const SizedBox(height: 12),
                ElevatedButton(onPressed: _refresh, child: const Text('Retry')),
              ],
            ),
          );
        }

        final sets = snapshot.data?.content ?? [];
        if (sets.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.library_books_outlined,
                    color: AppTheme.textSecondaryColor, size: 48),
                const SizedBox(height: 12),
                Text('No study sets yet',
                    style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: sets.length,
          itemBuilder: (context, index) {
            final set = sets[index];
            return _StudySetCard(set: set)
                .animate(delay: Duration(milliseconds: 50 * index))
                .fadeIn()
                .slideY(begin: 0.03);
          },
        );
      },
    );
  }
}

class _StudySetCard extends StatelessWidget {
  final StudySetSummary set;
  const _StudySetCard({required this.set});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          // TODO: navigate to study set detail
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.menu_book_outlined,
                    color: AppTheme.primaryColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(set.title,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text('${set.termsCount} terms',
                            style: Theme.of(context).textTheme.bodyMedium),
                        if (set.category != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color:
                                  AppTheme.primaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(set.category!,
                                style: const TextStyle(
                                    color: AppTheme.primaryColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right,
                  color: AppTheme.textSecondaryColor),
            ],
          ),
        ),
      ),
    );
  }
}
