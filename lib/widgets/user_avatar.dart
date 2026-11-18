import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Kullanıcı adının baş harfini gösteren yuvarlak avatar.
/// Aynı isim her zaman aynı rengi alır.
class UserAvatar extends StatelessWidget {
  const UserAvatar({super.key, required this.name, this.radius = 20});

  final String name;
  final double radius;

  static const _colors = [
    AppColors.sage,
    AppColors.mint,
    Color(0xFFE8D9C5),
    Color(0xFFCFE0C3),
    Color(0xFFD9C7B8),
  ];

  @override
  Widget build(BuildContext context) {
    final trimmed = name.trim();
    final initial = trimmed.isEmpty ? '?' : trimmed.substring(0, 1).toUpperCase();
    // Harf kodlarının toplamı: aynı isim → aynı renk.
    final colorIndex = trimmed.codeUnits.fold<int>(0, (sum, c) => sum + c) % _colors.length;

    return CircleAvatar(
      radius: radius,
      backgroundColor: _colors[colorIndex],
      child: Text(
        initial,
        style: TextStyle(
          color: AppColors.darkGreen,
          fontWeight: FontWeight.bold,
          fontSize: radius * 0.85,
        ),
      ),
    );
  }
}
