import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../data/models/study_set_models.dart';
import '../../data/repositories/study_set_repository.dart';
import '../../data/services/auth_service.dart';
import '../../theme/app_theme.dart';

// ── View mode enum ─────────────────────────────────────────────────────────

enum _ViewMode { flashcard, grid }

// ── Screen ─────────────────────────────────────────────────────────────────

class StudySetDetailScreen extends StatefulWidget {
  final String studySetId;
  const StudySetDetailScreen({super.key, required this.studySetId});

  @override
  State<StudySetDetailScreen> createState() => _StudySetDetailScreenState();
}

class _StudySetDetailScreenState extends State<StudySetDetailScreen> {
  late StudySetRepository _repo;
  late Future<_StudySetData> _dataFuture;

  // State
  _ViewMode _viewMode = _ViewMode.flashcard;
  int _currentIndex = 0;
  bool _showTermFirst = true;
  bool _isShuffled = false;
  List<Term> _shuffledTerms = [];
  final Set<String> _learnedIds = {};

  // Clone/delete state
  bool _isCloning = false;
  bool _isDeleting = false;

  // Search state
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;
  String _searchQuery = '';
  String _searchField = 'term';
  List<Term> _searchResults = [];
  int _searchCursor = 0;
  bool _searchHasMore = false;
  bool _isSearching = false;
  bool _isSearchLoadingMore = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _repo = StudySetRepository(context.read<AuthService>());
    _dataFuture = _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<_StudySetData> _loadData() async {
    final detail = await _repo.getById(widget.studySetId);
    final termsPage = await _repo.getTerms(widget.studySetId, limit: 50);
    return _StudySetData(detail: detail, terms: termsPage.content);
  }

  List<Term> _activeTerms(_StudySetData data) {
    if (_isShuffled && _shuffledTerms.isNotEmpty) return _shuffledTerms;
    return data.terms;
  }

  void _toggleShuffle(_StudySetData data) {
    setState(() {
      if (_isShuffled) {
        _isShuffled = false;
        _shuffledTerms = [];
      } else {
        final list = List<Term>.from(data.terms);
        final rng = Random();
        for (int i = list.length - 1; i > 0; i--) {
          final j = rng.nextInt(i + 1);
          final tmp = list[i];
          list[i] = list[j];
          list[j] = tmp;
        }
        _shuffledTerms = list;
        _isShuffled = true;
      }
      _currentIndex = 0;
    });
  }

  void _toggleFlipOrder() => setState(() => _showTermFirst = !_showTermFirst);

  void _toggleLearned(Term current) {
    setState(() {
      if (_learnedIds.contains(current.id)) {
        _learnedIds.remove(current.id);
      } else {
        _learnedIds.add(current.id);
      }
    });
  }

  void _previous() {
    if (_currentIndex > 0) setState(() => _currentIndex--);
  }

  void _next(List<Term> terms) {
    if (_currentIndex < terms.length - 1) setState(() => _currentIndex++);
  }

  void _retry() {
    setState(() {
      _dataFuture = _loadData();
    });
  }

