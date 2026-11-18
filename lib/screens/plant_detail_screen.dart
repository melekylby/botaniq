import 'package:flutter/material.dart';

import '../models/plant.dart';
import '../theme/app_colors.dart';
import '../widgets/bullet_list.dart';
import '../widgets/care_info_tile.dart';
import '../widgets/circle_icon_button.dart';
import '../widgets/favorite_button.dart';
import '../widgets/plant_image.dart';
import '../widgets/section_header.dart';
import 'add_edit_plant_screen.dart';

/// Bitki detay sayfası: büyük fotoğraf, açıklama, bakım gereksinimleri
/// ve ipuçları.
class PlantDetailScreen extends StatelessWidget {
  const PlantDetailScreen({super.key, required this.plant});

  final Plant plant;

  /// Detay sayfasını açmanın tek yolu. Kartlar ve ana sayfa bunu çağırır.
  static Future<void> open(BuildContext context, Plant plant) {
    return Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PlantDetailScreen(plant: plant)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      // Sayfanın altında sabit duran "Bitkilerime Ekle" butonu.
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: FilledButton.icon(
            onPressed: () => AddEditPlantScreen.open(context, initialSpecies: plant),
            icon: const Icon(Icons.add),
            label: const Text('Bitkilerime Ekle'),
          ),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          // Kaydırınca küçülen, fotoğraflı üst bölüm.
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: AppColors.cream,
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: CircleIconButton(
                icon: Icons.arrow_back,
                tooltip: 'Geri',
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: FavoriteButton(plantId: plant.id),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: PlantImage(plant: plant, iconSize: 96),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plant.name,
                    style: textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    plant.scientificName,
                    style: textTheme.titleMedium?.copyWith(
                      fontStyle: FontStyle.italic,
                      color: AppColors.darkGreen.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _InfoChip(
                        icon: plant.category.icon,
                        label: plant.category.label,
                      ),
                      _InfoChip(
                        icon: Icons.spa_outlined,
                        label: 'Bakım: ${plant.difficulty.label}',
                      ),
                      _InfoChip(
                        icon: Icons.water_drop_outlined,
                        label: '~${plant.wateringIntervalDays} günde bir',
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    plant.description,
                    style: textTheme.bodyLarge?.copyWith(height: 1.5),
                  ),
                  const SizedBox(height: 28),
                  const SectionHeader(title: 'Bakım Gereksinimleri'),
                  const SizedBox(height: 12),
                  CareInfoTile(
                    icon: Icons.wb_sunny_outlined,
                    title: 'Işık',
                    value: plant.light,
                  ),
                  const SizedBox(height: 10),
                  CareInfoTile(
                    icon: Icons.water_drop_outlined,
                    title: 'Sulama',
                    value: plant.water,
                  ),
                  const SizedBox(height: 10),
                  CareInfoTile(
                    icon: Icons.thermostat_outlined,
                    title: 'Sıcaklık',
                    value: plant.temperature,
                  ),
                  const SizedBox(height: 10),
                  CareInfoTile(
                    icon: Icons.cloud_outlined,
                    title: 'Nem',
                    value: plant.humidity,
                  ),
                  const SizedBox(height: 28),
                  const SectionHeader(title: 'Bakım İpuçları'),
                  const SizedBox(height: 12),
                  BulletList(items: plant.tips),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Kategori, zorluk ve sulama bilgisini gösteren küçük etiket.
class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.mint,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.darkGreen),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
