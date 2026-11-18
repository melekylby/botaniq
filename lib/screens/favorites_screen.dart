import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/favorites_provider.dart';
import '../repositories/plant_repository.dart';
import '../widgets/empty_state.dart';
import '../widgets/plant_grid.dart';

/// Kullanıcının favorilere eklediği bitkiler.
class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // watch: favoriler değişince (ör. bir kalbe basılınca) ekran güncellenir.
    final favoriteIds = context.watch<FavoritesProvider>().ids;
    final plants = const PlantRepository()
        .getAll()
        .where((plant) => favoriteIds.contains(plant.id))
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Favorilerim')),
      body: plants.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(20),
              child: Align(
                alignment: Alignment.topCenter,
                child: EmptyState(
                  icon: Icons.favorite_border,
                  title: 'Henüz favorin yok',
                  message:
                      'Beğendiğin bitkilerdeki kalp simgesine dokunarak onları buraya ekleyebilirsin.',
                ),
              ),
            )
          : PlantGrid(
              plants: plants,
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            ),
    );
  }
}
