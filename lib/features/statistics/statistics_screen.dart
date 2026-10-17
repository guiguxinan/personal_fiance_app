import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/utils/currency_formatter.dart';
import '../../data/database/app_database.dart';
import '../../providers/category_provider.dart';
import '../../providers/database_provider.dart';
import 'widgets/spending_pie_chart.dart';
import 'widgets/category_detail_item.dart';

// Time granularity enum
enum TimeGranularity { year, month, day }

// Expense/Income type
enum RecordType { expense, income }

// Providers for statistics screen
final statisticsGranularityProvider = StateProvider<TimeGranularity>((ref) => TimeGranularity.month);
final statisticsSelectedDateProvider = StateProvider<DateTime>((ref) => DateTime.now());
final statisticsRecordTypeProvider = StateProvider<RecordType>((ref) => RecordType.expense);

class StatisticsScreen extends ConsumerStatefulWidget {
  const StatisticsScreen({super.key});

  @override
  ConsumerState<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends ConsumerState<StatisticsScreen> {
  late ScrollController _dateScrollController;

  @override
  void initState() {
    super.initState();
    _dateScrollController = ScrollController();
  }

  @override
  void dispose() {
    _dateScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final granularity = ref.watch(statisticsGranularityProvider);
    final selectedDate = ref.watch(statisticsSelectedDateProvider);
    final recordType = ref.watch(statisticsRecordTypeProvider);

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
          '收支统计',
          style: AppTypography.titleLarge,
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Time granularity toggle
            _buildGranularityToggle(granularity),

            // Horizontal date picker
            _buildDatePicker(granularity, selectedDate),

            // Expense/Income type toggle
            _buildTypeToggle(recordType),

            const SizedBox(height: 16),

            // Chart and details based on type
            _buildStatisticsContent(recordType),
          ],
        ),
      ),
    );
  }

  Widget _buildGranularityToggle(TimeGranularity granularity) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: AppColors.surface,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildGranularitySegment('年', TimeGranularity.year, granularity),
          const SizedBox(width: 8),
          _buildGranularitySegment('月', TimeGranularity.month, granularity),
          const SizedBox(width: 8),
          _buildGranularitySegment('日', TimeGranularity.day, granularity),
        ],
      ),
    );
  }

  Widget _buildGranularitySegment(String label, TimeGranularity value, TimeGranularity current) {
    final isSelected = value == current;
    return GestureDetector(
      onTap: () {
        ref.read(statisticsGranularityProvider.notifier).state = value;
        // Reset date to current when changing granularity
        ref.read(statisticsSelectedDateProvider.notifier).state = DateTime.now();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryLight],
                )
              : null,
          color: isSelected ? null : AppColors.background,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: AppTypography.labelLarge.copyWith(
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildDatePicker(TimeGranularity granularity, DateTime selectedDate) {
    return Container(
      height: 80,
      color: AppColors.surface,
      child: _buildDateList(granularity, selectedDate),
    );
  }

  Widget _buildDateList(TimeGranularity granularity, DateTime selectedDate) {
    List<dynamic> items;
    String Function(dynamic) labelBuilder;
    bool Function(dynamic, DateTime) isSelectedBuilder;
    void Function(dynamic) onSelected;

    final now = DateTime.now();

    switch (granularity) {
      case TimeGranularity.year:
        items = List.generate(11, (i) => now.year - 5 + i);
        labelBuilder = (item) => '$item年';
        isSelectedBuilder = (item, date) => item == date.year;
        onSelected = (item) {
          ref.read(statisticsSelectedDateProvider.notifier).state =
              DateTime(item as int, now.month, now.day);
        };
        break;
      case TimeGranularity.month:
        items = List.generate(12, (i) => i + 1);
        labelBuilder = (item) => '$item月';
        isSelectedBuilder = (item, date) => item == date.month && date.year == now.year;
        onSelected = (item) {
          ref.read(statisticsSelectedDateProvider.notifier).state =
              DateTime(now.year, item as int, 1);
        };
        break;
      case TimeGranularity.day:
        final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
        items = List.generate(daysInMonth, (i) => i + 1);
        labelBuilder = (item) => '$item日';
        isSelectedBuilder = (item, date) => item == date.day &&
            date.month == now.month && date.year == now.year;
        onSelected = (item) {
          ref.read(statisticsSelectedDateProvider.notifier).state =
              DateTime(now.year, now.month, item as int);
        };
        break;
    }

    // Find initial scroll offset
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_dateScrollController.hasClients) {
        final selectedIndex = items.indexWhere((item) => isSelectedBuilder(item, selectedDate));
        if (selectedIndex >= 0) {
          final offset = (selectedIndex * 70.0) - (MediaQuery.of(context).size.width / 2) + 35;
          _dateScrollController.jumpTo(offset.clamp(0.0, _dateScrollController.position.maxScrollExtent));
        }
      }
    });

    return ListView.builder(
      controller: _dateScrollController,
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final selected = isSelectedBuilder(item, selectedDate);
        return GestureDetector(
          onTap: () {
            onSelected(item);
            // Auto-scroll to center
            final offset = (index * 70.0) - (MediaQuery.of(context).size.width / 2) + 35;
            _dateScrollController.animateTo(
              offset.clamp(0.0, _dateScrollController.position.maxScrollExtent),
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          },
          child: Container(
            width: 60,
            margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 12),
            decoration: BoxDecoration(
              gradient: selected
                  ? const LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryLight],
                    )
                  : null,
              color: selected ? null : AppColors.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  labelBuilder(item),
                  style: AppTypography.labelLarge.copyWith(
                    color: selected ? Colors.white : AppColors.textSecondary,
                  ),
                ),
                if (granularity == TimeGranularity.month && selected) ...[
                  const SizedBox(height: 2),
                  Text(
                    '${now.year}年',
                    style: AppTypography.labelSmall.copyWith(
                      color: selected ? Colors.white70 : AppColors.textHint,
                      fontSize: 10,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTypeToggle(RecordType recordType) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTypeSegment('支出', RecordType.expense, recordType),
          ),
          Expanded(
            child: _buildTypeSegment('收入', RecordType.income, recordType),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeSegment(String label, RecordType value, RecordType current) {
    final isSelected = value == current;
    return GestureDetector(
      onTap: () {
        ref.read(statisticsRecordTypeProvider.notifier).state = value;
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryLight],
                )
              : null,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            label,
            style: AppTypography.labelLarge.copyWith(
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatisticsContent(RecordType recordType) {
    final selectedDate = ref.watch(statisticsSelectedDateProvider);
    final granularity = ref.watch(statisticsGranularityProvider);

    // Calculate start date based on granularity
    DateTime startDate;

    switch (granularity) {
      case TimeGranularity.year:
        startDate = DateTime(selectedDate.year, 1, 1);
        break;
      case TimeGranularity.month:
        startDate = DateTime(selectedDate.year, selectedDate.month, 1);
        break;
      case TimeGranularity.day:
        startDate = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
        break;
    }

    // Get type-specific providers
    final typeStr = recordType == RecordType.expense ? 'expense' : 'income';
    final params = (month: startDate, type: typeStr);
    final summariesAsync = ref.watch(categorySummariesByTypeProvider(params));
    final totalAsync = ref.watch(totalByTypeProvider(params));
    // 当前 type 的分类列表（用于环形图色板 / 分类明细查 icon/color）
    final categories = ref.watch(categoriesByTypeProvider(typeStr)).valueOrNull ?? <Category>[];

    final typeLabel = recordType == RecordType.expense ? '支出' : '收入';
    final periodLabel = _getPeriodLabel(granularity, selectedDate);

    return Column(
      children: [
        // Total amount
        totalAsync.when(
          data: (total) => _buildTotalAmount(total, typeLabel, periodLabel, recordType),
          loading: () => const SizedBox(height: 100, child: Center(child: CircularProgressIndicator())),
          error: (_, __) => const SizedBox.shrink(),
        ),

        // Chart
        summariesAsync.when(
          data: (summaries) {
            if (summaries.isEmpty) {
              return _buildEmptyState();
            }
            return Column(
              children: [
                SpendingPieChart(
                  summaries: summaries,
                  categories: categories,
                  totalSpending: totalAsync.valueOrNull ?? 0,
                  typeLabel: '$periodLabel$typeLabel',
                  isIncome: recordType == RecordType.income,
                ),
                const SizedBox(height: 24),
                _buildCategoryDetails(summaries, recordType, categories),
                const SizedBox(height: 32),
              ],
            );
          },
          loading: () => const SizedBox(height: 300, child: Center(child: CircularProgressIndicator())),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
      ],
    );
  }

  String _getPeriodLabel(TimeGranularity granularity, DateTime date) {
    switch (granularity) {
      case TimeGranularity.year:
        return '${date.year}年';
      case TimeGranularity.month:
        return '${date.year}年${date.month}月';
      case TimeGranularity.day:
        return '${date.month}月${date.day}日';
    }
  }

  Widget _buildTotalAmount(double total, String typeLabel, String periodLabel, RecordType recordType) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24),
      color: AppColors.surface,
      child: Column(
        children: [
          Text(
            '$periodLabel$typeLabel',
            style: AppTypography.bodyMedium,
          ),
          const SizedBox(height: 8),
          Text(
            CurrencyFormatter.format(total),
            style: AppTypography.amountLarge.copyWith(
              fontSize: 42,
              color: recordType == RecordType.expense ? AppColors.expense : AppColors.income,
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
            '还没有记录，开始记账吧',
            style: AppTypography.titleMedium.copyWith(
              color: AppColors.textHint,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryDetails(
    Map<int, double> summaries,
    RecordType recordType,
    List<Category> categories,
  ) {
    if (summaries.isEmpty) return const SizedBox.shrink();

    final byId = {for (final c in categories) c.id: c};

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
            final category = byId[entry.key];
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

// New providers for type-filtered statistics
// Using a record to pass multiple parameters to family providers
typedef DateTimeTypeParams = ({DateTime month, String type});

final categorySummariesByTypeProvider = StreamProvider.family<Map<int, double>, DateTimeTypeParams>((ref, params) async* {
  final databaseAsync = ref.watch(databaseProvider);

  final db = await databaseAsync.when(
    data: (db) => db,
    loading: () => throw Exception('Database loading'),
    error: (e, _) => throw e,
  );

  yield* db.watchCategorySummariesByMonthAndType(params.month, params.type);
});

final totalByTypeProvider = StreamProvider.family<double, DateTimeTypeParams>((ref, params) async* {
  final databaseAsync = ref.watch(databaseProvider);

  final db = await databaseAsync.when(
    data: (db) => db,
    loading: () => throw Exception('Database loading'),
    error: (e, _) => throw e,
  );

  yield* db.watchTotalByMonthAndType(params.month, params.type);
});
