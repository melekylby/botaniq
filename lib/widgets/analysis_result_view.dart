import 'package:flutter/material.dart';

import '../models/analysis_result.dart';
import '../models/plant.dart';
import '../repositories/plant_repository.dart';
import '../screens/add_edit_plant_screen.dart';
import '../screens/plant_detail_screen.dart';
import '../theme/app_colors.dart';
import 'bullet_list.dart';
import 'care_info_tile.dart';
import 'empty_state.dart';
import 'section_header.dart';

/// Yapay zekâ analiz sonucunu gösterir: olası tür, sağlık durumu,
/// olası sorunlar, uyarılar ve bakım bilgileri.
class AnalysisResultView extends StatelessWidget {
  const AnalysisResultView({
    super.key,
    required this.result,
    required this.photoPath,
  });

  final AnalysisResult result;
  final String photoPath;

  @override
  Widget build(BuildContext context) {
    if (!result.isPlant) {
      return const EmptyState(
        icon: Icons.help_outline,
        title: 'Bitki bulunamadı',
        message:
            'Fotoğrafta bir bitki tanıyamadık. Bitkiyi yakından ve iyi ışıkta çekip tekrar dene.',
      );
    }

    // Tanınan tür kütüphanemizde varsa ona bağlantı veriyoruz.
    final libraryMatch =
        const PlantRepository().findByScientificName(result.scientificName);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _IdentificationCard(result: result, libraryMatch: libraryMatch),
        const SizedBox(height: 16),
        _HealthCard(result: result),
        if (result.issues.isNotEmpty) ...[
          const SizedBox(height: 24),
          const SectionHeader(title: 'Olası Sorunlar'),
          const SizedBox(height: 12),
          for (final issue in result.issues)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _IssueCard(issue: issue),
            ),
        ],
        if (result.warnings.isNotEmpty) ...[
          const SizedBox(height: 12),
          const SectionHeader(title: 'Dikkat Edilmesi Gerekenler'),
          const SizedBox(height: 12),
          BulletList(
            items: result.warnings,
            icon: Icons.info_outline,
            iconColor: AppColors.earth,
          ),
        ],
        const SizedBox(height: 16),
        const SectionHeader(title: 'Bakım Gereksinimleri'),
        const SizedBox(height: 12),
        CareInfoTile(icon: Icons.wb_sunny_outlined, title: 'Işık', value: result.light),
        const SizedBox(height: 10),
        CareInfoTile(icon: Icons.water_drop_outlined, title: 'Sulama', value: result.water),
        const SizedBox(height: 10),
        CareInfoTile(
          icon: Icons.thermostat_outlined,
          title: 'Sıcaklık',
          value: result.temperature,
        ),
        const SizedBox(height: 10),
        CareInfoTile(icon: Icons.cloud_outlined, title: 'Nem', value: result.humidity),
        if (result.careTips.isNotEmpty) ...[
          const SizedBox(height: 24),
          const SectionHeader(title: 'Bakım İpuçları'),
          const SizedBox(height: 12),
          BulletList(items: result.careTips),
        ],
        const SizedBox(height: 20),
        FilledButton.icon(
          icon: const Icon(Icons.add),
          label: const Text('Bitkilerime Ekle'),
          onPressed: () => AddEditPlantScreen.open(
            context,
            initialSpecies: libraryMatch,
            initialSpeciesName: libraryMatch == null ? result.commonName : null,
            initialPhotoPath: photoPath,
          ),
        ),
      ],
    );
  }
}

class _IdentificationCard extends StatelessWidget {
  const _IdentificationCard({required this.result, required this.libraryMatch});

  final AnalysisResult result;
  final Plant? libraryMatch;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final percent = (result.confidence * 100).round();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'OLASI TÜR',
            style: textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
              color: AppColors.earth,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            result.commonName.isEmpty ? 'Bilinmeyen bitki' : result.commonName,
            style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          if (result.scientificName.isNotEmpty)
            Text(
              result.scientificName,
              style: textTheme.titleMedium?.copyWith(
                fontStyle: FontStyle.italic,
                color: AppColors.darkGreen.withValues(alpha: 0.7),
              ),
            ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: result.confidence,
                    minHeight: 8,
                    backgroundColor: AppColors.mint,
                    color: AppColors.darkGreen,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '%$percent eşleşme',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          if (result.isLowConfidence) ...[
            const SizedBox(height: 8),
            Text(
              'Güven düşük: sonuç hatalı olabilir. Farklı açıdan bir fotoğraf daha dene.',
              style: textTheme.bodySmall?.copyWith(color: AppColors.earth),
            ),
          ],
          if (result.description.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(result.description, style: textTheme.bodyMedium?.copyWith(height: 1.5)),
          ],
          if (libraryMatch != null) ...[
            const SizedBox(height: 14),
            OutlinedButton.icon(
              icon: const Icon(Icons.menu_book_outlined),
              label: Text('${libraryMatch!.name} kütüphanede'),
              onPressed: () => PlantDetailScreen.open(context, libraryMatch!),
            ),
          ],
        ],
      ),
    );
  }
}

class _HealthCard extends StatelessWidget {
  const _HealthCard({required this.result});

  final AnalysisResult result;

  @override
  Widget build(BuildContext context) {
    final (Color background, Color foreground, IconData icon) =
        switch (result.healthStatus) {
      HealthStatus.healthy => (AppColors.mint, AppColors.darkGreen, Icons.check_circle_outline),
      HealthStatus.attention => (const Color(0xFFF5EBDD), const Color(0xFF8A6A4F), Icons.warning_amber_rounded),
      HealthStatus.unhealthy => (const Color(0xFFF6DEDC), const Color(0xFF9C4A45), Icons.healing_outlined),
    };

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: foreground, size: 30),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.healthStatus.label,
                  style: TextStyle(
                    color: foreground,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (result.healthSummary.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    result.healthSummary,
                    style: TextStyle(color: foreground, height: 1.4),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _IssueCard extends StatelessWidget {
  const _IssueCard({required this.issue});

  final HealthIssue issue;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  issue.name,
                  style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.mint,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '%${(issue.likelihood * 100).round()} olasılık',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          if (issue.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(issue.description, style: textTheme.bodyMedium?.copyWith(height: 1.45)),
          ],
          if (issue.careSteps.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Önerilen adımlar',
              style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            BulletList(
              items: issue.careSteps,
              icon: Icons.check,
              iconColor: AppColors.darkGreen,
            ),
          ],
        ],
      ),
    );
  }
}
