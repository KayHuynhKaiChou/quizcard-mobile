import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../data/models/page_response.dart';
import '../../data/models/study_set_summary.dart';
import '../../data/repositories/study_set_repository.dart';
// import '../../data/repositories/user_repository.dart'; // No longer needed
import '../../data/services/auth_service.dart';
import '../../theme/app_theme.dart';

class StudySetsScreen extends StatefulWidget {
  const StudySetsScreen({super.key});

  @override
  State<StudySetsScreen> createState() => _StudySetsScreenState();
}

class _StudySetsScreenState extends State<StudySetsScreen> {
  late StudySetRepository _studySetRepo;
  Future<PageResponse<StudySetSummary>>? _mySetsFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = context.read<AuthService>();
    _studySetRepo = StudySetRepository(auth);
    _mySetsFuture ??= _studySetRepo.getMyStudySets();
  }

  void _refresh() {
    setState(() {
      _mySetsFuture = _studySetRepo.getMyStudySets();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Study Sets'),
      ),
      body: _buildSetList(_mySetsFuture),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.primaryColor,
        onPressed: () {
          context.push('/create-set').then((_) => _refresh());
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
            return _StudySetCard(set: set, onRefresh: _refresh)
                .animate(delay: Duration(milliseconds: 50 * index))
                .fadeIn()
                .slideY(begin: 0.03);
          },
        );
      },
    );
  }
}

class _StudySetCard extends StatefulWidget {
  final StudySetSummary set;
  final VoidCallback onRefresh;
  const _StudySetCard({required this.set, required this.onRefresh});

  @override
  State<_StudySetCard> createState() => _StudySetCardState();
}

class _StudySetCardState extends State<_StudySetCard> {
  bool _isCloning = false;

  Future<void> _clone() async {
    setState(() => _isCloning = true);
    try {
      final repo = StudySetRepository(context.read<AuthService>());
      final cloned = await repo.cloneStudySet(widget.set.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã clone bộ thẻ thành công!')),
        );
        widget.onRefresh();
        context.push('/study-set/${cloned.id}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi clone: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isCloning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => context.go('/study-set/${widget.set.id}'),
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
                    Text(widget.set.title,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text('${widget.set.termsCount} terms',
                            style: Theme.of(context).textTheme.bodyMedium),
                        if (widget.set.category != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(widget.set.category!,
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
              if (_isCloning)
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppTheme.primaryColor),
                )
              else
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert,
                      color: AppTheme.textSecondaryColor),
                  color: AppTheme.surfaceColor,
                  onSelected: (value) {
                    if (value == 'clone') _clone();
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: 'clone',
                      child: Row(
                        children: [
                          Icon(Icons.copy_outlined,
                              size: 18, color: AppTheme.textPrimaryColor),
                          SizedBox(width: 8),
                          Text('Clone',
                              style:
                                  TextStyle(color: AppTheme.textPrimaryColor)),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
