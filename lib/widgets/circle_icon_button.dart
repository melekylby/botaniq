import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Fotoğrafın üstünde okunaklı duran, beyaz zeminli yuvarlak ikon butonu.
/// Detay sayfalarındaki geri, düzenle ve sil butonlarında kullanılır.
class CircleIconButton extends StatelessWidget {
  const CircleIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return IconButton.filled(
      style: IconButton.styleFrom(
        backgroundColor: Colors.white.withValues(alpha: 0.92),
        foregroundColor: AppColors.darkGreen,
      ),
      tooltip: tooltip,
      icon: Icon(icon),
      onPressed: onPressed,
    );
  }
}
