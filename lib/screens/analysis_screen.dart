import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/analysis_result.dart';
import '../services/plant_analysis_service.dart';
import '../theme/app_colors.dart';
import '../widgets/analysis_result_view.dart';

/// Ekranın içinde bulunabileceği durumlar.
enum _AnalysisStatus { idle, ready, loading, success, error }

/// Bitki Analizi: fotoğraf çek/seç → analiz et → sonucu göster.
///
/// Analiz durumu yalnızca bu ekranı ilgilendirdiği için Provider yerine
/// ekranın kendi State'inde tutuluyor. Sekmeler IndexedStack içinde
/// olduğundan başka sekmeye geçip dönünce sonuç kaybolmaz.
class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  final _imagePicker = ImagePicker();
  final _analysisService = PlantAnalysisService();

  _AnalysisStatus _status = _AnalysisStatus.idle;
  String? _photoPath;
  AnalysisResult? _result;
  String? _errorMessage;

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final file = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1200, // Küçük fotoğraf = daha hızlı yükleme, daha az kota.
        imageQuality: 80,
      );
      if (file == null) return;
      setState(() {
        _photoPath = file.path;
        _status = _AnalysisStatus.ready;
        _result = null;
        _errorMessage = null;
      });
    } catch (error) {
      _showMessage('Fotoğraf alınamadı. Kamera veya galeri iznini kontrol et.');
    }
  }

  Future<void> _analyze() async {
    final path = _photoPath;
    if (path == null) return;

    setState(() {
      _status = _AnalysisStatus.loading;
      _errorMessage = null;
    });

    try {
      final result = await _analysisService.analyze(path);
      if (!mounted) return;
      setState(() {
        _result = result;
        _status = _AnalysisStatus.success;
      });
    } on AnalysisException catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.message;
        _status = _AnalysisStatus.error;
      });
    } catch (error) {
      debugPrint('Beklenmeyen analiz hatası: $error');
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Beklenmeyen bir hata oluştu. Lütfen tekrar dene.';
        _status = _AnalysisStatus.error;
      });
    }
  }

  void _reset() {
    setState(() {
      _status = _AnalysisStatus.idle;
      _photoPath = null;
      _result = null;
      _errorMessage = null;
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _showPhotoOptions() async {
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
    if (source != null) await _pickPhoto(source);
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = _status == _AnalysisStatus.loading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bitki Analizi'),
        actions: [
          if (_status != _AnalysisStatus.idle && !isLoading)
            IconButton(
              tooltip: 'Yeni analiz',
              icon: const Icon(Icons.refresh),
              onPressed: _reset,
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          if (_photoPath == null)
            _IntroCard(
              onCamera: () => _pickPhoto(ImageSource.camera),
              onGallery: () => _pickPhoto(ImageSource.gallery),
            )
          else
            _PhotoPreview(
              path: _photoPath!,
              onChange: isLoading ? null : _showPhotoOptions,
            ),
          const SizedBox(height: 16),
          if (_status == _AnalysisStatus.ready)
            FilledButton.icon(
              onPressed: _analyze,
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Analiz Et'),
            ),
          if (isLoading) const _LoadingCard(),
          if (_status == _AnalysisStatus.error)
            _ErrorCard(message: _errorMessage!, onRetry: _analyze),
          if (_status == _AnalysisStatus.success && _result != null)
            AnalysisResultView(result: _result!, photoPath: _photoPath!),
          const SizedBox(height: 20),
          const _DisclaimerCard(),
        ],
      ),
    );
  }
}

class _IntroCard extends StatelessWidget {
  const _IntroCard({required this.onCamera, required this.onGallery});

  final VoidCallback onCamera;
  final VoidCallback onGallery;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.sage, width: 1.5),
      ),
      child: Column(
        children: [
          const CircleAvatar(
            radius: 44,
            backgroundColor: AppColors.mint,
            child: Icon(Icons.photo_camera_outlined, size: 44, color: AppColors.darkGreen),
          ),
          const SizedBox(height: 16),
          Text(
            'Bitkini tanıyalım',
            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            'Net ve iyi ışıklı bir fotoğraf çek ya da galeriden seç. '
            'Bitkinin adını ve sağlık durumunu tahmin edelim.',
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.darkGreen.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onCamera,
              icon: const Icon(Icons.camera_alt),
              label: const Text('Fotoğraf Çek'),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onGallery,
              icon: const Icon(Icons.photo_library_outlined),
              label: const Text('Galeriden Seç'),
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoPreview extends StatelessWidget {
  const _PhotoPreview({required this.path, required this.onChange});

  final String path;
  final VoidCallback? onChange;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: SizedBox(
        height: 260,
        child: Stack(
          children: [
            Positioned.fill(child: Image.file(File(path), fit: BoxFit.cover)),
            if (onChange != null)
              Positioned(
                right: 12,
                bottom: 12,
                child: Material(
                  color: Colors.white.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(20),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: onChange,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.photo_camera_outlined, size: 18),
                          SizedBox(width: 6),
                          Text('Değiştir', style: TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            'Bitkin inceleniyor...',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Bu işlem 10-20 saniye sürebilir.',
            style: TextStyle(color: AppColors.darkGreen.withValues(alpha: 0.65)),
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    const errorText = Color(0xFF9C4A45);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF6DEDC),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          const Icon(Icons.cloud_off_outlined, color: errorText, size: 36),
          const SizedBox(height: 10),
          const Text(
            'Analiz yapılamadı',
            style: TextStyle(
              color: errorText,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: errorText, height: 1.4),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Tekrar Dene'),
          ),
        ],
      ),
    );
  }
}

class _DisclaimerCard extends StatelessWidget {
  const _DisclaimerCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.mint,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: AppColors.darkGreen),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Analiz sonuçları yapay zekâ tarafından üretilen tahmini '
              'değerlendirmelerdir, kesin teşhis yerine geçmez. Ciddi '
              'sorunlarda bir ziraat uzmanına danışmanı öneririz.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
