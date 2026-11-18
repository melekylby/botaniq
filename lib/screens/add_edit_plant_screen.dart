import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/my_plant.dart';
import '../models/plant.dart';
import '../providers/my_plants_provider.dart';
import '../repositories/plant_repository.dart';
import '../services/photo_storage_service.dart';
import '../theme/app_colors.dart';
import '../utils/formatters.dart';
import '../widgets/my_plant_photo.dart';
import '../widgets/plant_image.dart';

/// Bitki ekleme ve düzenleme formu.
/// [plant] verilirse düzenleme modunda, verilmezse ekleme modunda açılır.
/// [initialSpecies] kütüphaneden "Bitkilerime Ekle" ile gelindiğinde
/// türü ve sulama aralığını önceden doldurur.
/// [initialSpeciesName] ve [initialPhotoPath] yapay zekâ analizinden
/// gelindiğinde tür adını ve analiz fotoğrafını önceden doldurur.
class AddEditPlantScreen extends StatefulWidget {
  const AddEditPlantScreen({
    super.key,
    this.plant,
    this.initialSpecies,
    this.initialSpeciesName,
    this.initialPhotoPath,
  });

  final MyPlant? plant;
  final Plant? initialSpecies;
  final String? initialSpeciesName;
  final String? initialPhotoPath;

  static Future<void> open(
    BuildContext context, {
    MyPlant? plant,
    Plant? initialSpecies,
    String? initialSpeciesName,
    String? initialPhotoPath,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddEditPlantScreen(
          plant: plant,
          initialSpecies: initialSpecies,
          initialSpeciesName: initialSpeciesName,
          initialPhotoPath: initialPhotoPath,
        ),
      ),
    );
  }

  @override
  State<AddEditPlantScreen> createState() => _AddEditPlantScreenState();
}

class _AddEditPlantScreenState extends State<AddEditPlantScreen> {
  static const _minInterval = 1;
  static const _maxInterval = 60;

  final _formKey = GlobalKey<FormState>();
  final _plantRepository = const PlantRepository();
  final _imagePicker = ImagePicker();

  late final TextEditingController _nameController;
  late final TextEditingController _customSpeciesController;
  late final TextEditingController _notesController;

  String? _speciesId; // null = kullanıcı türü kendisi yazıyor
  late int _wateringInterval;
  late DateTime _lastWateredAt;

  String? _newPhotoPath; // Formda yeni seçilen, henüz kaydedilmemiş fotoğraf
  bool _removePhoto = false;
  bool _isSaving = false;

  bool get _isEditing => widget.plant != null;

