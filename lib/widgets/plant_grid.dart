import 'package:flutter/material.dart';

import '../models/plant.dart';
import 'plant_card.dart';

/// İki sütunlu bitki kartı ızgarası.
/// Keşfet ve Favoriler ekranları aynı ızgarayı kullanır (kod tekrarı yok).
class PlantGrid extends StatelessWidget {
  const PlantGrid({
    super.key,
    required this.plants,
    this.padding = const EdgeInsets.fromLTRB(20, 0, 20, 24),
  });

  final List<Plant> plants;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: padding,
      // Kullanıcı listeyi kaydırınca klavye kapansın.
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 0.72,
      ),
      itemCount: plants.length,
      itemBuilder: (context, index) => PlantCard(plant: plants[index]),
    );
  }
}
