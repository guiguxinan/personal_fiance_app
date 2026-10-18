import 'dart:ui' show ImageFilter;

import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../data/database/app_database.dart';
import '../../providers/category_provider.dart';
import '../../providers/database_provider.dart';
import '../../providers/record_provider.dart';
import '../record/add_record_screen.dart';
import '../settings/settings_screen.dart';
import '../statistics/statistics_screen.dart';
import 'widgets/budget_card.dart';
import 'widgets/category_summary_list.dart';
import 'widgets/monthly_summary_card.dart';
import 'widgets/record_list_item.dart';
import 'widgets/surplus_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedMonth = ref.watch(selectedMonthProvider);
    final selectedType = ref.watch(selectedTypeProvider);
    final recordsAsync = ref.watch(recordsByMonthProvider);
    final categorySummariesAsync = ref.watch(categorySummariesProvider);
    final totalSpendingAsync = ref.watch(totalSpendingProvider);
    final prevMonthTotalAsync = ref.watch(prevMonthTotalProvider);
    // V3.1 (M4a/M4b)
    final surplusAsync = ref.watch(monthlySurplusProvider(selectedMonth));
    final budgetAsync = ref.watch(monthlyBudgetProvider(selectedMonth));
    // 当前收支类型下的分类（用于 Top4 chip 的 icon/name/color）
    final categories =
        ref.watch(categoriesByTypeProvider(selectedType)).valueOrNull ?? <Category>[];

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(recordsByMonthProvider);
            ref.invalidate(monthlySurplusProvider(selectedMonth));
            ref.invalidate(monthlyBudgetProvider(selectedMonth));
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 月份切换器 + 设置入口（M7）
                _buildHeader(context, ref, selectedMonth),

                // 总览卡片
                totalSpendingAsync.when(
                  data: (total) => prevMonthTotalAsync.when(
                    data: (prev) => MonthlySummaryCard(
                      totalSpending: total,
                      prevMonthTotal: prev,
                    ),
                    loading: () => MonthlySummaryCard(
                      totalSpending: total,
                      prevMonthTotal: 0,
                      isLoading: true,
                    ),
                    error: (_, __) => MonthlySummaryCard(totalSpending: total),
                  ),
                  loading: () => const MonthlySummaryCard(
                    totalSpending: 0,
                    isLoading: true,
                  ),
                  error: (_, __) => const MonthlySummaryCard(totalSpending: 0),
                ),

                // M4a 结余卡片
                const SizedBox(height: 12),
                surplusAsync.when(
                  data: (stats) => SurplusCard(
                    income: stats.income,
                    expense: stats.expense,
                    onTap: () => _navigateToStatistics(context),
                  ),
                  loading: () => const SizedBox(
                    height: 80,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (_, __) => const SizedBox.shrink(),
                ),

                // M4b 预算进度条（开启且金额>0 时展示）
                const SizedBox(height: 12),
                budgetAsync.when(
                  data: (budget) {
                    if (budget == null || !budget.enabled || budget.amount <= 0) {
                      return const SizedBox.shrink();
                    }
                    final expense = surplusAsync.valueOrNull?.expense ?? 0.0;
                    return BudgetCard(
                      budgetAmount: budget.amount,
                      expenseAmount: expense,
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),

                // Top4 分类概览
                const SizedBox(height: 12),
                categorySummariesAsync.when(
                  data: (summaries) => CategorySummaryList(
                    summaries: summaries,
                    categories: categories,
                  ),
                  loading: () => const SizedBox(
                    height: 80,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (_, __) => const SizedBox.shrink(),
                ),

                // 记录列表（按天分组）
                recordsAsync.when(
                  data: (records) => _buildRecordsList(context, ref, records),
                  loading: () => const SizedBox(
                    height: 200,
                    child: Center(child: CircularProgressIndicator()),
                  ),
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
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(context),
    );
  }

  /// 月份切换器 + V3.1 (M7) 设置入口
  Widget _buildHeader(BuildContext context, WidgetRef ref, DateTime selectedMonth) {
    final monthFormat = DateFormat('yyyy年MM月');

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 6, 4, 12),
      child: Row(
        children: [
          _buildMonthArrow(
            ref: ref,
            selectedMonth: selectedMonth,
            delta: -1,
            icon: Icons.chevron_left,
          ),
          Expanded(
            child: Center(
              child: Text(
                monthFormat.format(selectedMonth),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
          _buildMonthArrow(
            ref: ref,
            selectedMonth: selectedMonth,
            delta: 1,
            icon: Icons.chevron_right,
          ),
          // M7：设置入口
          const SizedBox(width: 4),
          IconButton(
            key: const Key('settings-btn'),
            icon: const Icon(Icons.settings_outlined, size: 22),
            color: AppColors.textHint,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () => _navigateToSettings(context),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthArrow({
    required WidgetRef ref,
    required DateTime selectedMonth,
    required int delta,
    required IconData icon,
  }) {
    return GestureDetector(
      onTap: () {
        ref.read(selectedMonthProvider.notifier).state =
            DateTime(selectedMonth.year, selectedMonth.month + delta, 1);
      },
      child: Container(
        width: 30,
        height: 30,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 16,
          color: AppColors.textHint,
        ),
      ),
    );
  }

  Widget _buildRecordsList(BuildContext context, WidgetRef ref, List records) {
    if (records.isEmpty) {
      // 原型空态：单行居中「还没有记录，点下方 + 记一笔吧～」
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        child: const Text(
          '还没有记录，点下方 + 记一笔吧～',
          style: TextStyle(fontSize: 13, color: AppColors.textHint),
          textAlign: TextAlign.center,
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

        // Calculate total for the day
        final dayTotal = recordsForDate.fold<double>(
          0,
          (sum, record) => sum + record.amount,
        );
        final recordCount = recordsForDate.length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 原型 day-label：左右两端对齐「今天 / 2笔 · ¥174」（整数金额）
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    dateLabel,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textHint,
                    ),
                  ),
                  Text(
                    '$recordCount笔 · ¥${dayTotal.round()}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textHint,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
            ...recordsForDate.map((record) => RecordListItem(
                  record: record,
                  onEdit: () => _navigateToEditRecord(context, record),
                  onDelete: () => _confirmDelete(context, ref, record),
                  onCopy: () => _navigateToPrefillRecord(context, record),
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

  /// 底部导航（对齐原型 tabbar：毛玻璃白底、首页 + 中间 FAB + 统计）
  /// 容器高 110：上 30px 为 FAB 上凸区（保持可命中），下 80px 为毛玻璃条
  Widget _buildBottomNavBar(BuildContext context) {
    return SizedBox(
      height: 110,
      child: Stack(
        children: [
          // 毛玻璃底条（含左右两个 tab）
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 80,
            child: Container(
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: AppColors.line),
                ),
              ),
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    color: Colors.white.withValues(alpha: 0.98),
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 20),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildTabItem(
                            context: context,
                            icon: Icons.home,
                            label: '首页',
                            active: true,
                            onTap: () {},
                          ),
                        ),
                        const SizedBox(width: 56), // FAB 占位
                        Expanded(
                          child: _buildTabItem(
                            context: context,
                            icon: Icons.bar_chart,
                            label: '统计',
                            active: false,
                            onTap: () => _navigateToStatistics(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          // 中间 FAB：上凸 30px（对齐原型 fab）
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Center(
              child: _buildFab(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    final color = active ? AppColors.primaryDark : AppColors.textHint;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 原型 tab-item.active::before 顶部小横条
          Container(
            width: 20,
            height: 3,
            decoration: BoxDecoration(
              color: active ? AppColors.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 6),
          Icon(icon, size: 22, color: color),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: active ? FontWeight.w600 : FontWeight.w400,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// 中间 FAB（对齐原型 fab：56px 圆形粉色渐变、+ 号）
  Widget _buildFab(BuildContext context) {
    return GestureDetector(
      key: const Key('fab'),
      onTap: () => _navigateToAddRecord(context),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.expenseGradientStart, AppColors.primary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.5),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Icon(
          Icons.add,
          color: Colors.white,
          size: 28,
          weight: 300,
        ),
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

  // M3b 复记：携带 prefillRecord 进入记账页，生成新记录
  void _navigateToPrefillRecord(BuildContext context, dynamic record) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddRecordScreen(prefillRecord: record),
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

  // M7：跳设置页
  void _navigateToSettings(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const SettingsScreen(),
      ),
    );
  }

  // M2 删除撤销：物理删除 + 内存缓存 + 5s 撤销 SnackBar
  void _confirmDelete(BuildContext context, WidgetRef ref, dynamic record) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('确定删除？'),
        content: const Text('删除后 5 秒内可在底部"撤销"恢复'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(dialogCtx).pop();
              final database = await ref.read(databaseProvider.future);
              // 1) 物理删除
              await database.deleteRecord(record.id);
              // 2) 缓存被删记录（M2 物理删除+内存缓存方案）
              ref.read(lastDeletedRecordProvider.notifier).state =
                  record as Record;
              // 3) 立即关闭任何已存在的撤销 SnackBar
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              // 4) 弹 5s 撤销 SnackBar
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('已删除'),
                  duration: const Duration(seconds: 5),
                  action: SnackBarAction(
                    label: '撤销',
                    onPressed: () async {
                      final cached = ref.read(lastDeletedRecordProvider);
                      if (cached == null) return;
                      // 重新插入（auto-increment 新 id，保留原字段）
                      await database.insertRecord(RecordsCompanion.insert(
                        amount: cached.amount,
                        categoryId: cached.categoryId,
                        recordDate: cached.recordDate,
                        note: drift.Value(cached.note),
                        type: drift.Value(cached.type),
                      ));
                      ref.read(lastDeletedRecordProvider.notifier).state = null;
                    },
                  ),
                ),
              );
              // 5) 5s 后清空缓存（仅当未撤销时）
              Future.delayed(const Duration(seconds: 5), () {
                if (ref.read(lastDeletedRecordProvider) == record) {
                  ref.read(lastDeletedRecordProvider.notifier).state = null;
                }
              });
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
