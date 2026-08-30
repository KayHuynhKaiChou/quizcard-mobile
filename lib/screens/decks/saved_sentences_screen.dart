import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';

import '../../data/models/sentence_models.dart';
import '../../data/repositories/saved_sentence_repository.dart';
import '../../data/services/auth_service.dart';
import '../../theme/app_theme.dart';

const _pageSize = 20;

/// Lists every sentence the user kept, newest first. Independent of study sets.
class SavedSentencesScreen extends StatefulWidget {
  const SavedSentencesScreen({super.key});

  @override
  State<SavedSentencesScreen> createState() => _SavedSentencesScreenState();
}

class _SavedSentencesScreenState extends State<SavedSentencesScreen> {
  late SavedSentenceRepository _repo;

  final List<SavedSentence> _items = [];
  int _page = 0;
  bool _hasMore = false;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _repo = SavedSentenceRepository(context.read<AuthService>());
    _loadFirstPage();
  }

  Future<void> _loadFirstPage() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final page = await _repo.getSaved(page: 0, size: _pageSize);
      if (!mounted) return;
      setState(() {
        _items
          ..clear()
          ..addAll(page.content);
        _page = 0;
        _hasMore = page.number + 1 < page.totalPages;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Không tải được câu đã lưu';
      });
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);
    try {
      final page = await _repo.getSaved(page: _page + 1, size: _pageSize);
      if (!mounted) return;
      setState(() {
        _items.addAll(page.content);
        _page = page.number;
        _hasMore = page.number + 1 < page.totalPages;
        _isLoadingMore = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingMore = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không tải thêm được')),
      );
    }
  }

  Future<void> _confirmDelete(SavedSentence item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Xóa câu này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await _repo.delete(item.id);
      if (!mounted) return;
      setState(() => _items.removeWhere((s) => s.id == item.id));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã xóa câu')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không xóa được câu')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Câu đã lưu')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_outlined,
                color: AppTheme.textSecondaryColor, size: 48),
            const SizedBox(height: 12),
            Text(_error!),
            const SizedBox(height: 12),
            ElevatedButton(
                onPressed: _loadFirstPage, child: const Text('Thử lại')),
          ],
        ),
      );
    }

    if (_items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.chat_bubble_outline,
                  color: AppTheme.textSecondaryColor.withValues(alpha: 0.5),
                  size: 64),
              const SizedBox(height: 16),
              const Text('Chưa có câu nào được lưu',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
              const SizedBox(height: 8),
              const Text(
                'Mở một thẻ từ vựng và bấm nút câu ví dụ để bắt đầu.',
                textAlign: TextAlign.center,
                style:
                    TextStyle(color: AppTheme.textSecondaryColor, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadFirstPage,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _items.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _items.length) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: _isLoadingMore
                    ? const CircularProgressIndicator()
                    : OutlinedButton(
                        onPressed: _loadMore,
                        child: const Text('Tải thêm'),
                      ),
              ),
            );
          }

          final item = _items[index];
          return _SavedSentenceCard(
            item: item,
            onDelete: () => _confirmDelete(item),
          )
              .animate(delay: Duration(milliseconds: 40 * index))
              .fadeIn()
              .slideY(begin: 0.03);
        },
      ),
    );
  }
}

class _SavedSentenceCard extends StatelessWidget {
  final SavedSentence item;
  final VoidCallback onDelete;

  const _SavedSentenceCard({required this.item, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Slidable(
        key: ValueKey(item.id),
        endActionPane: ActionPane(
          motion: const ScrollMotion(),
          extentRatio: 0.2,
          children: [
            CustomSlidableAction(
              onPressed: (_) => onDelete(),
              backgroundColor: Colors.transparent,
              foregroundColor: AppTheme.errorColor,
              child: const Icon(Icons.delete_outline, size: 26),
            ),
          ],
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  item.word,
                  style: const TextStyle(
                    color: AppTheme.primaryColor,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(item.sentence,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600, height: 1.4)),
              if (item.translation != null) ...[
                const SizedBox(height: 6),
                Text(item.translation!,
                    style: const TextStyle(
                        color: AppTheme.textSecondaryColor,
                        fontSize: 13,
                        height: 1.4)),
              ],
              if (item.createdAt != null) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined,
                        size: 12, color: AppTheme.textSecondaryColor),
                    const SizedBox(width: 5),
                    Text(
                      _formatDate(item.createdAt!),
                      style: const TextStyle(
                          color: AppTheme.textSecondaryColor, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final local = dt.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/${local.year}';
  }
}
