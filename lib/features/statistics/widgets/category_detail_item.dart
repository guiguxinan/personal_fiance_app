import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../data/database/app_database.dart';

/// 统计页分类明细行：色点 + 图标 + 名称 + 金额 + 占比 + 进度条。
/// 颜色取自 [Category.color]（HEX）。
class CategoryDetailItem extends StatelessWidget {
  final Category category;
  final double amount;
  final double percentage;

  const CategoryDetailItem({
    super.key,
    required this.category,
    required this.amount,
    required this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    final color = _parseHexColor(category.color) ?? AppColors.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                category.icon,
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  category.name,
                  style: AppTypography.bodyLarge,
                ),
              ),
              Text(
                CurrencyFormatter.format(amount),
                style: AppTypography.amountMedium.copyWith(
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 50,
                child: Text(
                  '${percentage.toStringAsFixed(1)}%',
                  style: AppTypography.labelSmall,
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: AppColors.background,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Color? _parseHexColor(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    var s = hex.replaceFirst('#', '').trim();
    if (s.length == 6) s = 'FF$s';
    if (s.length != 8) return null;
    final v = int.tryParse(s, radix: 16);
    return v == null ? null : Color(v);
  }
}
