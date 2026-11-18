import 'package:flutter_test/flutter_test.dart';

import 'package:botaniq/models/my_plant.dart';
import 'package:botaniq/providers/my_plants_provider.dart';
import 'package:botaniq/services/watering_schedule.dart';

import 'fakes/fake_my_plant_repository.dart';

MyPlant plant(String name, {required DateTime lastWatered, int interval = 7}) =>
    MyPlant(
      name: name,
      species: 'Test',
      addedAt: DateTime(2026, 10, 1),
      wateringIntervalDays: interval,
      lastWateredAt: lastWatered,
    );

void main() {
  final today = DateTime(2026, 11, 18);

  group('isDueOn', () {
    // Son sulama 15 Kasım, 7 günde bir → 22, 29 Kasım, 6 Aralık...
    final onTime = plant('A', lastWatered: DateTime(2026, 11, 15));

    test('Planlanan günlerde true döner', () {
      expect(WateringSchedule.isDueOn(onTime, DateTime(2026, 11, 22), today: today), isTrue);
      expect(WateringSchedule.isDueOn(onTime, DateTime(2026, 11, 29), today: today), isTrue);
      expect(WateringSchedule.isDueOn(onTime, DateTime(2026, 12, 6), today: today), isTrue);
    });

    test('Ara günlerde ve geçmişte false döner', () {
      expect(WateringSchedule.isDueOn(onTime, DateTime(2026, 11, 25), today: today), isFalse);
      expect(WateringSchedule.isDueOn(onTime, DateTime(2026, 11, 17), today: today), isFalse);
    });

    test('Gecikmiş bitki bugüne sayılır, plan bugünden devam eder', () {
      // Son sulama 1 Kasım → 8 Kasım'da sulanmalıydı (gecikmiş).
      final overdue = plant('B', lastWatered: DateTime(2026, 11, 1));
      expect(WateringSchedule.isDueOn(overdue, today, today: today), isTrue);
      expect(WateringSchedule.isDueOn(overdue, DateTime(2026, 11, 25), today: today), isTrue);
      expect(WateringSchedule.isDueOn(overdue, DateTime(2026, 11, 22), today: today), isFalse);
    });
  });

  test('upcoming en acil bitkiyi en üste koyar ve uzaktakileri dışarıda bırakır', () {
    final soon = plant('Yakında', lastWatered: DateTime(2026, 11, 13)); // 2 gün kaldı
    final overdue = plant('Gecikmiş', lastWatered: DateTime(2026, 11, 1)); // gecikmiş
    final far = plant('Uzak', lastWatered: DateTime(2026, 11, 18)); // 7 gün kaldı

    final result = WateringSchedule.upcoming([soon, far, overdue], today: today);
    expect(result.map((p) => p.name), ['Gecikmiş', 'Yakında']);
  });

  test('markWatered son sulama tarihini günceller', () async {
    final provider = MyPlantsProvider(repository: FakeMyPlantRepository());
    await provider.load();
    await provider.add(plant('C', lastWatered: DateTime(2026, 11, 1)));

    final updated = await provider.markWatered(provider.plants.first, at: today);
    expect(updated.lastWateredAt, today);
    expect(provider.plants.first.nextWateringDate, DateTime(2026, 11, 25));
  });
}
