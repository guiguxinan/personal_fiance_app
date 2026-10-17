import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../data/models/category_model.dart';

class CategorySummaryList extends StatelessWidget {
  final Map<int, double> summaries;

  const CategorySummaryList({
    super.key,
    required this.summaries,
  });

  @override
  Widget build(BuildContext context) {
    if (summaries.isEmpty) {
      return const SizedBox.shrink();
    }

    // Sort by amount descending
    final sortedEntries = summaries.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '分类支出',
            style: AppTypography.titleMedium,
          ),
          const SizedBox(height: 12),
          ...sortedEntries.map((entry) {
            final category = getCategoryById(entry.key);
            if (category == null) return const SizedBox.shrink();

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
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
                    '-${CurrencyFormatter.format(entry.value)}',
                    style: AppTypography.amountMedium,
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
