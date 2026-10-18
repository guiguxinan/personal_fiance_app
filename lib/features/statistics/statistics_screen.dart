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
import 'widgets/insight_card.dart';

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
            // N1：顶部一行双开关（左类型 收入/支出 flex:1，右粒度 年/月/日 flex:1.4），对齐原型 stats-switch-row
            _buildStatsSwitchRow(granularity, recordType),

            // Horizontal date picker
            _buildDatePicker(granularity, selectedDate),

            const SizedBox(height: 16),

            // Chart and details based on type
            _buildStatisticsContent(recordType),
          ],
        ),
      ),
    );
  }

  /// N1：顶部一行双开关（对齐原型 stats-switch-row：左类型 flex:1、右粒度 flex:1.4，灰底圆角10，选中白底+轻投影）
  Widget _buildStatsSwitchRow(TimeGranularity granularity, RecordType recordType) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
      child: Row(
        children: [
          Expanded(
            // 左类型开关 flex:5（与右粒度 7 近似原型 1:1.4，flex 必须为 int）
            flex: 5,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: AppColors.switchTrack,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  _buildStatsSeg(
                    '收入',
                    selected: recordType == RecordType.income,
                    income: true,
                    onTap: () {
                      ref.read(statisticsRecordTypeProvider.notifier).state =
                          RecordType.income;
                    },
                  ),
                  _buildStatsSeg(
                    '支出',
                    selected: recordType == RecordType.expense,
                    income: false,
                    onTap: () {
                      ref.read(statisticsRecordTypeProvider.notifier).state =
                          RecordType.expense;
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            // 右粒度开关 flex:7（与左 5 近似原型 1:1.4）
            flex: 7,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: AppColors.switchTrack,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  _buildStatsSeg(
                    '年',
                    selected: granularity == TimeGranularity.year,
                    onTap: () {
                      ref.read(statisticsGranularityProvider.notifier).state =
                          TimeGranularity.year;
                    },
                  ),
                  _buildStatsSeg(
                    '月',
                    selected: granularity == TimeGranularity.month,
                    onTap: () {
                      ref.read(statisticsGranularityProvider.notifier).state =
                          TimeGranularity.month;
                    },
                  ),
                  _buildStatsSeg(
                    '日',
                    selected: granularity == TimeGranularity.day,
                    onTap: () {
                      ref.read(statisticsGranularityProvider.notifier).state =
                          TimeGranularity.day;
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSeg(
    String label, {
    required bool selected,
    required VoidCallback onTap,
    bool income = false,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: selected
                ? const [
                    BoxShadow(
                      color: Color(0x0F000000),
                      blurRadius: 3,
                      offset: Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
              color: selected
                  ? (income ? AppColors.incomeDark : AppColors.primaryDark)
                  : AppColors.textSecondary,
            ),
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
    // M3 修复：日期条基于 selectedDate 的年/月生成，而非锁死 now
    final baseYear = selectedDate.year;
    final baseMonth = selectedDate.month;

    switch (granularity) {
      case TimeGranularity.year:
        items = List.generate(11, (i) => now.year - 5 + i);
        labelBuilder = (item) => '$item年';
        isSelectedBuilder = (item, date) => item == date.year;
        onSelected = (item) {
          ref.read(statisticsSelectedDateProvider.notifier).state =
              DateTime(item as int, baseMonth, 1);
        };
        break;
      case TimeGranularity.month:
        items = List.generate(12, (i) => i + 1);
        labelBuilder = (item) => '$item月';
        isSelectedBuilder = (item, date) => item == date.month && date.year == baseYear;
        onSelected = (item) {
          ref.read(statisticsSelectedDateProvider.notifier).state =
              DateTime(baseYear, item as int, 1);
        };
        break;
      case TimeGranularity.day:
        final daysInMonth = DateTime(baseYear, baseMonth + 1, 0).day;
        items = List.generate(daysInMonth, (i) => i + 1);
        labelBuilder = (item) => '$item日';
        isSelectedBuilder = (item, date) => item == date.day &&
            date.month == baseMonth && date.year == baseYear;
        onSelected = (item) {
          ref.read(statisticsSelectedDateProvider.notifier).state =
              DateTime(baseYear, baseMonth, item as int);
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

  Widget _buildStatisticsContent(RecordType recordType) {
    final selectedDate = ref.watch(statisticsSelectedDateProvider);
    final granularity = ref.watch(statisticsGranularityProvider);

    // S1 修复：按粒度构造起止日期范围
    DateTime startDate;
    DateTime endDate;

    switch (granularity) {
      case TimeGranularity.year:
        startDate = DateTime(selectedDate.year, 1, 1);
        endDate = DateTime(selectedDate.year, 12, 31, 23, 59, 59);
        break;
      case TimeGranularity.month:
        startDate = DateTime(selectedDate.year, selectedDate.month, 1);
        endDate = DateTime(selectedDate.year, selectedDate.month + 1, 0, 23, 59, 59);
        break;
      case TimeGranularity.day:
        startDate = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
        endDate = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 23, 59, 59);
        break;
    }

    // Get type-specific providers (S1 修复：用 range provider 替代 ByMonthAndType)
    final typeStr = recordType == RecordType.expense ? 'expense' : 'income';
    final params = (start: startDate, end: endDate, type: typeStr);
    final summariesAsync = ref.watch(categorySummariesByRangeProvider(params));
    final totalAsync = ref.watch(totalByRangeProvider(params));
    // V3.3 (B2)：另一类型的总额（洞察卡结余率需要收入+支出）
    final oppositeTypeStr = recordType == RecordType.expense ? 'income' : 'expense';
    final oppositeParams = (start: startDate, end: endDate, type: oppositeTypeStr);
    final oppositeTotalAsync = ref.watch(totalByRangeProvider(oppositeParams));
    // 当前 type 的分类列表（用于环形图色板 / 分类明细查 icon/color）
    final categories = ref.watch(categoriesByTypeProvider(typeStr)).valueOrNull ?? <Category>[];

    final typeLabel = recordType == RecordType.expense ? '支出' : '收入';
    final periodLabel = _getPeriodLabel(granularity, selectedDate);

    return Column(
      children: [
        // Total amount（N8：对齐原型 stats-summary，仅显示周期，不带类型后缀）
        totalAsync.when(
          data: (total) => _buildTotalAmount(total, periodLabel, recordType),
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
                // V3.3 (B2)：一句话洞察卡（总额下方、图表上方；无数据不展示）。
                // §10.6#4：前缀对齐原型「本月」（不随周期变化）。
                InsightCard(
                  incomeTotal: recordType == RecordType.expense
                      ? (oppositeTotalAsync.valueOrNull ?? 0)
                      : (totalAsync.valueOrNull ?? 0),
                  expenseTotal: recordType == RecordType.expense
                      ? (totalAsync.valueOrNull ?? 0)
                      : (oppositeTotalAsync.valueOrNull ?? 0),
                  summaries: summaries,
                  categories: categories,
                  periodLabel: '本月',
                  typeLabel: typeLabel,
                ),
                SpendingPieChart(
                  summaries: summaries,
                  categories: categories,
                  totalSpending: totalAsync.valueOrNull ?? 0,
                  // §10.6#3：环形图中心对齐原型「月支出 / 月收入」
                  typeLabel: '月$typeLabel',
                  isIncome: recordType == RecordType.income,
                ),
                const SizedBox(height: 24),
                _buildCategoryDetails(
                  summaries,
                  recordType,
                  categories,
                  startDate,
                  endDate,
                ),
                const SizedBox(height: 32),
              ],
            );
          },
          loading: () => const SizedBox(height: 300, child: Center(child: CircularProgressIndicator())),
          error: (e, _) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, color: AppColors.textHint, size: 40),
                const SizedBox(height: 8),
                Text(
                  '数据加载失败，请下拉刷新重试',
                  style: TextStyle(color: AppColors.textHint),
                ),
              ],
            ),
          ),
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

  Widget _buildTotalAmount(double total, String periodLabel, RecordType recordType) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24),
      color: AppColors.surface,
      child: Column(
        children: [
          Text(
            periodLabel,
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
    DateTime startDate,
    DateTime endDate,
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
              recordType: recordType == RecordType.expense ? 'expense' : 'income',
              startDate: startDate,
              endDate: endDate,
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

// S1 修复：按起止日期范围聚合（年/月/日粒度共用），替代按月硬编码
typedef DateTimeTypeRangeParams = ({DateTime start, DateTime end, String type});

final categorySummariesByRangeProvider = StreamProvider.family<Map<int, double>, DateTimeTypeRangeParams>((ref, params) async* {
  final databaseAsync = ref.watch(databaseProvider);

  final db = await databaseAsync.when(
    data: (db) => db,
    loading: () => throw Exception('Database loading'),
    error: (e, _) => throw e,
  );

  yield* db.watchCategorySummariesByRange(params.start, params.end, params.type);
});

final totalByRangeProvider = StreamProvider.family<double, DateTimeTypeRangeParams>((ref, params) async* {
  final databaseAsync = ref.watch(databaseProvider);

  final db = await databaseAsync.when(
    data: (db) => db,
    loading: () => throw Exception('Database loading'),
    error: (e, _) => throw e,
  );

  yield* db.watchTotalByRange(params.start, params.end, params.type);
});
