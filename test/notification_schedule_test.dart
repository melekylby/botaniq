import 'package:flutter_test/flutter_test.dart';

import 'package:botaniq/models/my_plant.dart';
import 'package:botaniq/services/notification_service.dart';

void main() {
  // Son sulama 15 Kasım, 7 günde bir → sonraki sulama 22 Kasım.
  final plant = MyPlant(
    id: 1,
    name: 'Monstera',
    species: 'Deve Tabanı',
    addedAt: DateTime(2026, 11, 1),
    wateringIntervalDays: 7,
    lastWateredAt: DateTime(2026, 11, 15, 18, 30),
  );

  test('Hatırlatma sulama günü saat 09:00\'a kurulur', () {
    final time = NotificationService.reminderTimeFor(
      plant,
      now: DateTime(2026, 11, 18, 20),
    );
    expect(time, DateTime(2026, 11, 22, 9));
  });

  test('Sulama günü 09:00 geçtiyse hatırlatma kurulmaz', () {
    final time = NotificationService.reminderTimeFor(
      plant,
      now: DateTime(2026, 11, 22, 10),
    );
    expect(time, isNull);
  });
}