  @override
  void initState() {
    super.initState();
    final plant = widget.plant;
    final species = widget.initialSpecies;

    _nameController = TextEditingController(
      text: plant?.name ?? species?.name ?? widget.initialSpeciesName ?? '',
    );
    _speciesId = plant != null ? plant.speciesId : species?.id;
    _customSpeciesController = TextEditingController(
      text: plant != null
          ? (plant.speciesId == null ? plant.species : '')
          : (widget.initialSpeciesName ?? ''),
    );
    _newPhotoPath = widget.initialPhotoPath;
    _notesController = TextEditingController(text: plant?.notes ?? '');
    _wateringInterval =
        plant?.wateringIntervalDays ?? species?.wateringIntervalDays ?? 7;
    _lastWateredAt = plant?.lastWateredAt ?? DateTime.now();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _customSpeciesController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Plant? get _selectedSpecies =>
      _speciesId == null ? null : _plantRepository.getById(_speciesId!);

  // ---------------------------------------------------------------- Fotoğraf

  bool get _hasPhoto =>
      _newPhotoPath != null || (!_removePhoto && widget.plant?.photoName != null);

  Future<void> _showPhotoOptions() async {
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Fotoğraf çek'),
              onTap: () => Navigator.pop(sheetContext, 'camera'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Galeriden seç'),
              onTap: () => Navigator.pop(sheetContext, 'gallery'),
            ),
            if (_hasPhoto)
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('Fotoğrafı kaldır'),
                onTap: () => Navigator.pop(sheetContext, 'remove'),
              ),
          ],
        ),
      ),
    );

    switch (action) {
      case 'camera':
        await _pickPhoto(ImageSource.camera);
      case 'gallery':
        await _pickPhoto(ImageSource.gallery);
      case 'remove':
        setState(() {
          _newPhotoPath = null;
          _removePhoto = true;
        });
    }
  }

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      // Fotoğrafı küçültüyoruz: hem yer kaplamaz hem de 4. aşamada
      // API'ye daha hızlı gönderilir.
      final file = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1200,
        imageQuality: 80,
      );
      if (file == null) return; // Kullanıcı vazgeçti.
      setState(() {
        _newPhotoPath = file.path;
        _removePhoto = false;
      });
    } catch (error) {
      _showMessage('Fotoğraf alınamadı. Kamera veya galeri iznini kontrol et.');
    }
  }

  // --------------------------------------------------------------------- Tür

  static const _customSpeciesKey = '__custom__';

  Future<void> _showSpeciesPicker() async {
    final plants = _plantRepository.getAll();

    final result = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: SizedBox(
          height: MediaQuery.of(sheetContext).size.height * 0.65,
          child: ListView(
            children: [
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Listede yok, kendim yazacağım'),
                onTap: () => Navigator.pop(sheetContext, _customSpeciesKey),
              ),
              const Divider(),
              for (final plant in plants)
                ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox(
                      width: 44,
                      height: 44,
                      child: PlantImage(plant: plant, iconSize: 20),
                    ),
                  ),
                  title: Text(plant.name),
                  subtitle: Text(
                    plant.scientificName,
                    style: const TextStyle(fontStyle: FontStyle.italic),
                  ),
                  trailing: plant.id == _speciesId
                      ? const Icon(Icons.check, color: AppColors.darkGreen)
                      : null,
                  onTap: () => Navigator.pop(sheetContext, plant.id),
                ),
            ],
          ),
        ),
      ),
    );

    if (result == null) return;

    setState(() {
      if (result == _customSpeciesKey) {
        _speciesId = null;
        return;
      }
      final species = _plantRepository.getById(result)!;
      _speciesId = species.id;
      // Türün önerdiği sulama aralığını otomatik doldur.
      _wateringInterval = species.wateringIntervalDays;
      // Ad henüz boşsa tür adını öner.
      if (_nameController.text.trim().isEmpty) {
        _nameController.text = species.name;
      }
    });
  }

  // ------------------------------------------------------------------ Tarih

  Future<void> _pickLastWateredDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _lastWateredAt,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now, // Gelecekte sulama yapılamaz.
      helpText: 'Son sulama tarihi',
    );
    if (picked != null) {
      setState(() => _lastWateredAt = picked);
    }
  }

  // ----------------------------------------------------------------- Kaydet

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    // await'ten sonra context kullanmamak için gerekenleri önceden alıyoruz.
    final provider = context.read<MyPlantsProvider>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final photoStorage = PhotoStorageService.instance;

    try {
      String? photoName = widget.plant?.photoName;

      if (_newPhotoPath != null) {
        // Yeni fotoğrafı kalıcı klasöre kopyala, eskisini sil.
        final savedName = await photoStorage.savePhoto(_newPhotoPath!);
        if (photoName != null) await photoStorage.deletePhoto(photoName);
        photoName = savedName;
      } else if (_removePhoto && photoName != null) {
        await photoStorage.deletePhoto(photoName);
        photoName = null;
      }

      final plant = MyPlant(
        id: widget.plant?.id,
        name: _nameController.text.trim(),
        speciesId: _speciesId,
        species: _selectedSpecies?.name ?? _customSpeciesController.text.trim(),
        photoName: photoName,
        addedAt: widget.plant?.addedAt ?? DateTime.now(),
        wateringIntervalDays: _wateringInterval,
        lastWateredAt: _lastWateredAt,
        notes: _notesController.text.trim(),
      );

      if (_isEditing) {
        await provider.update(plant);
      } else {
        await provider.add(plant);
      }

      navigator.pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text(_isEditing
              ? '${plant.name} güncellendi'
              : '${plant.name} koleksiyonuna eklendi 🌱'),
        ),
      );
    } catch (error) {
      debugPrint('Bitki kaydedilemedi: $error');
      if (!mounted) return;
      setState(() => _isSaving = false);
      _showMessage('Bitki kaydedilemedi. Lütfen tekrar dene.');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  // ------------------------------------------------------------------ Arayüz

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Bitkiyi Düzenle' : 'Yeni Bitki'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          children: [
            _buildPhotoPicker(),
            const SizedBox(height: 24),
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Bitkinin adı',
                hintText: 'ör. Salondaki Monstera',
                prefixIcon: Icon(Icons.label_outline),
              ),
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? 'Lütfen bitkine bir ad ver.'
                  : null,
            ),
            const SizedBox(height: 14),
            _buildSpeciesTile(),
            if (_speciesId == null) ...[
              const SizedBox(height: 14),
              TextFormField(
                controller: _customSpeciesController,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Bitki türü',
                  hintText: 'ör. Kaktüs',
                  prefixIcon: Icon(Icons.eco_outlined),
                ),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Türü listeden seç ya da buraya yaz.'
                    : null,
              ),
            ],
            const SizedBox(height: 14),
            _buildIntervalStepper(),
            const SizedBox(height: 14),
            _buildLastWateredTile(),
            const SizedBox(height: 14),
            TextFormField(
              controller: _notesController,
              minLines: 3,
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Bakım notların (isteğe bağlı)',
                hintText: 'ör. Pencerenin sol tarafında, haftada bir döndür.',
                alignLabelWithHint: true,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: FilledButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(_isEditing ? 'Değişiklikleri Kaydet' : 'Bitkiyi Ekle'),
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoPicker() {
    return GestureDetector(
      onTap: _showPhotoOptions,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: SizedBox(
          height: 200,
          child: Stack(
            children: [
              Positioned.fill(
                child: MyPlantPhoto(
                  filePath: _newPhotoPath,
                  photoName: _removePhoto ? null : widget.plant?.photoName,
                  iconSize: 64,
                ),
              ),
              Positioned(
                right: 12,
                bottom: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.photo_camera_outlined, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        _hasPhoto ? 'Değiştir' : 'Fotoğraf ekle',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Form alanlarıyla aynı görünen, dokunulabilir beyaz kutu.
  Widget _buildTappableField({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: AppColors.darkGreen.withValues(alpha: 0.7)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.darkGreen.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSpeciesTile() {
    return _buildTappableField(
      icon: Icons.menu_book_outlined,
      label: 'Kütüphaneden tür',
      value: _selectedSpecies?.name ?? 'Seç (isteğe bağlı)',
      onTap: _showSpeciesPicker,
    );
  }

  Widget _buildLastWateredTile() {
    return _buildTappableField(
      icon: Icons.event_outlined,
      label: 'Son sulama tarihi',
      value: formatDate(_lastWateredAt),
      onTap: _pickLastWateredDate,
    );
  }

  Widget _buildIntervalStepper() {
    final suggested = _selectedSpecies?.wateringIntervalDays;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            Icons.water_drop_outlined,
            color: AppColors.darkGreen.withValues(alpha: 0.7),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sulama sıklığı',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                if (suggested != null)
                  Text(
                    'Önerilen: $suggested günde bir',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.darkGreen.withValues(alpha: 0.6),
                    ),
                  ),
              ],
            ),
          ),
          IconButton.outlined(
            tooltip: 'Azalt',
            icon: const Icon(Icons.remove),
            onPressed: _wateringInterval > _minInterval
                ? () => setState(() => _wateringInterval--)
                : null,
          ),
          SizedBox(
            width: 64,
            child: Text(
              '$_wateringInterval gün',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          IconButton.outlined(
            tooltip: 'Artır',
            icon: const Icon(Icons.add),
            onPressed: _wateringInterval < _maxInterval
                ? () => setState(() => _wateringInterval++)
                : null,
          ),
        ],
      ),
    );
  }
}
