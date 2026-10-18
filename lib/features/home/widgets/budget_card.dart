import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';

/// V3.1 (M4b)：本月预算进度条卡片
/// 状态色：≤70% 粉 #E88BA3；70-100% 黄 #E8C46A；>100% 红 #D96B5F + 「已超支 ¥Z」
class BudgetCard extends StatelessWidget {
  final double budgetAmount;
  final double expenseAmount;

  const BudgetCard({
    super.key,
    required this.budgetAmount,
    required this.expenseAmount,
  });

  @override
  Widget build(BuildContext context) {
    final pct = budgetAmount > 0 ? (expenseAmount / budgetAmount) : 0.0;
    final isOver = pct > 1.0;
    final overAmount = isOver ? (expenseAmount - budgetAmount) : 0.0;

    final barColor = pct <= 0.7
        ? const Color(0xFFE88BA3) // 粉
        : pct <= 1.0
            ? const Color(0xFFE8C46A) // 黄
            : AppColors.expense; // 红

    // 本月剩余天数（含今天）= (lastDay - today) + 1
    final now = DateTime.now();
    final lastDay = DateTime(now.year, now.month + 1, 0).day;
    final remainingDays = (lastDay - now.day + 1).clamp(1, lastDay);
    final remainingBudget = (budgetAmount - expenseAmount).clamp(0.0, double.infinity);
    final dailyAvg = remainingBudget / remainingDays;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A1F2A27),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '本月预算',
                style: TextStyle(fontSize: 12, color: AppColors.textHint),
              ),
              Text(
                CurrencyFormatter.format(budgetAmount),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: pct.clamp(0.0, 1.0).toDouble(),
              minHeight: 8,
              backgroundColor: AppColors.line,
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${(pct * 100).round()}%',
                style: TextStyle(
                  fontSize: 11,
                  color: barColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (!isOver)
                Text(
                  '剩余日均 ${CurrencyFormatter.format(dailyAvg)}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textHint,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                )
              else
                Text(
                  '已超支 ${CurrencyFormatter.format(overAmount)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.expense,
                    fontWeight: FontWeight.w600,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
