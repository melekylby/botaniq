import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/post.dart';
import '../providers/community_provider.dart';
import '../services/photo_storage_service.dart';
import '../theme/app_colors.dart';
import '../widgets/my_plant_photo.dart';

/// Yeni topluluk gönderisi oluşturma formu.
class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  static Future<void> open(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CreatePostScreen()),
    );
  }

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  static const _minLength = 10;
  static const _maxLength = 1000;

  final _formKey = GlobalKey<FormState>();
  final _imagePicker = ImagePicker();
  late final TextEditingController _nameController;
  final _contentController = TextEditingController();

  PostTag _tag = PostTag.question;
  String? _photoPath;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Daha önce kaydedilmiş adı hazır getir.
    _nameController = TextEditingController(
      text: context.read<CommunityProvider>().userName,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Fotoğraf çek'),
              onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Galeriden seç'),
              onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;

    try {
      final file = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1200,
        imageQuality: 80,
      );
      if (file != null) setState(() => _photoPath = file.path);
    } catch (error) {
      _showMessage('Fotoğraf alınamadı. Kamera veya galeri iznini kontrol et.');
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final provider = context.read<CommunityProvider>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    try {
      await provider.setUserName(_nameController.text);
      final photoName = _photoPath == null
          ? null
          : await PhotoStorageService.instance.savePhoto(_photoPath!);
      await provider.addPost(
        tag: _tag,
        content: _contentController.text.trim(),
        photoName: photoName,
      );
      navigator.pop();
      messenger.showSnackBar(
        const SnackBar(content: Text('Gönderin paylaşıldı 🌿')),
      );
    } catch (error) {
      debugPrint('Gönderi paylaşılamadı: $error');
      if (!mounted) return;
      setState(() => _isSaving = false);
      _showMessage('Gönderi paylaşılamadı. Lütfen tekrar dene.');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Yeni Gönderi')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          children: [
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Topluluktaki adın',
                hintText: CommunityProvider.defaultUserName,
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Gönderi türü',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            SegmentedButton<PostTag>(
              showSelectedIcon: false,
              segments: [
                for (final tag in PostTag.values)
                  ButtonSegment(value: tag, label: Text(tag.label)),
              ],
              selected: {_tag},
              onSelectionChanged: (selection) =>
                  setState(() => _tag = selection.first),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _contentController,
              minLines: 5,
              maxLines: 10,
              maxLength: _maxLength,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: switch (_tag) {
                  PostTag.question => 'Sorunu anlat',
                  PostTag.experience => 'Deneyimini paylaş',
                  PostTag.tip => 'İpucunu yaz',
                },
                hintText: 'ör. Bitkimin yaprakları neden sararıyor?',
                alignLabelWithHint: true,
              ),
              validator: (value) {
                final text = value?.trim() ?? '';
                if (text.length < _minLength) {
                  return 'Biraz daha ayrıntı yaz (en az $_minLength karakter).';
                }
                return null;
              },
            ),
            const SizedBox(height: 8),
            if (_photoPath == null)
              OutlinedButton.icon(
                onPressed: _pickPhoto,
                icon: const Icon(Icons.add_photo_alternate_outlined),
                label: const Text('Fotoğraf ekle (isteğe bağlı)'),
              )
            else
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: SizedBox(
                  height: 200,
                  child: Stack(
                    children: [
                      Positioned.fill(child: MyPlantPhoto(filePath: _photoPath)),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: IconButton.filled(
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white.withValues(alpha: 0.92),
                            foregroundColor: AppColors.darkGreen,
                          ),
                          tooltip: 'Fotoğrafı kaldır',
                          icon: const Icon(Icons.close),
                          onPressed: () => setState(() => _photoPath = null),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: FilledButton(
            onPressed: _isSaving ? null : _submit,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Paylaş'),
          ),
        ),
      ),
    );
  }
}
