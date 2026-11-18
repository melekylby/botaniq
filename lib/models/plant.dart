import 'package:flutter/material.dart';

/// Bitki kategorileri. Her kategorinin Türkçe etiketi ve ikonu vardır.
enum PlantCategory {
  indoor('İç Mekân', Icons.chair_outlined),
  outdoor('Dış Mekân', Icons.park_outlined),
  succulent('Sukulent', Icons.grass),
  flowering('Çiçekli', Icons.local_florist_outlined);

  const PlantCategory(this.label, this.icon);

  final String label;
  final IconData icon;
}

/// Bakım zorluğu.
enum CareDifficulty {
  easy('Kolay'),
  medium('Orta'),
  hard('Zor');

  const CareDifficulty(this.label);

  final String label;
}

/// Kütüphanedeki bir bitki türünü temsil eden veri modeli.
/// Bu sınıf yalnızca veri taşır; ekran veya kayıt mantığı içermez.
class Plant {
  const Plant({
    required this.id,
    required this.name,
    required this.scientificName,
    required this.category,
    required this.difficulty,
    required this.description,
    required this.light,
    required this.water,
    required this.temperature,
    required this.humidity,
    required this.wateringIntervalDays,
    required this.tips,
  });

  final String id;
  final String name;
  final String scientificName;
  final PlantCategory category;
  final CareDifficulty difficulty;
  final String description;
  final String light;
  final String water;
  final String temperature;
  final String humidity;

  /// Ortalama sulama aralığı (gün). 3. aşamada varsayılan değer olarak kullanılacak.
  final int wateringIntervalDays;
  final List<String> tips;

  /// Fotoğraf dosyasının yolu. Dosya yoksa arayüz pastel bir yer tutucu gösterir.
  String get imagePath => 'assets/images/plants/$id.jpg';

  /// Arama metni bitkinin Türkçe ya da bilimsel adında geçiyor mu?
  bool matchesQuery(String query) {
    final q = _normalize(query.trim());
    if (q.isEmpty) return true;
    return _normalize(name).contains(q) || _normalize(scientificName).contains(q);
  }

  /// Dart'ın toLowerCase() fonksiyonu Türkçe "İ/I" harflerini doğru
  /// çevirmez. Önce bu iki harfi elle düzeltiyoruz.
  static String _normalize(String text) =>
      text.replaceAll('İ', 'i').replaceAll('I', 'ı').toLowerCase();
}
