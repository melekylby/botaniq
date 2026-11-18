import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/my_plant.dart';
import '../providers/my_plants_provider.dart';
import '../repositories/plant_repository.dart';
import '../theme/app_colors.dart';
import '../utils/formatters.dart';
import '../widgets/care_info_tile.dart';
import '../widgets/circle_icon_button.dart';
import '../widgets/my_plant_photo.dart';
import '../widgets/section_header.dart';
import '../widgets/water_button.dart';
import '../widgets/watering_badge.dart';
import 'add_edit_plant_screen.dart';
import 'plant_detail_screen.dart';

/// Kullanıcının kendi bitkisinin detay sayfası.
///
/// Bitkiyi nesne olarak değil id ile alıyoruz ve güncel hâlini her
/// seferinde provider'dan okuyoruz. Böylece düzenleme ekranından
/// dönüldüğünde bu sayfa kendiliğinden güncellenir.
class MyPlantDetailScreen extends StatelessWidget {
  const MyPlantDetailScreen({super.key, required this.plantId});

  final int plantId;

  static Future<void> open(BuildContext context, int plantId) {
    return Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => MyPlantDetailScreen(plantId: plantId)),
    );
  }

  Future<void> _confirmDelete(BuildContext context, MyPlant plant) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Bitkiyi sil'),
        content: Text(
          '"${plant.name}" koleksiyonundan silinsin mi? Bu işlem geri alınamaz.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFB85C57)),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final provider = context.read<MyPlantsProvider>();
    final messenger = ScaffoldMessenger.of(context);

    // Önce sayfayı kapatıyoruz, sonra siliyoruz; böylece boş bir sayfa
    // bir anlığına bile görünmez.
    Navigator.of(context).pop();
    try {
      await provider.delete(plant);
      messenger.showSnackBar(SnackBar(content: Text('${plant.name} silindi')));
    } catch (error) {
      debugPrint('Bitki silinemedi: $error');
      messenger.showSnackBar(
        const SnackBar(content: Text('Bitki silinemedi. Lütfen tekrar dene.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final plant = context.watch<MyPlantsProvider>().findById(plantId);

    // Bitki silindiyse (sayfa kapanırken) boş bir ekran döndür.
    if (plant == null) return const Scaffold();

    final textTheme = Theme.of(context).textTheme;
    final species = plant.speciesId == null
        ? null
        : const PlantRepository().getById(plant.speciesId!);

    return Scaffold(
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: WaterButton(plant: plant, large: true),
        ),
      ),
      body: CustomScrollView(
        slivers: [
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
              CircleIconButton(
                icon: Icons.edit_outlined,
                tooltip: 'Düzenle',
                onPressed: () => AddEditPlantScreen.open(context, plant: plant),
              ),
              const SizedBox(width: 4),
              CircleIconButton(
                icon: Icons.delete_outline,
                tooltip: 'Sil',
                onPressed: () => _confirmDelete(context, plant),
              ),
              const SizedBox(width: 12),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: MyPlantPhoto(photoName: plant.photoName, iconSize: 96),
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
                    plant.species,
                    style: textTheme.titleMedium?.copyWith(
                      color: AppColors.darkGreen.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 14),
                  WateringBadge(plant: plant),
                  const SizedBox(height: 28),
                  const SectionHeader(title: 'Bakım Bilgileri'),
                  const SizedBox(height: 12),
                  CareInfoTile(
                    icon: Icons.repeat,
                    title: 'Sulama sıklığı',
                    value: '${plant.wateringIntervalDays} günde bir',
                  ),
                  const SizedBox(height: 10),
                  CareInfoTile(
                    icon: Icons.water_drop_outlined,
                    title: 'Son sulama',
                    value: formatDate(plant.lastWateredAt),
                  ),
                  const SizedBox(height: 10),
                  CareInfoTile(
                    icon: Icons.event_available_outlined,
                    title: 'Sonraki sulama',
                    value: formatDate(plant.nextWateringDate),
                  ),
                  const SizedBox(height: 10),
                  CareInfoTile(
                    icon: Icons.calendar_today_outlined,
                    title: 'Eklenme tarihi',
                    value: formatDate(plant.addedAt),
                  ),
                  if (plant.notes.isNotEmpty) ...[
                    const SizedBox(height: 28),
                    const SectionHeader(title: 'Notlarım'),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Text(
                        plant.notes,
                        style: textTheme.bodyMedium?.copyWith(height: 1.5),
                      ),
                    ),
                  ],
                  if (species != null) ...[
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => PlantDetailScreen.open(context, species),
                        icon: const Icon(Icons.menu_book_outlined),
                        label: Text('${species.name} bakım rehberi'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