  Future<void> _cloneStudySet() async {
    setState(() => _isCloning = true);
    try {
      final cloned = await _repo.cloneStudySet(widget.studySetId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã clone bộ thẻ thành công!')),
        );
        context.pushReplacement('/study-set/${cloned.id}');
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

  Future<void> _deleteStudySet() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: const Text('Xóa bộ thẻ?'),
        content: const Text(
            'Xóa bộ thẻ này? Các thuật ngữ sẽ bị xóa theo.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Hủy',
                style: TextStyle(color: AppTheme.textSecondaryColor)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Xóa',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _isDeleting = true);
    try {
      await _repo.delete(widget.studySetId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xóa bộ thẻ')),
        );
        context.canPop() ? context.pop() : context.go('/studyset');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi xóa: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      if (value == _searchQuery) return;
      setState(() {
        _searchQuery = value;
        _searchResults = [];
        _searchCursor = 0;
        _searchHasMore = false;
      });
      if (value.isNotEmpty) _runSearch(reset: true);
    });
  }

  void _onSearchFieldChanged(String field) {
    setState(() {
      _searchField = field;
      _searchResults = [];
      _searchCursor = 0;
      _searchHasMore = false;
    });
    if (_searchQuery.isNotEmpty) _runSearch(reset: true);
  }

  Future<void> _runSearch({bool reset = false}) async {
    if (reset) {
      setState(() => _isSearching = true);
    } else {
      setState(() => _isSearchLoadingMore = true);
    }
    try {
      final page = await _repo.searchTerms(
        widget.studySetId,
        query: _searchQuery,
        field: _searchField,
        cursor: reset ? 0 : _searchCursor,
        limit: 20,
      );
      setState(() {
        if (reset) {
          _searchResults = page.content;
        } else {
          _searchResults = [..._searchResults, ...page.content];
        }
        _searchCursor = page.nextCursor ?? 0;
        _searchHasMore = page.hasMore;
        _isSearching = false;
        _isSearchLoadingMore = false;
      });
    } catch (_) {
      setState(() {
        _isSearching = false;
        _isSearchLoadingMore = false;
      });
    }
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _searchResults = [];
      _searchCursor = 0;
      _searchHasMore = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: FocusNode()..requestFocus(),
      onKeyEvent: (event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.arrowLeft) _previous();
          // next is handled after data is available
        }
      },
      child: Scaffold(
        body: FutureBuilder<_StudySetData>(
          future: _dataFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return _buildError();
            }
            final data = snapshot.data!;
            return _buildContent(data);
          },
        ),
      ),
    );
  }

  // ── Search bar ─────────────────────────────────────────────────────────

  Widget _buildSearchBar() {
    return Container(
      color: AppTheme.backgroundColor,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 44,
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Tìm thuật ngữ...',
                  prefixIcon: const Icon(Icons.search, size: 18,
                      color: AppTheme.textSecondaryColor),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? GestureDetector(
                          onTap: _clearSearch,
                          child: const Icon(Icons.close, size: 18,
                              color: AppTheme.textSecondaryColor),
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  filled: true,
                  fillColor: AppTheme.surfaceColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppTheme.primaryColor),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Field picker
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            alignment: Alignment.center,
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _searchField,
                isDense: true,
                style: const TextStyle(
                    fontSize: 13, color: AppTheme.textPrimaryColor),
                dropdownColor: AppTheme.surfaceColor,
                icon: const Icon(Icons.arrow_drop_down, color: AppTheme.textSecondaryColor, size: 20),
                items: const [
                  DropdownMenuItem(value: 'term', child: Text('Thuật ngữ')),
                  DropdownMenuItem(value: 'definition', child: Text('Định nghĩa')),
                ],
                onChanged: (v) {
                  if (v != null) _onSearchFieldChanged(v);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Search results ──────────────────────────────────────────────────────

  Widget _buildSearchResults(bool isOwner) {
    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_searchResults.isEmpty) {
      return const Center(
        child: Text(
          'Không tìm thấy kết quả.',
          style: TextStyle(color: AppTheme.textSecondaryColor),
        ),
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        if (n is ScrollEndNotification &&
            n.metrics.pixels >= n.metrics.maxScrollExtent - 80 &&
            _searchHasMore &&
            !_isSearchLoadingMore) {
          _runSearch();
        }
        return false;
      },
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        itemCount: _searchResults.length + (_searchHasMore ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          if (index == _searchResults.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(8),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          }
          final t = _searchResults[index];
          return _TermGridCard(
            term: t,
            onEdit: isOwner
                ? () async {
                    final result = await context.push<bool>(
                        '/study-set/${widget.studySetId}/term-edit',
                        extra: t);
                    if (result == true) _retry();
                  }
                : null,
          );
        },
      ),
    );
  }

  // ── Error state ────────────────────────────────────────────────────────

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_outlined,
                color: AppTheme.textSecondaryColor, size: 52),
            const SizedBox(height: 12),
            const Text('Không tải được study set.',
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _retry, child: const Text('Thử lại')),
          ],
        ),
      ),
    );
  }

  // ── Main content ───────────────────────────────────────────────────────

  Widget _buildContent(_StudySetData data) {
    final detail = data.detail;
    final terms = _activeTerms(data);
    final currentTerm = terms.isNotEmpty ? terms[_currentIndex] : null;
    final isLearned = currentTerm != null && _learnedIds.contains(currentTerm.id);

    return SafeArea(
      child: Column(
        children: [
          _buildHeader(context, detail, detail.isOwner),
          _buildViewToggle(),
          _buildSearchBar(),
          if (_searchQuery.isNotEmpty)
            Expanded(child: _buildSearchResults(detail.isOwner))
          else if (_viewMode == _ViewMode.flashcard)
            Expanded(child: _buildFlashcardSection(data, terms, currentTerm, isLearned))
          else
            Expanded(child: _buildGridSection(terms, detail.isOwner)),
        ],
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context, StudySetDetail detail, bool isOwner) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () =>
                    context.canPop() ? context.pop() : context.go('/home'),
              ),
              Expanded(child: const SizedBox()),
              // Add term button — owner only
              if (isOwner)
                TextButton.icon(
                  onPressed: () async {
                    final result = await context.push<bool>('/study-set/${widget.studySetId}/term-edit');
                    if (result == true) _retry();
                  },
                  icon: const Icon(Icons.add, size: 16, color: AppTheme.primaryColor),
                  label: const Text('Thêm từ', style: TextStyle(color: AppTheme.primaryColor)),
                ),
              // Quiz button
              TextButton.icon(
                onPressed: () => context.go('/quiz/${widget.studySetId}'),
                icon: const Icon(Icons.play_arrow,
                    size: 16, color: AppTheme.primaryColor),
                label: const Text(
                  'Quiz',
                  style: TextStyle(color: AppTheme.primaryColor),
                ),
              ),
              // Clone / more menu
              if (_isCloning || _isDeleting)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  ),
                )
              else
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert,
                      color: AppTheme.textSecondaryColor),
                  color: AppTheme.surfaceColor,
                  onSelected: (value) {
                    if (value == 'clone') _cloneStudySet();
                    if (value == 'delete') _deleteStudySet();
                  },
                  itemBuilder: (_) {
                    // Clone is visible for own sets OR public sets by others.
                    // Hide clone for private sets owned by others.
                    final canClone = isOwner ||
                        detail.visibility.toUpperCase() == 'PUBLIC';
                    return [
                      if (canClone)
                        const PopupMenuItem(
                          value: 'clone',
                          child: Row(
                            children: [
                              Icon(Icons.copy_outlined,
                                  size: 18, color: AppTheme.textPrimaryColor),
                              SizedBox(width: 8),
                              Text('Clone bộ thẻ này',
                                  style: TextStyle(
                                      color: AppTheme.textPrimaryColor)),
                            ],
                          ),
                        ),
                      if (isOwner)
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline,
                                  size: 18, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Xóa bộ thẻ',
                                  style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                    ];
                  },
                ),
              const SizedBox(width: 4),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
            child: Text(
              detail.title,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                Text(
                  '${detail.termsCount} thuật ngữ',
                  style: const TextStyle(
                      color: AppTheme.textSecondaryColor, fontSize: 13),
                ),
                if (detail.category != null) ...[
                  const SizedBox(width: 10),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      detail.category!,
                      style: const TextStyle(
                          color: AppTheme.primaryColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
                const SizedBox(width: 10),
                const Icon(Icons.person_outline,
                    size: 14, color: AppTheme.textSecondaryColor),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    detail.authorName,
                    style: const TextStyle(
                        color: AppTheme.textSecondaryColor, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          if (detail.description != null && detail.description!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Text(
                detail.description!,
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }

  // ── View Toggle (Flashcard / Grid) ─────────────────────────────────────

  Widget _buildViewToggle() {
    return Container(
      color: AppTheme.backgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: _ViewToggleButton(
              label: 'Flashcard',
              icon: Icons.style_outlined,
              isSelected: _viewMode == _ViewMode.flashcard,
              onTap: () => setState(() => _viewMode = _ViewMode.flashcard),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _ViewToggleButton(
              label: 'Danh sách',
              icon: Icons.grid_view_outlined,
              isSelected: _viewMode == _ViewMode.grid,
              onTap: () => setState(() => _viewMode = _ViewMode.grid),
            ),
          ),
        ],
      ),
    );
  }

  // ── Flashcard section ──────────────────────────────────────────────────

  Widget _buildFlashcardSection(
      _StudySetData data, List<Term> terms, Term? currentTerm, bool isLearned) {
    if (terms.isEmpty) {
      return const Center(
        child: Text('Chưa có thuật ngữ nào.',
            style: TextStyle(color: AppTheme.textSecondaryColor)),
      );
    }

    return Column(
      children: [
        // Controls toolbar
        _buildControlsToolbar(data, isLearned, currentTerm),

        // Progress bar
        _buildProgressBar(terms),

        // Flashcard
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: currentTerm != null
                ? _FlashCard(
                    key: ValueKey('${currentTerm.id}_$_showTermFirst'),
                    term: currentTerm,
                    showTermFirst: _showTermFirst,
                  ).animate().fadeIn(duration: 180.ms)
                : const SizedBox(),
          ),
        ),

        // Navigation controls
        _buildNavigationControls(terms),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildControlsToolbar(
      _StudySetData data, bool isLearned, Term? currentTerm) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          _ToolbarButton(
            icon: _isShuffled ? Icons.shuffle_on_outlined : Icons.shuffle,
            label: _isShuffled ? 'Bỏ trộn' : 'Trộn',
            isActive: _isShuffled,
            onTap: () => _toggleShuffle(data),
          ),
          _ToolbarButton(
            icon: Icons.swap_horiz,
            label: _showTermFirst ? 'Thuật ngữ trước' : 'Nghĩa trước',
            onTap: _toggleFlipOrder,
          ),
          if (currentTerm != null)
            _ToolbarButton(
              icon: isLearned
                  ? Icons.check_circle
                  : Icons.radio_button_unchecked,
              label: isLearned ? 'Đã thuộc' : 'Đánh dấu',
              isActive: isLearned,
              onTap: () => _toggleLearned(currentTerm),
            ),
          const Spacer(),
          if (_learnedIds.isNotEmpty)
            Text(
              '${_learnedIds.length}/${data.detail.termsCount} thuộc',
              style: const TextStyle(
                  color: AppTheme.primaryColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600),
            ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(List<Term> terms) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${_currentIndex + 1} / ${terms.length}',
              style: const TextStyle(
                  color: AppTheme.textSecondaryColor, fontSize: 12),
            ),
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: terms.isEmpty ? 0 : (_currentIndex + 1) / terms.length,
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              valueColor: const AlwaysStoppedAnimation(AppTheme.primaryColor),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationControls(List<Term> terms) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton.outlined(
            icon: const Icon(Icons.chevron_left),
            onPressed: _currentIndex == 0 ? null : _previous,
            padding: const EdgeInsets.all(12),
          ),
          Text(
            'Tap thẻ để lật',
            style: const TextStyle(
                color: AppTheme.textSecondaryColor, fontSize: 12),
          ),
          IconButton.outlined(
            icon: const Icon(Icons.chevron_right),
            onPressed:
                _currentIndex == terms.length - 1 ? null : () => _next(terms),
            padding: const EdgeInsets.all(12),
          ),
        ],
      ),
    );
  }

  // ── Grid section ───────────────────────────────────────────────────────

  Widget _buildGridSection(List<Term> terms, bool isOwner) {
    if (terms.isEmpty) {
      return const Center(
        child: Text('Chưa có thuật ngữ nào.',
            style: TextStyle(color: AppTheme.textSecondaryColor)),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: terms.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final t = terms[index];
        return _TermGridCard(
          term: t,
          onEdit: isOwner
              ? () async {
                  final result = await context.push<bool>('/study-set/${widget.studySetId}/term-edit', extra: t);
                  if (result == true) _retry();
                }
              : null,
        )
            .animate()
            .fadeIn(delay: Duration(milliseconds: 40 * index))
            .slideY(begin: 0.03, end: 0);
      },
    );
  }
}

