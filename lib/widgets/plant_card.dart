import 'package:flutter/material.dart';

import '../models/plant.dart';
import '../screens/plant_detail_screen.dart';
import '../theme/app_colors.dart';
import 'favorite_button.dart';
import 'plant_image.dart';

/// Kütüphane ve favoriler ızgarasında gösterilen fotoğraflı bitki kartı.
class PlantCard extends StatelessWidget {
  const PlantCard({super.key, required this.plant});

  final Plant plant;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      clipBehavior: Clip.antiAlias, // Fotoğrafın köşeleri de yuvarlansın.
      child: InkWell(
        onTap: () => PlantDetailScreen.open(context, plant),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(child: PlantImage(plant: plant)),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: FavoriteButton(plantId: plant.id),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plant.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    plant.scientificName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall?.copyWith(
                      fontStyle: FontStyle.italic,
                      color: AppColors.darkGreen.withValues(alpha: 0.65),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(plant.category.icon, size: 14, color: AppColors.earth),
                      const SizedBox(width: 4),
                      Text(
                        plant.category.label,
                        style: textTheme.labelSmall?.copyWith(
                          color: AppColors.earth,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
