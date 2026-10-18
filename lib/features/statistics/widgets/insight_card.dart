import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/database/app_database.dart';

/// V3.3 (B2)：统计页「一句话洞察」卡（按 V3.1 原型 insight-card）。
///
/// 规则库生成（无 AI），无数据时不展示：
/// - 收入>0：结余率 = 结余/收入；≥30%「继续保持」、0~30%「注意控制支出」、<0「已超支，注意控制」
/// - 收入=0 且有支出：提示暂无收入
/// - 附当前查看类型占比最大的分类及占比
class InsightCard extends StatelessWidget {
  final double incomeTotal;
  final double expenseTotal;
  final Map<int, double> summaries; // 当前查看类型的分类聚合
  final List<Category> categories;
  final String periodLabel; // 如「2026年10月」
  final String typeLabel; // 当前查看类型：支出/收入

  const InsightCard({
    super.key,
    required this.incomeTotal,
    required this.expenseTotal,
    required this.summaries,
    required this.categories,
    required this.periodLabel,
    required this.typeLabel,
  });

  @override
  Widget build(BuildContext context) {
    final text = _buildText();
    if (text == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.insightBgStart, AppColors.insightBgEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('💡', style: TextStyle(fontSize: 14)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.insightText,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String? _buildText() {
    final hasData = incomeTotal > 0 || expenseTotal > 0;
    if (!hasData) return null; // 无数据不展示

    final surplus = incomeTotal - expenseTotal;
    final typeTotal = summaries.values.fold<double>(0.0, (s, v) => s + v);
    final topEntry = _topCategoryEntry();

    final StringBuffer sb = StringBuffer();
    if (incomeTotal > 0) {
      final rate = surplus / incomeTotal * 100;
      final tone = rate >= 30
          ? '继续保持'
          : (rate >= 0 ? '注意控制支出' : '已超支，注意控制');
      sb.write('$periodLabel结余率 ${rate.toStringAsFixed(1)}%，$tone');
      if (expenseTotal <= 0) {
        sb.write('；暂无支出记录');
      }
    } else {
      sb.write('$periodLabel暂无收入，当前${typeLabel}合计 ${CurrencyFormatter.format(typeTotal)}');
    }

    if (topEntry != null) {
      final topCategory = _categoryById(topEntry.key);
      final pct = typeTotal > 0 ? topEntry.value / typeTotal * 100 : 0.0;
      sb.write('；「${topCategory?.name ?? '未命名'}」占$typeLabel ${pct.toStringAsFixed(1)}%，为最大分类');
    }

    final text = sb.toString();
    return text.isEmpty ? null : text;
  }

  MapEntry<int, double>? _topCategoryEntry() {
    if (summaries.isEmpty) return null;
    final entries = summaries.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.first;
  }

  Category? _categoryById(int id) {
    for (final c in categories) {
      if (c.id == id) return c;
    }
    return null;
  }
}
