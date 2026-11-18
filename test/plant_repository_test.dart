import 'package:flutter_test/flutter_test.dart';

import 'package:botaniq/models/plant.dart';
import 'package:botaniq/repositories/plant_repository.dart';

void main() {
  const repository = PlantRepository();

  test('Türkçe adla arama yapılabilir (büyük/küçük harf duyarsız)', () {
    final results = repository.search(query: 'PAŞA');
    expect(results.map((p) => p.id), contains('pasa_kilici'));
  });

  test('Bilimsel adla arama yapılabilir', () {
    final results = repository.search(query: 'monstera');
    expect(results.single.id, 'deve_tabani');
  });

  test('Kategori filtresi yalnızca o kategoriyi döndürür', () {
    final results = repository.search(category: PlantCategory.succulent);
    expect(results, isNotEmpty);
    expect(results.every((p) => p.category == PlantCategory.succulent), isTrue);
  });

  test('Günün bitkisi aynı gün için hep aynıdır', () {
    final a = repository.plantOfTheDay(DateTime(2026, 11, 18, 9));
    final b = repository.plantOfTheDay(DateTime(2026, 11, 18, 23));
    expect(a.id, b.id);
  });

  test('Bitki id değerleri benzersizdir', () {
    final ids = repository.getAll().map((p) => p.id).toList();
    expect(ids.toSet().length, ids.length);
  });
}
