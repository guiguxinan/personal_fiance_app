import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../data/models/category_model.dart';

class SpendingPieChart extends StatefulWidget {
  final Map<int, double> summaries;
  final double totalSpending;

  const SpendingPieChart({
    super.key,
    required this.summaries,
    required this.totalSpending,
  });

  @override
  State<SpendingPieChart> createState() => _SpendingPieChartState();
}

class _SpendingPieChartState extends State<SpendingPieChart> {
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    if (widget.summaries.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 280,
      padding: const EdgeInsets.all(16),
      child: PieChart(
        PieChartData(
          pieTouchData: PieTouchData(
            touchCallback: (FlTouchEvent event, pieTouchResponse) {
              setState(() {
                if (!event.isInterestedForInteractions ||
                    pieTouchResponse == null ||
                    pieTouchResponse.touchedSection == null) {
                  touchedIndex = -1;
                  return;
                }
                touchedIndex =
                    pieTouchResponse.touchedSection!.touchedSectionIndex;
              });
            },
          ),
          borderData: FlBorderData(show: false),
          sectionsSpace: 2,
          centerSpaceRadius: 50,
          sections: _buildSections(),
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildSections() {
    final entries = widget.summaries.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return entries.asMap().entries.map((entry) {
      final index = entry.key;
      final mapEntry = entry.value;
      final category = getCategoryById(mapEntry.key);
      final isTouched = index == touchedIndex;
      final percentage =
          widget.totalSpending > 0 ? (mapEntry.value / widget.totalSpending * 100) : 0.0;

      return PieChartSectionData(
        color: AppColors.categoryColors[index % AppColors.categoryColors.length],
        value: mapEntry.value,
        title: isTouched ? '${percentage.toStringAsFixed(1)}%' : '',
        radius: isTouched ? 70 : 60,
        titleStyle: AppTypography.labelSmall.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
        titlePositionPercentageOffset: 0.55,
        badgeWidget: isTouched
            ? null
            : _buildBadge(category?.icon ?? '📌', index),
        badgePositionPercentageOffset: 0.95,
      );
    }).toList();
  }

  Widget _buildBadge(String icon, int index) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: AppColors.surface,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          icon,
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
