import 'package:flutter/material.dart';

import '../models/plant.dart';
import '../repositories/plant_repository.dart';
import '../widgets/empty_state.dart';
import '../widgets/plant_grid.dart';
import 'favorites_screen.dart';

/// Keşfet: bitki kütüphanesi, arama ve kategori filtreleri.
///
/// Arama metni ve seçili kategori yalnızca bu ekranı ilgilendirdiği için
/// Provider yerine basit setState ile tutuluyor.
class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final _repository = const PlantRepository();
  final _searchController = TextEditingController();

  String _query = '';
  PlantCategory? _selectedCategory; // null = "Tümü"

  @override
  void dispose() {
    _searchController.dispose(); // Bellek sızıntısını önler.
    super.dispose();
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() => _query = '');
  }

  @override
  Widget build(BuildContext context) {
    final plants = _repository.search(
      query: _query,
      category: _selectedCategory,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Keşfet'),
        actions: [
          IconButton(
            tooltip: 'Favorilerim',
            icon: const Icon(Icons.favorite_border),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const FavoritesScreen()),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _query = value),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Bitki ara...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Temizle',
                        icon: const Icon(Icons.close),
                        onPressed: _clearSearch,
                      ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                _buildCategoryChip('Tümü', null),
                for (final category in PlantCategory.values)
                  _buildCategoryChip(category.label, category),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: plants.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: EmptyState(
                        icon: Icons.search_off,
                        title: 'Sonuç bulunamadı',
                        message: 'Farklı bir isim ya da kategori deneyebilirsin.',
                      ),
                    ),
                  )
                : PlantGrid(plants: plants),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String label, PlantCategory? category) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: _selectedCategory == category,
        showCheckmark: false,
        onSelected: (_) => setState(() => _selectedCategory = category),
      ),
    );
  }
}
