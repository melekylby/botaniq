import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/favorites_provider.dart';
import '../theme/app_colors.dart';

/// Yuvarlak, beyaz zeminli kalp butonu.
/// Hem bitki kartında hem de detay sayfasında kullanılır.
class FavoriteButton extends StatelessWidget {
  const FavoriteButton({super.key, required this.plantId});

  final String plantId;

  @override
  Widget build(BuildContext context) {
    // select: yalnızca BU bitkinin favori durumu değişince yeniden çizilir.
    final isFavorite = context.select<FavoritesProvider, bool>(
      (provider) => provider.isFavorite(plantId),
    );

    return Material(
      color: Colors.white.withValues(alpha: 0.92),
      shape: const CircleBorder(),
      child: IconButton(
        visualDensity: VisualDensity.compact,
        tooltip: isFavorite ? 'Favorilerden çıkar' : 'Favorilere ekle',
        icon: Icon(
          isFavorite ? Icons.favorite : Icons.favorite_border,
          color: isFavorite ? AppColors.heart : AppColors.darkGreen,
        ),
        onPressed: () => context.read<FavoritesProvider>().toggle(plantId),
      ),
    );
  }
}
