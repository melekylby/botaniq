import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:botaniq/main.dart';
import 'package:botaniq/providers/favorites_provider.dart';
import 'package:botaniq/providers/my_plants_provider.dart';

import 'package:botaniq/providers/community_provider.dart';

import 'fakes/fake_community_repository.dart';
import 'fakes/fake_my_plant_repository.dart';

/// Uygulamayı test ortamında, sahte (boş) depolarla başlatır.
Future<void> pumpApp(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  final favorites = FavoritesProvider();
  await favorites.load();

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: favorites),
        ChangeNotifierProvider(
          create: (_) =>
              MyPlantsProvider(repository: FakeMyPlantRepository())..load(),
        ),
        ChangeNotifierProvider(
          create: (_) =>
              CommunityProvider(repository: FakeCommunityRepository())..load(),
        ),
      ],
      child: const BotanIQApp(),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Ana sayfa açılır ve alt menüyle sekme değişir', (tester) async {
    await pumpApp(tester);
    expect(find.text('Hızlı İşlemler'), findsOneWidget);

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Bitkilerim'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Koleksiyonun boş'), findsOneWidget);
  });

  test('Favori ekleme ve çıkarma çalışır', () async {
    SharedPreferences.setMockInitialValues({});
    final favorites = FavoritesProvider();
    await favorites.load();

    await favorites.toggle('aloe_vera');
    expect(favorites.isFavorite('aloe_vera'), isTrue);

    await favorites.toggle('aloe_vera');
    expect(favorites.isFavorite('aloe_vera'), isFalse);
  });
}
