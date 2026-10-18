import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';

/// V3.1 (M4a)：本月结余卡片
/// 结余 = 当月收入 − 当月支出；正数绿、负数警示色（#D96B5F）
class SurplusCard extends StatelessWidget {
  final double income;
  final double expense;
  final VoidCallback onTap;

  const SurplusCard({
    super.key,
    required this.income,
    required this.expense,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final surplus = income - expense;
    final isPositive = surplus >= 0;
    final surplusColor = isPositive ? AppColors.income : AppColors.expense;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
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
              const Text(
                '本月结余',
                style: TextStyle(fontSize: 12, color: AppColors.textHint),
              ),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    (isPositive ? '' : '-') + CurrencyFormatter.format(surplus.abs()),
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: surplusColor,
                      fontFeatures: const [FontFeature.tabularFigures()],
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    surplus > 0 ? '结余' : surplus < 0 ? '透支' : '持平',
                    style: TextStyle(fontSize: 12, color: surplusColor),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _miniLine('收入', income, AppColors.income)),
                  const SizedBox(width: 12),
                  Expanded(child: _miniLine('支出', expense, AppColors.expense)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _miniLine(String label, double value, Color color) {
    return Text.rich(
      TextSpan(children: [
        TextSpan(
          text: '$label ',
          style: const TextStyle(fontSize: 11, color: AppColors.textHint),
        ),
        TextSpan(
          text: CurrencyFormatter.format(value),
          style: TextStyle(
            fontSize: 11,
            color: color,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ]),
    );
  }
}
