import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../providers/database_provider.dart';
import '../../providers/record_provider.dart';
import '../record/add_record_screen.dart';
import '../statistics/statistics_screen.dart';
import 'widgets/monthly_summary_card.dart';
import 'widgets/category_summary_list.dart';
import 'widgets/record_list_item.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedMonth = ref.watch(selectedMonthProvider);
    final recordsAsync = ref.watch(recordsByMonthProvider);
    final categorySummariesAsync = ref.watch(categorySummariesProvider);
    final totalSpendingAsync = ref.watch(totalSpendingProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header with month selector
            _buildHeader(context, ref, selectedMonth),

            // Main content
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(recordsByMonthProvider);
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    children: [
                      // Monthly summary card
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: totalSpendingAsync.when(
                          data: (total) => MonthlySummaryCard(
                            month: selectedMonth,
                            totalSpending: total,
                          ),
                          loading: () => const MonthlySummaryCard(
                            month: null,
                            totalSpending: 0,
                            isLoading: true,
                          ),
                          error: (_, __) => const MonthlySummaryCard(
                            month: null,
                            totalSpending: 0,
                          ),
                        ),
                      ),

                      // Category summary
                      categorySummariesAsync.when(
                        data: (summaries) => CategorySummaryList(
                          summaries: summaries,
                        ),
                        loading: () => const SizedBox(
                          height: 100,
                          child: Center(child: CircularProgressIndicator()),
                        ),
                        error: (_, __) => const SizedBox.shrink(),
                      ),

                      // Records list
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: recordsAsync.when(
                          data: (records) => _buildRecordsList(context, ref, records),
                          loading: () => const SizedBox(
                            height: 200,
                            child: Center(child: CircularProgressIndicator()),
                          ),
                          error: (e, _) => Center(
                            child: Text('Error: $e'),
                          ),
                        ),
                      ),

                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddRecord(context),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white, size: 32),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _buildBottomNavBar(context),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref, DateTime selectedMonth) {
    final monthFormat = DateFormat('yyyy年MM月');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              ref.read(selectedMonthProvider.notifier).state = DateTime(
                selectedMonth.year,
                selectedMonth.month - 1,
                1,
              );
            },
          ),
          Text(
            monthFormat.format(selectedMonth),
            style: AppTypography.titleLarge,
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {
              ref.read(selectedMonthProvider.notifier).state = DateTime(
                selectedMonth.year,
                selectedMonth.month + 1,
                1,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRecordsList(BuildContext context, WidgetRef ref, List records) {
    if (records.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
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
              '点击下方 + 按钮开始记账',
              style: AppTypography.bodyMedium,
            ),
          ],
        ),
      );
    }

    // Group records by date
    final groupedRecords = <String, List>{};
    final dateFormat = DateFormat('yyyy-MM-dd');

    for (final record in records) {
      final dateKey = dateFormat.format(record.recordDate);
      groupedRecords.putIfAbsent(dateKey, () => []).add(record);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: groupedRecords.entries.map((entry) {
        final recordsForDate = entry.value;
        final date = DateTime.parse(entry.key);
        final isToday = _isToday(date);
        final isYesterday = _isYesterday(date);

        String dateLabel;
        if (isToday) {
          dateLabel = '今天';
        } else if (isYesterday) {
          dateLabel = '昨天';
        } else {
          dateLabel = DateFormat('MM月dd日 E', 'zh_CN').format(date);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                dateLabel,
                style: AppTypography.labelLarge.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            ...recordsForDate.map((record) => RecordListItem(
                  record: record,
                  onEdit: () => _navigateToEditRecord(context, record),
                  onDelete: () => _confirmDelete(context, ref, record),
                )),
          ],
        );
      }).toList(),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  bool _isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day;
  }

  Widget _buildBottomNavBar(BuildContext context) {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const SizedBox(width: 48),
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: () => _navigateToStatistics(context),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  void _navigateToAddRecord(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AddRecordScreen(),
      ),
    );
  }

  void _navigateToEditRecord(BuildContext context, dynamic record) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddRecordScreen(recordToEdit: record),
      ),
    );
  }

  void _navigateToStatistics(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const StatisticsScreen(),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, dynamic record) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确定删除？'),
        content: const Text('删除后无法恢复'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final database = await ref.read(databaseProvider.future);
              await database.deleteRecord(record.id);
            },
            child: Text(
              '删除',
              style: TextStyle(color: AppColors.expense),
            ),
          ),
        ],
      ),
    );
  }
}
