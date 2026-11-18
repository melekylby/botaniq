import 'package:flutter/material.dart';

import '../models/my_plant.dart';
import '../screens/my_plant_detail_screen.dart';
import 'my_plant_photo.dart';
import 'water_button.dart';
import 'watering_badge.dart';

/// Ana sayfa ve takvimde gösterilen sulama görevi satırı.
/// [showWaterButton] false ise (ör. takvimde gelecek bir gün)
/// "Suladım" butonu gizlenir.
class WateringTaskTile extends StatelessWidget {
  const WateringTaskTile({
    super.key,
    required this.plant,
    this.showWaterButton = true,
  });

  final MyPlant plant;
  final bool showWaterButton;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => MyPlantDetailScreen.open(context, plant.id!),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: MyPlantPhoto(photoName: plant.photoName, iconSize: 26),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plant.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 6),
                    WateringBadge(plant: plant),
                  ],
                ),
              ),
              if (showWaterButton) ...[
                const SizedBox(width: 8),
                WaterButton(plant: plant),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
