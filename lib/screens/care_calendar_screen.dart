import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/my_plant.dart';
import '../providers/my_plants_provider.dart';
import '../services/watering_schedule.dart';
import '../theme/app_colors.dart';
import '../widgets/empty_state.dart';
import '../widgets/section_header.dart';
import '../widgets/watering_task_tile.dart';

/// Bakım Takvimi: aylık görünüm. Sulama olan günlerin altında nokta
/// görünür; bir güne dokununca o günün görevleri listelenir.
///
/// Hazır takvim paketi kullanmadık: ızgara 7 sütunlu basit bir GridView.
/// Böylece hem bağımlılık eklemedik hem de kodun her satırı açıklanabilir.
class CareCalendarScreen extends StatefulWidget {
  const CareCalendarScreen({super.key});

  static Future<void> open(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CareCalendarScreen()),
    );
  }

  @override
  State<CareCalendarScreen> createState() => _CareCalendarScreenState();
}

class _CareCalendarScreenState extends State<CareCalendarScreen> {
  static const _weekdayLabels = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];

  late final DateTime _today;
  late DateTime _visibleMonth; // Gösterilen ayın 1. günü
  late DateTime _selectedDay;

  @override
  void initState() {
    super.initState();
    _today = DateUtils.dateOnly(DateTime.now());
    _selectedDay = _today;
    _visibleMonth = DateTime(_today.year, _today.month);
  }

  bool get _isCurrentMonth =>
      _visibleMonth.year == _today.year && _visibleMonth.month == _today.month;

  void _changeMonth(int offset) {
    setState(() {
      // DateTime ay taşmalarını kendisi düzeltir (13. ay = sonraki yılın Ocak'ı).
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + offset);
    });
  }

  @override
  Widget build(BuildContext context) {
    final plants = context.watch<MyPlantsProvider>().plants;
    final localizations = MaterialLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Bakım Takvimi')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      tooltip: 'Önceki ay',
                      icon: const Icon(Icons.chevron_left),
                      // Geçmiş aylar için sulama kaydı tutmuyoruz.
                      onPressed: _isCurrentMonth ? null : () => _changeMonth(-1),
                    ),
                    Expanded(
                      child: Text(
                        localizations.formatMonthYear(_visibleMonth),
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Sonraki ay',
                      icon: const Icon(Icons.chevron_right),
                      onPressed: () => _changeMonth(1),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    for (final label in _weekdayLabels)
                      Expanded(
                        child: Center(
                          child: Text(
                            label,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.darkGreen.withValues(alpha: 0.55),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                _buildMonthGrid(plants),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SectionHeader(
            title: DateUtils.isSameDay(_selectedDay, _today)
                ? 'Bugün'
                : localizations.formatFullDate(_selectedDay),
          ),
          const SizedBox(height: 12),
          ..._buildTasksForSelectedDay(plants),
        ],
      ),
    );
  }

  Widget _buildMonthGrid(List<MyPlant> plants) {
    final daysInMonth =
        DateUtils.getDaysInMonth(_visibleMonth.year, _visibleMonth.month);
    // Ay hangi gün başlıyorsa önüne o kadar boş kutu koyuyoruz (Pazartesi = 1).
    final leadingBlanks = _visibleMonth.weekday - 1;

    return GridView.builder(
      shrinkWrap: true, // ListView içinde olduğu için kendi boyunu alsın.
      physics: const NeverScrollableScrollPhysics(),
      itemCount: leadingBlanks + daysInMonth,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
      ),
      itemBuilder: (context, index) {
        if (index < leadingBlanks) return const SizedBox.shrink();

        final day = DateTime(
          _visibleMonth.year,
          _visibleMonth.month,
          index - leadingBlanks + 1,
        );
        final taskCount =
            WateringSchedule.plantsDueOn(plants, day, today: _today).length;

        return _DayCell(
          day: day,
          isToday: DateUtils.isSameDay(day, _today),
          isSelected: DateUtils.isSameDay(day, _selectedDay),
          isPast: day.isBefore(_today),
          hasTasks: taskCount > 0,
          onTap: () => setState(() => _selectedDay = day),
        );
      },
    );
  }

  List<Widget> _buildTasksForSelectedDay(List<MyPlant> plants) {
    if (_selectedDay.isBefore(_today)) {
      return const [
        EmptyState(
          icon: Icons.history,
          title: 'Geçmiş bir gün',
          message: 'Takvim bugünü ve sonraki günlerin sulama planını gösterir.',
        ),
      ];
    }

    final duePlants =
        WateringSchedule.plantsDueOn(plants, _selectedDay, today: _today);

    if (duePlants.isEmpty) {
      return [
        EmptyState(
          icon: Icons.event_available_outlined,
          title: 'Bu gün sulama yok',
          message: plants.isEmpty
              ? 'Bitkilerim sekmesinden bitki eklediğinde planın burada görünecek.'
              : 'Bitkilerin bu gün su beklemiyor.',
        ),
      ];
    }

    final isToday = DateUtils.isSameDay(_selectedDay, _today);
    return [
      for (final plant in duePlants)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          // "Suladım" butonu yalnızca bugün için gösterilir.
          child: WateringTaskTile(plant: plant, showWaterButton: isToday),
        ),
    ];
  }
}

/// Takvimdeki tek bir gün kutusu.
class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.isToday,
    required this.isSelected,
    required this.isPast,
    required this.hasTasks,
    required this.onTap,
  });

  final DateTime day;
  final bool isToday;
  final bool isSelected;
  final bool isPast;
  final bool hasTasks;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color textColor;
    if (isSelected) {
      textColor = Colors.white;
    } else if (isPast) {
      textColor = AppColors.darkGreen.withValues(alpha: 0.3);
    } else {
      textColor = AppColors.darkGreen;
    }

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? AppColors.darkGreen : null,
          borderRadius: BorderRadius.circular(12),
          border: isToday && !isSelected
              ? Border.all(color: AppColors.sage, width: 1.5)
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${day.day}',
              style: TextStyle(
                color: textColor,
                fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
              ),
            ),
            const SizedBox(height: 3),
            // Sulama olan günlerin altında küçük bir nokta.
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: hasTasks
                    ? (isSelected ? AppColors.mint : AppColors.earth)
                    : Colors.transparent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
