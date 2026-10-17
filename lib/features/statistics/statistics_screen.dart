import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/utils/currency_formatter.dart';
import '../../data/models/category_model.dart';
import '../../providers/record_provider.dart';
import 'widgets/spending_pie_chart.dart';
import 'widgets/category_detail_item.dart';

class StatisticsScreen extends ConsumerWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedMonth = ref.watch(selectedMonthProvider);
    final categorySummariesAsync = ref.watch(categorySummariesProvider);
    final totalSpendingAsync = ref.watch(totalSpendingProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          '支出统计',
          style: AppTypography.titleLarge,
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Month header
            _buildMonthHeader(selectedMonth),

            // Total spending
            totalSpendingAsync.when(
              data: (total) => _buildTotalSpending(total),
              loading: () => const SizedBox(
                height: 100,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, __) => const SizedBox.shrink(),
            ),

            // Pie chart
            categorySummariesAsync.when(
              data: (summaries) {
                if (summaries.isEmpty) {
                  return _buildEmptyState();
                }
                return Column(
                  children: [
                    SpendingPieChart(
                      summaries: summaries,
                      totalSpending: totalSpendingAsync.valueOrNull ?? 0,
                    ),
                    const SizedBox(height: 24),
                    _buildCategoryDetails(summaries),
                    const SizedBox(height: 32),
                  ],
                );
              },
              loading: () => const SizedBox(
                height: 300,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthHeader(DateTime month) {
    final monthFormat = DateFormat('yyyy年MM月', 'zh_CN');

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      color: AppColors.surface,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_today, color: AppColors.primary, size: 20),
          const SizedBox(width: 8),
          Text(
            monthFormat.format(month),
            style: AppTypography.titleMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildTotalSpending(double total) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24),
      color: AppColors.surface,
      child: Column(
        children: [
          Text(
            '本月支出',
            style: AppTypography.bodyMedium,
          ),
          const SizedBox(height: 8),
          Text(
            CurrencyFormatter.format(total),
            style: AppTypography.amountLarge.copyWith(
              fontSize: 42,
              color: AppColors.expense,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 80),
      child: Column(
        children: [
          Icon(
            Icons.pie_chart_outline,
            size: 80,
            color: AppColors.textHint,
          ),
          const SizedBox(height: 16),
          Text(
            '还没有记录',
            style: AppTypography.titleMedium.copyWith(
              color: AppColors.textHint,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '开始记账吧~',
            style: AppTypography.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryDetails(Map<int, double> summaries) {
    if (summaries.isEmpty) return const SizedBox.shrink();

    // Sort by amount descending
    final sortedEntries = summaries.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final total = summaries.values.fold(0.0, (sum, val) => sum + val);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '分类明细',
            style: AppTypography.titleMedium,
          ),
          const SizedBox(height: 16),
          ...sortedEntries.map((entry) {
            final category = getCategoryById(entry.key);
            if (category == null) return const SizedBox.shrink();

            final percentage = total > 0 ? (entry.value / total * 100) : 0.0;

            return CategoryDetailItem(
              category: category,
              amount: entry.value,
              percentage: percentage,
            );
          }),
        ],
      ),
    );
  }
}
