import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/my_plant.dart';
import '../providers/my_plants_provider.dart';

/// Bitkiyi sulandı olarak işaretler ve "Geri Al" seçenekli bir mesaj
/// gösterir. Yanlışlıkla basıldıysa kullanıcı tek dokunuşla geri alabilir.
Future<void> waterPlantWithUndo(BuildContext context, MyPlant plant) async {
  final provider = context.read<MyPlantsProvider>();
  final messenger = ScaffoldMessenger.of(context);
  final previousDate = plant.lastWateredAt;

  try {
    final updated = await provider.markWatered(plant);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('${plant.name} sulandı 💧'),
          action: SnackBarAction(
            label: 'Geri Al',
            onPressed: () =>
                provider.update(updated.copyWith(lastWateredAt: previousDate)),
          ),
        ),
      );
  } catch (error) {
    debugPrint('Sulama kaydedilemedi: $error');
    messenger.showSnackBar(
      const SnackBar(content: Text('Sulama kaydedilemedi. Lütfen tekrar dene.')),
    );
  }
}

/// "Suladım" butonu.
/// [large] true ise tam genişlikte büyük buton (detay sayfası),
/// false ise listelerde kullanılan küçük buton.
class WaterButton extends StatelessWidget {
  const WaterButton({super.key, required this.plant, this.large = false});

  final MyPlant plant;
  final bool large;

  @override
  Widget build(BuildContext context) {
    void onPressed() => waterPlantWithUndo(context, plant);

    if (large) {
      return SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: onPressed,
          icon: const Icon(Icons.water_drop),
          label: const Text('Suladım'),
        ),
      );
    }

    return FilledButton.tonal(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        visualDensity: VisualDensity.compact,
      ),
      child: const Text('Suladım'),
    );
  }
}
