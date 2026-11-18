import 'package:flutter/material.dart';

import '../models/plant.dart';
import '../theme/app_colors.dart';

/// Kütüphanedeki bitkinin fotoğrafını gösterir. Fotoğraf dosyası henüz
/// eklenmemişse uygulama çökmez; kategori ikonlu pastel bir yer tutucu
/// gösterilir.
class PlantImage extends StatelessWidget {
  const PlantImage({super.key, required this.plant, this.iconSize = 48});

  final Plant plant;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      plant.imagePath,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (context, error, stackTrace) => PlantPhotoPlaceholder(
        icon: plant.category.icon,
        iconSize: iconSize,
      ),
    );
  }
}

/// Fotoğraf olmadığında gösterilen pastel degrade zemin ve ikon.
/// Hem kütüphane hem de "Bitkilerim" fotoğraflarında kullanılır.
class PlantPhotoPlaceholder extends StatelessWidget {
  const PlantPhotoPlaceholder({
    super.key,
    this.icon = Icons.local_florist_outlined,
    this.iconSize = 48,
  });

  final IconData icon;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.mint, AppColors.sage],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      alignment: Alignment.center,
      child: Icon(
        icon,
        size: iconSize,
        color: AppColors.darkGreen.withValues(alpha: 0.55),
      ),
    );
  }
}
