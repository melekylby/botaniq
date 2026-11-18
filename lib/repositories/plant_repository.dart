import '../data/plant_data.dart';
import '../models/plant.dart';

/// Bitki verisine erişimin tek kapısı.
/// Ekranlar veriyi doğrudan plant_data.dart'tan değil buradan alır.
/// İleride veri bir API'den veya veritabanından gelirse yalnızca bu
/// dosya değişir, ekranlara dokunmak gerekmez.
class PlantRepository {
  const PlantRepository();

  List<Plant> getAll() => plantLibrary;

  /// id'si verilen bitkiyi bulur, yoksa null döndürür.
  Plant? getById(String id) {
    for (final plant in plantLibrary) {
      if (plant.id == id) return plant;
    }
    return null;
  }

  /// Yapay zekânın verdiği bilimsel adı kütüphanedeki bir bitkiyle
  /// eşleştirmeye çalışır (ör. "Monstera deliciosa" → Deve Tabanı).
  /// Önce cins + tür, kütüphanede "spp." yazıyorsa yalnızca cins karşılaştırılır.
  Plant? findByScientificName(String scientificName) {
    final words = _scientificWords(scientificName);
    if (words.isEmpty) return null;

    for (final plant in plantLibrary) {
      final plantWords = _scientificWords(plant.scientificName);
      if (plantWords.first != words.first) continue; // Cins farklı

      final isWholeGenus = plantWords.length < 2 || plantWords[1] == 'spp.';
      if (isWholeGenus) return plant;
      if (words.length >= 2 && words[1] == plantWords[1]) return plant;
    }
    return null;
  }

  static List<String> _scientificWords(String name) => name
      .toLowerCase()
      .replaceAll('×', ' ')
      .split(RegExp(r'\s+'))
      // Melez işareti "x" ya da "×" eşleştirmede dikkate alınmaz.
      .where((word) => word.isNotEmpty && word != 'x')
      .toList();

  /// Arama metnine ve kategoriye göre filtreler.
  /// category null ise tüm kategoriler gösterilir ("Tümü").
  List<Plant> search({String query = '', PlantCategory? category}) {
    return plantLibrary
        .where((plant) => category == null || plant.category == category)
        .where((plant) => plant.matchesQuery(query))
        .toList();
  }

  /// Yılın gününe göre her gün farklı bir bitki seçer.
  /// Aynı gün içinde uygulama kaç kez açılırsa açılsın aynı bitki gelir.
  Plant plantOfTheDay([DateTime? date]) {
    final d = date ?? DateTime.now();
    final dayOfYear =
        DateTime.utc(d.year, d.month, d.day).difference(DateTime.utc(d.year)).inDays;
    return plantLibrary[dayOfYear % plantLibrary.length];
  }
}
