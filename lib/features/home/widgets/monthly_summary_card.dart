import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../providers/record_provider.dart';

/// 首页顶部总览卡片（严格对齐原型「轻记 V2」）：
/// 胶囊切换（支出/收入）→ 标签「本月支出（元）」→ 大金额 ¥xxx.xx → 环比胶囊「↑ 较上月 +x.x%」
class MonthlySummaryCard extends ConsumerWidget {
  final double totalSpending;
  final double prevMonthTotal;
  final bool isLoading;

  const MonthlySummaryCard({
    super.key,
    required this.totalSpending,
    this.prevMonthTotal = 0,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedType = ref.watch(selectedTypeProvider);
    final isExpense = selectedType == 'expense';

    final gradientColors = isExpense
        ? [
            AppColors.expenseGradientStart,
            AppColors.expenseGradientMid,
            AppColors.expenseGradientEnd,
          ]
        : [
            AppColors.incomeGradientStart,
            AppColors.incomeGradientMid,
            AppColors.incomeGradientEnd,
          ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD47B95).withValues(alpha: 0.5),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 胶囊切换：收入 / 支出（U1：收入置前）
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(999),
            ),
            padding: const EdgeInsets.all(3),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildToggleButton(
                  label: '收入',
                  isSelected: !isExpense,
                  onTap: () {
                    ref.read(selectedTypeProvider.notifier).state = 'income';
                  },
                ),
                _buildToggleButton(
                  label: '支出',
                  isSelected: isExpense,
                  onTap: () {
                    ref.read(selectedTypeProvider.notifier).state = 'expense';
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // 标签：本月支出（元）
          Text(
            isExpense ? '本月支出（元）' : '本月收入（元）',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white,
            ).copyWith(
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 4),
          // 大金额：¥xxx.xx
          Text(
            isLoading ? '...' : CurrencyFormatter.format(totalSpending),
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              fontFeatures: [FontFeature.tabularFigures()],
              letterSpacing: -0.5,
            ),
          ),
          if (!isLoading) ...[
            const SizedBox(height: 8),
            _buildChangeChip(),
          ],
        ],
      ),
    );
  }

  Widget _buildToggleButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
            color: isSelected ? AppColors.primaryDark : Colors.white.withValues(alpha: 0.9),
          ),
        ),
      ),
    );
  }

  /// 环比胶囊：↑ 较上月 +12.5% / ↓ 较上月 -12.5%；上月无数据时不展示
  Widget _buildChangeChip() {
    if (prevMonthTotal <= 0) return const SizedBox.shrink();

    final pct = (totalSpending - prevMonthTotal) / prevMonthTotal * 100;
    final isUp = pct >= 0;
    final arrow = isUp ? '↑' : '↓';
    final sign = isUp ? '+' : '-';
    final text = '$arrow 较上月 $sign${pct.abs().toStringAsFixed(1)}%';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          color: Colors.white,
          fontFeatures: [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}
