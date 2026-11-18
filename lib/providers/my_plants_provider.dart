import 'package:flutter/foundation.dart';

import '../models/my_plant.dart';
import '../repositories/my_plant_repository.dart';
import '../services/notification_service.dart';
import '../services/photo_storage_service.dart';

/// Kullanıcının bitki koleksiyonunu yöneten durum sınıfı.
///
/// Ekranlar bu sınıfı dinler. Bitki eklenince, düzenlenince ya da
/// silinince notifyListeners() çağrılır ve liste kendiliğinden yenilenir.
/// Her değişiklikte sulama hatırlatması da güncellenir.
class MyPlantsProvider extends ChangeNotifier {
  MyPlantsProvider({
    MyPlantRepository? repository,
    PhotoStorageService? photoStorage,
    NotificationService? notifications,
  })  : _repository = repository ?? MyPlantRepository(),
        _photoStorage = photoStorage ?? PhotoStorageService.instance,
        _notifications = notifications ?? NotificationService.instance;

  final MyPlantRepository _repository;
  final PhotoStorageService _photoStorage;
  final NotificationService _notifications;

  List<MyPlant> _plants = [];
  bool _isLoading = true;
  String? _errorMessage;

  List<MyPlant> get plants => List.unmodifiable(_plants);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  MyPlant? findById(int id) {
    for (final plant in _plants) {
      if (plant.id == id) return plant;
    }
    return null;
  }

  /// Bitkileri veritabanından yükler. Hata olursa kullanıcıya
  /// gösterilecek bir mesaj saklanır, uygulama çökmez.
  Future<void> load() async {
    if (!_isLoading) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    }
    try {
      _plants = await _repository.getAll();
    } catch (error) {
      debugPrint('Bitkiler yüklenemedi: $error');
      _errorMessage = 'Bitkilerin yüklenemedi. Lütfen tekrar dene.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    // Hatırlatmaları veritabanıyla eşitle (arayüzü bekletmeden).
    _notifications.rescheduleAll(_plants);
  }

  Future<void> add(MyPlant plant) async {
    final saved = await _repository.insert(plant);
    _plants = [saved, ..._plants];
    notifyListeners();
    await _notifications.scheduleFor(saved);
  }

  Future<void> update(MyPlant plant) async {
    await _repository.update(plant);
    _plants = [
      for (final p in _plants) p.id == plant.id ? plant : p,
    ];
    notifyListeners();
    await _notifications.scheduleFor(plant);
  }

  /// Bitkiyi sulandı olarak işaretler: son sulama tarihi şimdi olur,
  /// bir sonraki sulama tarihi de buna göre kendiliğinden hesaplanır.
  /// Güncellenmiş bitkiyi döndürür ("Geri Al" için gerekli).
  Future<MyPlant> markWatered(MyPlant plant, {DateTime? at}) async {
    final updated = plant.copyWith(lastWateredAt: at ?? DateTime.now());
    await update(updated);
    return updated;
  }

  /// Bitkiyi, varsa fotoğraf dosyasını ve hatırlatmasını siler.
  Future<void> delete(MyPlant plant) async {
    await _repository.delete(plant.id!);
    if (plant.photoName != null) {
      await _photoStorage.deletePhoto(plant.photoName!);
    }
    _plants = _plants.where((p) => p.id != plant.id).toList();
    notifyListeners();
    await _notifications.cancelFor(plant.id!);
  }
}
