import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'providers/community_provider.dart';
import 'providers/favorites_provider.dart';
import 'providers/my_plants_provider.dart';
import 'screens/main_shell.dart';
import 'services/notification_service.dart';
import 'services/photo_storage_service.dart';
import 'theme/app_theme.dart';

/// Uygulamanın giriş noktası.
Future<void> main() async {
  // runApp'ten önce eklenti (shared_preferences, path_provider)
  // kullanacağımız için gerekli.
  WidgetsFlutterBinding.ensureInitialized();

  // Fotoğraf klasörünü ve bildirim sistemini hazırla.
  await PhotoStorageService.instance.init();
  await NotificationService.instance.init();

  // Favorileri uygulama açılmadan yüklüyoruz; böylece ilk ekranda
  // kalp ikonları doğru görünür.
  final favoritesProvider = FavoritesProvider();
  await favoritesProvider.load();

  runApp(
    // Provider'ları uygulamanın en üstüne koyuyoruz: alttaki her ekran
    // context.watch / context.read ile bunlara ulaşabilir.
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: favoritesProvider),
        // Bitkilerim arka planda yüklenir; ekran o sırada yükleniyor gösterir.
        ChangeNotifierProvider(create: (_) => MyPlantsProvider()..load()),
        ChangeNotifierProvider(create: (_) => CommunityProvider()..load()),
      ],
      child: const BotanIQApp(),
    ),
  );
}

class BotanIQApp extends StatelessWidget {
  const BotanIQApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BotanIQ',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      // Takvim, saat seçici ve sistem metinleri Türkçe olsun.
      locale: const Locale('tr'),
      supportedLocales: const [Locale('tr')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const MainShell(),
    );
  }
}
