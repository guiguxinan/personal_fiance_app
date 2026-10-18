import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/database/app_database.dart';

/// 首页分类概览（严格对齐原型「轻记 V2」）：
/// 无外层容器，直接 4 列白色小 chip：图标 + 名称 + 纯数字金额（无符号、整数）
///
/// 颜色与图标来源：[Category]（Drift 实体，含 type/color/icon 字段），
/// 由父组件按当前 type 过滤后传入，覆盖 8 支出 + 5 收入全量。
class CategorySummaryList extends StatelessWidget {
  final Map<int, double> summaries;
  final List<Category> categories;

  const CategorySummaryList({
    super.key,
    required this.summaries,
    required this.categories,
  });

  @override
  Widget build(BuildContext context) {
    if (summaries.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 10),
        child: Text(
          '本月暂无记录',
          style: TextStyle(fontSize: 12, color: AppColors.textHint),
          textAlign: TextAlign.center,
        ),
      );
    }

    // 按 id 建索引 → O(1) 查找
    final byId = {for (final c in categories) c.id: c};

    // Sort by amount descending and take top 4
    final sortedEntries = summaries.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top4Entries = sortedEntries.take(4).toList();

    // M6 修复：弃用 GridView 固定 childAspectRatio（卡片高度不足导致金额溢出），
    // 改为 Row + Expanded 自适应高度布局——卡片高度由内容撑开，大字体/窄屏均不溢出。
    final top4 = top4Entries.take(4).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < top4.length; i++) ...[
            if (i > 0) const SizedBox(width: 6),
            Expanded(child: _buildCard(byId[top4[i].key], top4[i].value)),
          ],
          // 不足 4 个分类时用空槽占位，保持四列等宽
          for (var i = top4.length; i < 4; i++)
            const Expanded(child: SizedBox.shrink()),
        ],
      ),
    );
  }

  Widget _buildCard(Category? category, double amount) {
    if (category == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0x0A1F2A27),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            category.icon,
            style: const TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 3),
          Text(
            category.name,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 1),
          // 原型：金额前带 ¥ 符号（对齐 V3.1 原型高保真）
          Text(
            '¥${amount.round()}',
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
