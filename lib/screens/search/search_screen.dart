import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../data/models/study_set_summary.dart';
import '../../data/repositories/study_set_repository.dart';
import '../../data/services/auth_service.dart';
import '../../theme/app_theme.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late StudySetRepository _repo;
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;

  List<StudySetSummary> _results = [];
  bool _loading = false;
  String? _error;
  String _lastQuery = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _repo = StudySetRepository(context.read<AuthService>());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onQueryChanged(String query) {
    _debounce?.cancel();
    if (query.trim().isEmpty) {
      setState(() {
        _results = [];
        _loading = false;
        _error = null;
        _lastQuery = '';
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _search(query.trim());
    });
  }

  Future<void> _search(String query) async {
    setState(() {
      _loading = true;
      _error = null;
      _lastQuery = query;
    });
    try {
      final page = await _repo.searchStudySets(query: query);
      if (mounted && _lastQuery == query) {
        setState(() {
          _results = page.content;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted && _lastQuery == query) {
        setState(() {
          _error = 'Không thể tải kết quả. Vui lòng thử lại.';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Tìm kiếm bộ thẻ...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: AppTheme.textSecondaryColor),
          ),
          style: const TextStyle(fontSize: 16),
          onChanged: _onQueryChanged,
        ),
        actions: [
          if (_controller.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _controller.clear();
                _onQueryChanged('');
              },
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    final query = _controller.text.trim();

    if (query.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search, size: 64, color: AppTheme.textSecondaryColor),
            SizedBox(height: 16),
            Text(
              'Nhập từ khóa để tìm kiếm',
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.textSecondaryColor,
              ),
            ),
          ],
        ),
      );
    }

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline,
                size: 48, color: AppTheme.textSecondaryColor),
            const SizedBox(height: 12),
            Text(_error!,
                style:
                    const TextStyle(color: AppTheme.textSecondaryColor)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _search(query),
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    if (_results.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off,
                size: 64, color: AppTheme.textSecondaryColor),
            SizedBox(height: 16),
            Text(
              'Không tìm thấy kết quả',
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.textSecondaryColor,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _results.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return _SearchResultCard(set: _results[index]);
      },
    );
  }
}

class _SearchResultCard extends StatefulWidget {
  final StudySetSummary set;
  const _SearchResultCard({required this.set});

  @override
  State<_SearchResultCard> createState() => _SearchResultCardState();
}

class _SearchResultCardState extends State<_SearchResultCard> {
  bool _isCloning = false;

  // Show clone for own sets OR public sets by others; hide for private sets by others.
  bool get _canClone =>
      widget.set.isOwner ||
      widget.set.visibility.toUpperCase() == 'PUBLIC';

  Future<void> _clone() async {
    setState(() => _isCloning = true);
    try {
      final repo = StudySetRepository(context.read<AuthService>());
      final cloned = await repo.cloneStudySet(widget.set.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã clone bộ thẻ thành công!')),
        );
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
    return InkWell(
      onTap: () => context.go('/study-set/${widget.set.id}'),
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
                  Text(
                    widget.set.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  if (widget.set.authorDisplayName != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      widget.set.authorDisplayName!,
                      style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondaryColor,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text('${widget.set.termsCount} thuật ngữ',
                          style: Theme.of(context).textTheme.bodyMedium),
                      if (widget.set.category != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            widget.set.category!,
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
            if (_canClone)
              _isCloning
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppTheme.primaryColor),
                    )
                  : IconButton(
                      icon: const Icon(Icons.copy_outlined,
                          size: 20, color: AppTheme.textSecondaryColor),
                      onPressed: _clone,
                      tooltip: 'Clone',
                    )
            else
              const Icon(Icons.chevron_right,
                  color: AppTheme.textSecondaryColor),
          ],
        ),
      ),
    );
  }
}
