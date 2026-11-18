import 'package:flutter/material.dart';

import '../services/notification_service.dart';
import 'analysis_screen.dart';
import 'community_screen.dart';
import 'explore_screen.dart';
import 'home_screen.dart';
import 'my_plants_screen.dart';

/// Alt gezinme çubuğunu ve beş ana sekmeyi barındıran iskelet ekran.
///
/// IndexedStack kullanıyoruz: sekmeler arasında geçiş yapıldığında
/// ekranlar yeniden oluşturulmaz, kaydırma konumu ve yazılan arama
/// metni gibi durumlar korunur.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // İlk ekran çizildikten sonra bildirim izni iste (Android 13+).
    // İzin daha önce verildiyse/reddedildiyse sistem tekrar sormaz.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService.instance.requestPermission();
    });
  }

  void _onTabSelected(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final screens = <Widget>[
      // Ana sayfadaki hızlı işlem kartları diğer sekmelere geçebilsin diye
      // sekme değiştirme fonksiyonunu parametre olarak veriyoruz.
      HomeScreen(onNavigate: _onTabSelected),
      const ExploreScreen(),
      const AnalysisScreen(),
      const MyPlantsScreen(),
      const CommunityScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _onTabSelected,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Ana Sayfa',
          ),
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore),
            label: 'Keşfet',
          ),
          NavigationDestination(
            icon: Icon(Icons.document_scanner_outlined),
            selectedIcon: Icon(Icons.document_scanner),
            label: 'Analiz',
          ),
          NavigationDestination(
            icon: Icon(Icons.local_florist_outlined),
            selectedIcon: Icon(Icons.local_florist),
            label: 'Bitkilerim',
          ),
          NavigationDestination(
            icon: Icon(Icons.forum_outlined),
            selectedIcon: Icon(Icons.forum),
            label: 'Topluluk',
          ),
        ],
      ),
    );
  }
}
