import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../data/models/category_model.dart';

class CategoryDetailItem extends StatelessWidget {
  final CategoryModel category;
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
    final colorIndex = defaultCategories.indexOf(category);
    final color = colorIndex >= 0 && colorIndex < AppColors.categoryColors.length
        ? AppColors.categoryColors[colorIndex]
        : AppColors.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Row(
            children: [
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
}
