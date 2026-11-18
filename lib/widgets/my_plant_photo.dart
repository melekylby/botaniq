import 'dart:io';

import 'package:flutter/material.dart';

import '../services/photo_storage_service.dart';
import 'plant_image.dart';

/// Kullanıcının kendi bitki fotoğrafını gösterir.
///
/// [photoName]: kalıcı klasördeki kayıtlı fotoğraf.
/// [filePath]: formda yeni seçilmiş, henüz kaydedilmemiş fotoğraf.
/// İkisi de yoksa ya da dosya okunamazsa pastel yer tutucu gösterilir.
class MyPlantPhoto extends StatelessWidget {
  const MyPlantPhoto({
    super.key,
    this.photoName,
    this.filePath,
    this.iconSize = 40,
  });

  final String? photoName;
  final String? filePath;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final File? file = filePath != null
        ? File(filePath!)
        : photoName != null
            ? PhotoStorageService.instance.fileFor(photoName!)
            : null;

    if (file == null) {
      return PlantPhotoPlaceholder(iconSize: iconSize);
    }

    return Image.file(
      file,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (context, error, stackTrace) =>
          PlantPhotoPlaceholder(iconSize: iconSize),
    );
  }
}
