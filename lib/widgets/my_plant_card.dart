import 'package:flutter/material.dart';

import '../models/my_plant.dart';
import '../screens/my_plant_detail_screen.dart';
import '../theme/app_colors.dart';
import 'my_plant_photo.dart';
import 'watering_badge.dart';

/// "Bitkilerim" listesindeki yatay kart: fotoğraf, ad, tür ve sulama durumu.
class MyPlantCard extends StatelessWidget {
  const MyPlantCard({super.key, required this.plant});

  final MyPlant plant;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => MyPlantDetailScreen.open(context, plant.id!),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  width: 76,
                  height: 76,
                  child: MyPlantPhoto(photoName: plant.photoName, iconSize: 32),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plant.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      plant.species,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.darkGreen.withValues(alpha: 0.65),
                      ),
                    ),
                    const SizedBox(height: 8),
                    WateringBadge(plant: plant),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.sage),
            ],
          ),
        ),
      ),
    );
  }
}
