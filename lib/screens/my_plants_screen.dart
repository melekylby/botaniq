import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/my_plants_provider.dart';
import '../services/notification_service.dart';
import '../theme/app_colors.dart';
import '../widgets/empty_state.dart';
import '../widgets/my_plant_card.dart';
import 'add_edit_plant_screen.dart';
import 'care_calendar_screen.dart';

/// Bitkilerim: kullanıcının kişisel koleksiyonu.
/// Yükleniyor, hata, boş ve dolu olmak üzere dört durumu ayrı ayrı gösterir.
class MyPlantsScreen extends StatelessWidget {
  const MyPlantsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MyPlantsProvider>();
    final showFab = !provider.isLoading && provider.plants.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bitkilerim'),
        actions: [
          IconButton(
            tooltip: 'Hatırlatmalar',
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => _showReminderSheet(context),
          ),
          IconButton(
            tooltip: 'Bakım Takvimi',
            icon: const Icon(Icons.calendar_month_outlined),
            onPressed: () => CareCalendarScreen.open(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _buildBody(context, provider),
      floatingActionButton: showFab
          ? FloatingActionButton.extended(
              onPressed: () => AddEditPlantScreen.open(context),
              icon: const Icon(Icons.add),
              label: const Text('Bitki Ekle'),
            )
          : null,
    );
  }

  /// Hatırlatmaların nasıl çalıştığını anlatan ve test bildirimi
  /// gönderebilen alt sayfa.
  Future<void> _showReminderSheet(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircleAvatar(
                radius: 32,
                backgroundColor: AppColors.mint,
                child: Icon(
                  Icons.notifications_active_outlined,
                  size: 32,
                  color: AppColors.darkGreen,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Sulama Hatırlatmaları',
                style: Theme.of(sheetContext)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Bir bitkinin sulama günü geldiğinde saat '
                '${NotificationService.reminderHour.toString().padLeft(2, '0')}:00\'da '
                'bildirim alırsın. "Suladım" dediğinde bir sonraki hatırlatma '
                'kendiliğinden kurulur.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  height: 1.4,
                  color: AppColors.darkGreen.withValues(alpha: 0.75),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  icon: const Icon(Icons.send_outlined),
                  label: const Text('Test Bildirimi Gönder'),
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    Navigator.pop(sheetContext);
                    final notifications = NotificationService.instance;
                    final granted = await notifications.requestPermission();
                    if (granted) {
                      await notifications.showTestNotification();
                    } else {
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Bildirim izni kapalı. Ayarlar > Uygulamalar > '
                            'botaniq > Bildirimler bölümünden açabilirsin.',
                          ),
                        ),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, MyPlantsProvider provider) {
    // 1) Yükleniyor
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // 2) Hata
    if (provider.errorMessage != null) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Align(
          alignment: Alignment.topCenter,
          child: EmptyState(
            icon: Icons.error_outline,
            title: 'Bir sorun oluştu',
            message: provider.errorMessage!,
            actionLabel: 'Tekrar Dene',
            onAction: provider.load,
          ),
        ),
      );
    }

    // 3) Boş
    if (provider.plants.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Align(
          alignment: Alignment.topCenter,
          child: EmptyState(
            icon: Icons.local_florist_outlined,
            title: 'Koleksiyonun boş',
            message: 'İlk bitkini ekle, sulama zamanlarını senin için takip edelim.',
            actionLabel: 'İlk Bitkimi Ekle',
            onAction: () => AddEditPlantScreen.open(context),
          ),
        ),
      );
    }

    // 4) Liste (alttaki boşluk, FAB kartların üstünü kapatmasın diye)
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 96),
      itemCount: provider.plants.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) =>
          MyPlantCard(plant: provider.plants[index]),
    );
  }
}
