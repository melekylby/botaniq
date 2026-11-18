import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/plant.dart';
import '../providers/my_plants_provider.dart';
import '../repositories/plant_repository.dart';
import '../services/watering_schedule.dart';
import '../theme/app_colors.dart';
import '../widgets/empty_state.dart';
import '../widgets/plant_image.dart';
import '../widgets/quick_action_card.dart';
import '../widgets/section_header.dart';
import '../widgets/watering_task_tile.dart';
import 'care_calendar_screen.dart';
import 'plant_detail_screen.dart';

/// Ana Sayfa: selamlama, günün bitkisi, hızlı işlemler ve yaklaşan bakımlar.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.onNavigate});

  /// Hızlı işlem kartına basıldığında ilgili sekmeye geçmek için kullanılır.
  final ValueChanged<int> onNavigate;

  /// Ana sayfada kaç gün ilerisine kadar görev gösterilsin?
  static const _upcomingDays = 3;

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Günaydın';
    if (hour < 18) return 'İyi günler';
    return 'İyi akşamlar';
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final plantOfTheDay = const PlantRepository().plantOfTheDay();
    final myPlants = context.watch<MyPlantsProvider>();
    final dueToday = WateringSchedule.dueTodayCount(myPlants.plants);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          Text(
            '${_greeting()} 🌿',
            style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            dueToday > 0
                ? 'Bugün $dueToday bitkin su bekliyor 💧'
                : 'Bitkilerin bugün nasıl?',
            style: textTheme.bodyLarge?.copyWith(
              color: AppColors.darkGreen.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 24),
          _PlantOfTheDayCard(plant: plantOfTheDay),
          const SizedBox(height: 28),
          const SectionHeader(title: 'Hızlı İşlemler'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: QuickActionCard(
                  icon: Icons.camera_alt_outlined,
                  label: 'Bitki Tanı',
                  onTap: () => onNavigate(2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: QuickActionCard(
                  icon: Icons.add_circle_outline,
                  label: 'Bitki Ekle',
                  onTap: () => onNavigate(3),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: QuickActionCard(
                  icon: Icons.search,
                  label: 'Keşfet',
                  onTap: () => onNavigate(1),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          SectionHeader(
            title: 'Yaklaşan Bakımlar',
            actionLabel: 'Takvim',
            onActionTap: () => CareCalendarScreen.open(context),
          ),
          const SizedBox(height: 12),
          ..._buildUpcomingTasks(myPlants),
        ],
      ),
    );
  }

  List<Widget> _buildUpcomingTasks(MyPlantsProvider myPlants) {
    if (myPlants.isLoading) {
      return const [
        Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }

    if (myPlants.plants.isEmpty) {
      return [
        EmptyState(
          icon: Icons.water_drop_outlined,
          title: 'Henüz görev yok',
          message:
              'Bitkilerim sekmesinden bitki eklediğinde sulama görevlerin burada görünecek.',
          actionLabel: 'Bitki Ekle',
          onAction: () => onNavigate(3),
        ),
      ];
    }

    final upcoming = WateringSchedule.upcoming(
      myPlants.plants,
      withinDays: _upcomingDays,
    );

    if (upcoming.isEmpty) {
      return const [
        EmptyState(
          icon: Icons.check_circle_outline,
          title: 'Her şey yolunda',
          message: 'Önümüzdeki $_upcomingDays gün içinde sulanacak bitkin yok.',
        ),
      ];
    }

    return [
      for (final plant in upcoming)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: WateringTaskTile(plant: plant),
        ),
    ];
  }
}

/// "Günün Bitkisi" kartı. Dokununca bitkinin detay sayfası açılır.
class _PlantOfTheDayCard extends StatelessWidget {
  const _PlantOfTheDayCard({required this.plant});

  final Plant plant;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [AppColors.mint, AppColors.sage],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.darkGreen.withValues(alpha: 0.10),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => PlantDetailScreen.open(context, plant),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'GÜNÜN BİTKİSİ',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        plant.name,
                        style: textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        plant.scientificName,
                        style: textTheme.bodyMedium
                            ?.copyWith(fontStyle: FontStyle.italic),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        plant.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 84,
                  height: 84,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                  padding: const EdgeInsets.all(3),
                  child: ClipOval(child: PlantImage(plant: plant, iconSize: 38)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
