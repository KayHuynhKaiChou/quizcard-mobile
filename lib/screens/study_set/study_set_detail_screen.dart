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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _repo = StudySetRepository(context.read<AuthService>());
    _dataFuture = _loadData();
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
          _buildHeader(context, detail),
          _buildViewToggle(),
          if (_viewMode == _ViewMode.flashcard)
            Expanded(child: _buildFlashcardSection(data, terms, currentTerm, isLearned))
          else
            Expanded(child: _buildGridSection(terms, detail.isOwner)),
        ],
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context, StudySetDetail detail) {
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
              // Quiz button
              if (detail.isOwner)
                TextButton.icon(
                  onPressed: () async {
                    final result = await context.push<bool>('/study-set/${widget.studySetId}/term-edit');
                    if (result == true) _retry();
                  },
                  icon: const Icon(Icons.add, size: 16, color: AppTheme.primaryColor),
                  label: const Text('Thêm từ', style: TextStyle(color: AppTheme.primaryColor)),
                ),
              TextButton.icon(
                onPressed: () => context.go('/quiz/${widget.studySetId}'),
                icon: const Icon(Icons.play_arrow,
                    size: 16, color: AppTheme.primaryColor),
                label: const Text(
                  'Quiz',
                  style: TextStyle(color: AppTheme.primaryColor),
                ),
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
          isLearned: _learnedIds.contains(t.id),
          onToggleLearned: () => _toggleLearned(t),
          onEdit: isOwner ? () async {
            final result = await context.push<bool>('/study-set/${widget.studySetId}/term-edit', extra: t);
            if (result == true) _retry();
          } : null,
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
  final bool isLearned;
  final VoidCallback onToggleLearned;
  final VoidCallback? onEdit;

  const _TermGridCard({
    required this.term,
    required this.isLearned,
    required this.onToggleLearned,
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
          color: isLearned
              ? AppTheme.primaryColor.withValues(alpha: 0.4)
              : Colors.white.withValues(alpha: 0.08),
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
          const SizedBox(width: 8),
          Column(
            children: [
              if (onEdit != null)
                GestureDetector(
                  onTap: onEdit,
                  child: const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: Icon(Icons.edit_outlined, color: AppTheme.textSecondaryColor, size: 20),
                  ),
                ),
              GestureDetector(
                onTap: onToggleLearned,
                child: Icon(
                  isLearned ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: isLearned
                      ? AppTheme.primaryColor
                      : AppTheme.textSecondaryColor,
                  size: 22,
                ),
              ),
            ],
          ),
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
