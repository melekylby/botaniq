import 'package:flutter_test/flutter_test.dart';

import 'package:botaniq/models/my_plant.dart';
import 'package:botaniq/providers/my_plants_provider.dart';

import 'fakes/fake_my_plant_repository.dart';

MyPlant samplePlant({DateTime? lastWatered, int interval = 7}) => MyPlant(
      name: 'Salondaki Monstera',
      species: 'Deve Tabanı',
      speciesId: 'deve_tabani',
      addedAt: DateTime(2026, 11, 1),
      wateringIntervalDays: interval,
      lastWateredAt: lastWatered ?? DateTime(2026, 11, 15),
      notes: 'Pencerenin yanında',
    );

void main() {
  group('MyPlant', () {
    test('toMap ve fromMap veriyi kaybetmeden çevirir', () {
      final plant = samplePlant().copyWith(id: 3);
      final restored = MyPlant.fromMap(plant.toMap());

      expect(restored.id, 3);
      expect(restored.name, plant.name);
      expect(restored.speciesId, plant.speciesId);
      expect(restored.lastWateredAt, plant.lastWateredAt);
      expect(restored.notes, plant.notes);
    });

    test('Sonraki sulama tarihi doğru hesaplanır', () {
      final plant = samplePlant(lastWatered: DateTime(2026, 11, 15), interval: 7);
      expect(plant.nextWateringDate, DateTime(2026, 11, 22));
    });

    test('Kalan gün: ileride, bugün ve gecikmiş', () {
      final plant = samplePlant(lastWatered: DateTime(2026, 11, 15), interval: 7);
      expect(plant.daysUntilWatering(DateTime(2026, 11, 18, 20)), 4);
      expect(plant.daysUntilWatering(DateTime(2026, 11, 22, 9)), 0);
      expect(plant.daysUntilWatering(DateTime(2026, 11, 25)), -3);
    });
  });

  group('MyPlantsProvider', () {
    test('Bitki ekler, günceller ve siler', () async {
      final provider = MyPlantsProvider(repository: FakeMyPlantRepository());
      await provider.load();
      expect(provider.plants, isEmpty);

      await provider.add(samplePlant());
      expect(provider.plants, hasLength(1));
      final added = provider.plants.first;
      expect(added.id, isNotNull);

      await provider.update(added.copyWith(name: 'Yatak Odası Monstera'));
      expect(provider.findById(added.id!)!.name, 'Yatak Odası Monstera');

      await provider.delete(provider.plants.first);
      expect(provider.plants, isEmpty);
    });
  });
}
