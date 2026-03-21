import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../data/services/auth_service.dart';
import '../../data/repositories/user_repository.dart';
import '../../theme/app_theme.dart';

/// DiceBear preset avatar options shown in selection dialog.
const List<Map<String, String>> kAvatarPresets = [
  {'url': 'https://api.dicebear.com/9.x/avataaars/svg?seed=alpha&backgroundColor=b6e3f4', 'label': 'Avatar 1'},
  {'url': 'https://api.dicebear.com/9.x/avataaars/svg?seed=beta&backgroundColor=c0aede', 'label': 'Avatar 2'},
  {'url': 'https://api.dicebear.com/9.x/lorelei/svg?seed=gamma&backgroundColor=d1d4f9', 'label': 'Avatar 3'},
  {'url': 'https://api.dicebear.com/9.x/lorelei/svg?seed=delta&backgroundColor=ffd5dc', 'label': 'Avatar 4'},
  {'url': 'https://api.dicebear.com/9.x/bottts/svg?seed=epsilon&backgroundColor=b6e3f4', 'label': 'Avatar 5'},
  {'url': 'https://api.dicebear.com/9.x/bottts/svg?seed=zeta&backgroundColor=c0aede', 'label': 'Avatar 6'},
  {'url': 'https://api.dicebear.com/9.x/pixel-art/svg?seed=eta', 'label': 'Avatar 7'},
  {'url': 'https://api.dicebear.com/9.x/pixel-art/svg?seed=theta', 'label': 'Avatar 8'},
  {'url': 'https://api.dicebear.com/9.x/thumbs/svg?seed=iota&backgroundColor=b6e3f4', 'label': 'Avatar 9'},
  {'url': 'https://api.dicebear.com/9.x/thumbs/svg?seed=kappa&backgroundColor=c0aede', 'label': 'Avatar 10'},
  {'url': 'https://api.dicebear.com/9.x/fun-emoji/svg?seed=lambda', 'label': 'Avatar 11'},
  {'url': 'https://api.dicebear.com/9.x/fun-emoji/svg?seed=mu', 'label': 'Avatar 12'},
];

/// Determines whether a URL points to an SVG image (e.g. DiceBear).
bool _isSvgUrl(String url) =>
    url.contains('dicebear') || url.endsWith('.svg');

/// Circular avatar widget that supports SVG and raster images.
class AvatarImage extends StatelessWidget {
  final String? url;
  final double size;

  const AvatarImage({super.key, required this.url, this.size = 110});

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) {
      return Icon(Icons.person, size: size * 0.55, color: AppTheme.textSecondaryColor);
    }
    if (_isSvgUrl(url!)) {
      return SvgPicture.network(
        url!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholderBuilder: (_) => const Center(child: CircularProgressIndicator()),
      );
    }
    return CachedNetworkImage(
      imageUrl: url!,
      width: size,
      height: size,
      fit: BoxFit.cover,
      placeholder: (_, __) => Container(color: AppTheme.surfaceColor),
      errorWidget: (_, __, ___) =>
          Icon(Icons.person, size: size * 0.55, color: AppTheme.textSecondaryColor),
    );
  }
}

/// Avatar section with edit button; handles pick/upload and preset selection.
class AvatarSection extends StatefulWidget {
  const AvatarSection({super.key});

  @override
  State<AvatarSection> createState() => _AvatarSectionState();
}

class _AvatarSectionState extends State<AvatarSection> {
  bool _isLoading = false;

  void _showAvatarOptions() {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.upload),
              title: const Text('Tải ảnh lên'),
              onTap: () { Navigator.pop(context); _pickAndUploadImage(); },
            ),
            ListTile(
              leading: const Icon(Icons.grid_view),
              title: const Text('Chọn avatar có sẵn'),
              onTap: () { Navigator.pop(context); _showAvatarPresets(); },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (picked == null) return;
    setState(() => _isLoading = true);
    try {
      final bytes = await picked.readAsBytes();
      final mimeType = picked.mimeType ?? 'image/jpeg';
      final authService = Provider.of<AuthService>(context, listen: false);
      final userRepo = UserRepository(authService);
      final updated = await userRepo.uploadAvatar(
        fileBytes: bytes,
        fileName: picked.name,
        mimeType: mimeType,
      );
      await authService.updateUser(updated);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showAvatarPresets() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Chọn avatar'),
        content: SizedBox(
          width: 300,
          height: 400,
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: kAvatarPresets.length,
            itemBuilder: (_, i) {
              final preset = kAvatarPresets[i];
              return GestureDetector(
                onTap: () async {
                  Navigator.pop(ctx);
                  await _selectPresetAvatar(preset['url']!);
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SvgPicture.network(
                    preset['url']!,
                    placeholderBuilder: (_) =>
                        const Center(child: CircularProgressIndicator()),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _selectPresetAvatar(String url) async {
    setState(() => _isLoading = true);
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final userRepo = UserRepository(authService);
      final updated = await userRepo.updateMe(avatarUrl: url);
      await authService.updateUser(updated);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthService>(context).user;
    return GestureDetector(
      onTap: _isLoading ? null : _showAvatarOptions,
      child: Stack(
        children: [
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppTheme.primaryColor.withValues(alpha: 0.3),
                width: 4,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(60),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : AvatarImage(url: user?.avatarUrl),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: AppTheme.primaryColor,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.edit, size: 16, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
