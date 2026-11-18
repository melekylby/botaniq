import 'package:flutter/material.dart';

import '../models/my_plant.dart';
import '../theme/app_colors.dart';

/// Sulama durumunu renkli bir etiketle gösterir:
/// gecikmiş (kırmızımsı), bugün (adaçayı), ileride (mint).
class WateringBadge extends StatelessWidget {
  const WateringBadge({super.key, required this.plant});

  final MyPlant plant;

  static const _overdueBackground = Color(0xFFF6DEDC);
  static const _overdueText = Color(0xFF9C4A45);

  @override
  Widget build(BuildContext context) {
    final days = plant.daysUntilWatering();

    // Dart 3 "record" yapısı: üç değeri tek seferde belirliyoruz.
    final (String text, Color background, Color foreground) = switch (days) {
      < 0 => ('${-days} gün gecikti', _overdueBackground, _overdueText),
      0 => ('Bugün sulanmalı', AppColors.sage, AppColors.darkGreen),
      1 => ('Yarın sulanacak', AppColors.mint, AppColors.darkGreen),
      _ => ('$days gün sonra sulanacak', AppColors.mint, AppColors.darkGreen),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.water_drop_outlined, size: 14, color: foreground),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: foreground,
            ),
          ),
        ],
      ),
    );
  }
}