// ── Sub-widgets ────────────────────────────────────────────────────────────

class _ViewToggleButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ViewToggleButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: 200.ms,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor.withValues(alpha: 0.15)
              : AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryColor.withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 16,
                color: isSelected
                    ? AppTheme.primaryColor
                    : AppTheme.textSecondaryColor),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected
                    ? AppTheme.primaryColor
                    : AppTheme.textSecondaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isActive;

  const _ToolbarButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(icon,
          size: 15,
          color: isActive
              ? AppTheme.primaryColor
              : AppTheme.textSecondaryColor),
      label: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: isActive
              ? AppTheme.primaryColor
              : AppTheme.textSecondaryColor,
        ),
      ),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}

// ── Flip flashcard widget ──────────────────────────────────────────────────

class _FlashCard extends StatefulWidget {
  final Term term;
  final bool showTermFirst;

  const _FlashCard({super.key, required this.term, required this.showTermFirst});

  @override
  State<_FlashCard> createState() => _FlashCardState();
}

class _FlashCardState extends State<_FlashCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _frontRotation;
  late Animation<double> _backRotation;
  bool _isFront = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));
    _frontRotation = TweenSequence([
      TweenSequenceItem(
          tween: Tween(begin: 0.0, end: pi / 2)
              .chain(CurveTween(curve: Curves.easeIn)),
          weight: 50),
      TweenSequenceItem(tween: ConstantTween(pi / 2), weight: 50),
    ]).animate(_controller);
    _backRotation = TweenSequence([
      TweenSequenceItem(tween: ConstantTween(pi / 2), weight: 50),
      TweenSequenceItem(
          tween: Tween(begin: pi / 2, end: 0.0)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 50),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _flip() {
    if (_isFront) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
    setState(() => _isFront = !_isFront);
  }

  @override
  Widget build(BuildContext context) {
    final frontText =
        widget.showTermFirst ? widget.term.term : widget.term.definition;
    final backText =
        widget.showTermFirst ? widget.term.definition : widget.term.term;
    final frontLabel = widget.showTermFirst ? 'THUẬT NGỮ' : 'ĐỊNH NGHĨA';
    final backLabel = widget.showTermFirst ? 'ĐỊNH NGHĨA' : 'THUẬT NGỮ';

    return GestureDetector(
      onTap: _flip,
      child: Stack(
        children: [
          // Front face
          AnimatedBuilder(
            animation: _frontRotation,
            builder: (_, child) => Transform(
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateY(_frontRotation.value),
              alignment: Alignment.center,
              child: _frontRotation.value <= pi / 2 ? child : const SizedBox(),
            ),
            child: _CardFace(label: frontLabel, text: frontText,
                isBack: false,
                ipa: widget.showTermFirst ? widget.term.ipa : null,
                example: widget.showTermFirst ? null : widget.term.exampleSentence),
          ),
          // Back face
          AnimatedBuilder(
            animation: _backRotation,
            builder: (_, child) => Transform(
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateY(_backRotation.value),
              alignment: Alignment.center,
              child: _backRotation.value >= pi / 2 ? const SizedBox() : child,
            ),
            child: _CardFace(label: backLabel, text: backText,
                isBack: true,
                ipa: !widget.showTermFirst ? widget.term.ipa : null,
                example: !widget.showTermFirst ? null : widget.term.exampleSentence),
          ),
        ],
      ),
    );
  }
}

class _CardFace extends StatelessWidget {
  final String label;
  final String text;
  final String? ipa;
  final String? example;
  final bool isBack;

  const _CardFace(
      {required this.label, required this.text, this.ipa, this.example, this.isBack = false});

  @override
  Widget build(BuildContext context) {
    // Front: indigo→purple  |  Back: pink→red  (matching Angular client)
    final gradient = isBack
        ? const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF093FB), Color(0xFFF5576C)],
          )
        : const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
          );

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    text,
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                  if (ipa != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      ipa!,
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 16,
                          fontStyle: FontStyle.italic),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  if (example != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      example!,
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8), fontSize: 14, fontStyle: FontStyle.italic),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ),
          // Label top-left
          Positioned(
            top: 16,
            left: 20,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.75),
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
          ),
          // Flip hint bottom-right
          Positioned(
            bottom: 16,
            right: 20,
            child: Row(
              children: [
                Icon(Icons.touch_app_outlined,
                    size: 13, color: Colors.white.withValues(alpha: 0.7)),
                const SizedBox(width: 4),
                Text(
                  'Tap to flip',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7), fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Term grid card ─────────────────────────────────────────────────────────


class _TermGridCard extends StatelessWidget {
  final Term term;
  final VoidCallback? onEdit;

  const _TermGridCard({
    required this.term,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  term.term,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 15),
                ),
                if (term.ipa != null) ...[
                  const SizedBox(height: 2),
                  Text(term.ipa!,
                      style: const TextStyle(
                          color: AppTheme.primaryColor,
                          fontSize: 12,
                          fontStyle: FontStyle.italic)),
                ],
                const SizedBox(height: 6),
                Divider(height: 1, color: Colors.white.withValues(alpha: 0.06)),
                const SizedBox(height: 6),
                Text(
                  term.definition,
                  style: const TextStyle(
                      color: AppTheme.textSecondaryColor, fontSize: 13),
                ),
                if (term.exampleSentence != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    term.exampleSentence!,
                    style: const TextStyle(
                        color: AppTheme.textSecondaryColor,
                        fontSize: 12,
                        fontStyle: FontStyle.italic),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          if (onEdit != null) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onEdit,
              child: const Icon(Icons.edit_outlined, color: AppTheme.textSecondaryColor, size: 20),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Data holder ─────────────────────────────────────────────────────────────

class _StudySetData {
  final StudySetDetail detail;
  final List<Term> terms;
  const _StudySetData({required this.detail, required this.terms});
}
