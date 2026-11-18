import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Favori bitkileri yöneten durum sınıfı.
///
/// ChangeNotifier: favoriler değiştiğinde notifyListeners() çağrılır ve
/// bu sınıfı dinleyen tüm widget'lar (kalp ikonları, favoriler ekranı)
/// otomatik olarak yeniden çizilir.
///
/// Favoriler yalnızca bitki id'leri olarak shared_preferences'ta
/// saklanır; uygulama kapanıp açılınca kaybolmaz.
class FavoritesProvider extends ChangeNotifier {
  static const _storageKey = 'favorite_plant_ids';

  final Set<String> _ids = {};

  Set<String> get ids => Set.unmodifiable(_ids);

  bool isFavorite(String plantId) => _ids.contains(plantId);

  /// Uygulama açılırken kayıtlı favorileri yükler.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _ids
      ..clear()
      ..addAll(prefs.getStringList(_storageKey) ?? const []);
    notifyListeners();
  }

  /// Bitki favorideyse çıkarır, değilse ekler.
  Future<void> toggle(String plantId) async {
    if (!_ids.remove(plantId)) {
      _ids.add(plantId);
    }
    // Önce arayüzü güncelle, sonra diske yaz: kullanıcı beklemez.
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_storageKey, _ids.toList());
  }
}
