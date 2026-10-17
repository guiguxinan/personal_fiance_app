import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../data/database/app_database.dart';

/// 统计页环形图（donut）。
/// 颜色取自 [Category.color]（HEX 字符串），由父组件按当前 type 传入分类列表。
class SpendingPieChart extends StatefulWidget {
  final Map<int, double> summaries;
  final List<Category> categories;
  final double totalSpending;
  final String typeLabel; // e.g., "月支出" or "月收入"
  final bool isIncome; // 中心数字颜色：收入绿 / 支出粉

  const SpendingPieChart({
    super.key,
    required this.summaries,
    required this.categories,
    required this.totalSpending,
    required this.typeLabel,
    this.isIncome = false,
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

    final byId = {for (final c in widget.categories) c.id: c};

    return Container(
      height: 280,
      padding: const EdgeInsets.all(16),
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
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
              centerSpaceRadius: 70, // Larger center space for donut
              sections: _buildSections(byId),
            ),
          ),
          // 中心两行：typeLabel(12px 灰) + 金额(15px 粗)
          // 原型：支出为深色主文字，收入为绿色
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.typeLabel,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textHint,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                CurrencyFormatter.format(widget.totalSpending),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: widget.isIncome ? AppColors.income : AppColors.textPrimary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildSections(Map<int, Category> byId) {
    final entries = widget.summaries.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return entries.asMap().entries.map((entry) {
      final index = entry.key;
      final mapEntry = entry.value;
      final category = byId[mapEntry.key];
      final isTouched = index == touchedIndex;
      final color = _parseHexColor(category?.color) ??
          AppColors.categoryColors[index % AppColors.categoryColors.length];
      final percentage =
          widget.totalSpending > 0 ? (mapEntry.value / widget.totalSpending * 100) : 0.0;

      return PieChartSectionData(
        color: color,
        value: mapEntry.value,
        title: isTouched ? '${percentage.toStringAsFixed(1)}%' : '',
        radius: isTouched ? 60 : 50,
        titleStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
        titlePositionPercentageOffset: 0.55,
        badgeWidget: isTouched
            ? null
            : _buildBadge(category?.icon ?? '📌'),
        badgePositionPercentageOffset: 0.95,
      );
    }).toList();
  }

  /// 把 '#E88BA3' / 'E88BA3' 解析为 Color；解析失败回退 null。
  Color? _parseHexColor(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    var s = hex.replaceFirst('#', '').trim();
    if (s.length == 6) s = 'FF$s';
    if (s.length != 8) return null;
    final v = int.tryParse(s, radix: 16);
    return v == null ? null : Color(v);
  }

  Widget _buildBadge(String icon) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: AppColors.surface,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
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
