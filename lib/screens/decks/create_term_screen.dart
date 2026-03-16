import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';

class CreateTermScreen extends StatefulWidget {
  const CreateTermScreen({super.key});

  @override
  State<CreateTermScreen> createState() => _CreateTermScreenState();
}

class _CreateTermScreenState extends State<CreateTermScreen> {
  final _termController = TextEditingController(text: 'Photosynthesis');
  final _definitionController = TextEditingController(
      text: 'The process by which green plants and some other organisms use sunlight to synthesize foods from carbon dioxide and water.');
  final _exampleController = TextEditingController(
      text: 'Through photosynthesis, the plant produces oxygen as a byproduct.');

  @override
  void dispose() {
    _termController.dispose();
    _definitionController.dispose();
    _exampleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Edit Term'),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Term Name
                  const Text('Term Name', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: AppTheme.textSecondaryColor)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _termController,
                    decoration: const InputDecoration(
                      hintText: 'Enter term name',
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Definition
                  const Text('Definition', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: AppTheme.textSecondaryColor)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _definitionController,
                    minLines: 4, maxLines: 6,
                    decoration: const InputDecoration(hintText: 'Enter definition'),
                  ),
                  const SizedBox(height: 20),

                  // Example Sentence
                  Row(children: [
                    const Text('Example Sentence', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: AppTheme.textSecondaryColor)),
                    const SizedBox(width: 6),
                    Text('(Optional)', style: TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor.withValues(alpha: 0.7))),
                  ]),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _exampleController,
                    minLines: 3, maxLines: 5,
                    decoration: const InputDecoration(hintText: 'Enter example sentence'),
                  ),
                  const SizedBox(height: 20),

                  // Upload Image
                  InkWell(
                    onTap: () {},
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.15), style: BorderStyle.solid, width: 1.5),
                        color: AppTheme.surfaceColor,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.image_outlined, color: AppTheme.primaryColor),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Upload Image', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                                SizedBox(height: 2),
                                Text('PNG, JPG up to 5MB', style: TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor)),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right, color: AppTheme.textSecondaryColor),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Delete
                  SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      onPressed: () => context.go('/decks'),
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      label: const Text('Delete Term', style: TextStyle(color: Colors.red)),
                      style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                    ),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
          // Sticky Save Button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.backgroundColor,
              border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => context.go('/decks'),
                icon: const Icon(Icons.save_outlined),
                label: const Text('Save Term', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
