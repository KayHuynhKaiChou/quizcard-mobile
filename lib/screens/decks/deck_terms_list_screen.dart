import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';

class DeckTermsListScreen extends StatelessWidget {
  const DeckTermsListScreen({super.key});

  static const List<Map<String, dynamic>> _terms = [
    {'term': 'Anatomy', 'def': 'The study of the structure of the human body and the relationship of its parts to each other.', 'starred': true},
    {'term': 'Physiology', 'def': 'The study of the normal function of living organisms and their parts, including physical and chemical processes.', 'starred': false},
    {'term': 'Pathology', 'def': 'The study of the causes and effects of disease or injury, focusing on changes in structure and function.', 'starred': false},
    {'term': 'Pharmacology', 'def': 'The branch of medicine concerned with the uses, effects, and modes of action of drugs.', 'starred': false},
    {'term': 'Histology', 'def': 'The microscopic study of the structure of tissues and cells.', 'starred': true},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header Bar
            Container(
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/home')),
                      IconButton(icon: const Icon(Icons.more_vert), onPressed: () => context.go('/create_term')),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Text(
                      'Medical Terminology',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            // Header Info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'A comprehensive deck covering essential medical terms and definitions. Perfect for pre-med students and healthcare professionals.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.style_outlined, size: 18, color: AppTheme.textSecondaryColor),
                      const SizedBox(width: 4),
                      const Text('124 Cards', style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 13)),
                      const SizedBox(width: 16),
                      const Icon(Icons.person_outline, size: 18, color: AppTheme.textSecondaryColor),
                      const SizedBox(width: 4),
                      const Text('Dr. Smith', style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 13)),
                    ],
                  ),
                ],
              ),
            ),
            // Terms List
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Terms', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              ),
            ),
            Expanded(
              child: ListView.separated(
                itemCount: _terms.length,
                separatorBuilder: (a, b) => Divider(height: 1, color: Colors.white.withValues(alpha: 0.08)),
                itemBuilder: (context, index) {
                  final term = _terms[index];
                  return TermListItem(
                    key: ValueKey(index),
                    term: term['term'] as String,
                    definition: term['def'] as String,
                    isStarred: term['starred'] as bool,
                    onTap: () => context.go('/create_term'),
                  ).animate().fadeIn(delay: Duration(milliseconds: 60 * index)).slideX(begin: 0.02, end: 0);
                },
              ),
            ),
          ],
        ),
      ),
      // Floating Start Studying Button
      floatingActionButton: SizedBox(
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: ElevatedButton.icon(
            onPressed: () => context.go('/study'),
            icon: const Icon(Icons.play_arrow),
            label: const Text('Start Studying'),
            style: ElevatedButton.styleFrom(
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

class TermListItem extends StatelessWidget {
  final String term;
  final String definition;
  final bool isStarred;
  final VoidCallback onTap;

  const TermListItem({super.key, required this.term, required this.definition, required this.isStarred, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(term, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                  const SizedBox(height: 4),
                  Text(definition, style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              isStarred ? Icons.star : Icons.star_border,
              color: isStarred ? AppTheme.primaryColor : AppTheme.textSecondaryColor,
            ),
          ],
        ),
      ),
    );
  }
}
