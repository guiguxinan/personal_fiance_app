import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../data/database/app_database.dart';
import '../../../../providers/database_provider.dart';

/// V3.3 (B3)：统计页分类明细行 → 点击展开近期记录子明细（日期 + 金额）。
/// 颜色取自 [Category.color]（HEX）；展开内容为「按范围+类型+分类」倒序取最近 5 条。
typedef CategoryRangeParams = ({DateTime start, DateTime end, String type, int categoryId});

final recentRecordsByCategoryProvider =
    FutureProvider.family<List<Record>, CategoryRangeParams>((ref, params) async {
  final database = await ref.watch(databaseProvider.future);
  return database.getRecordsByRangeAndCategory(
    params.start,
    params.end,
    params.type,
    params.categoryId,
  );
});

class CategoryDetailItem extends ConsumerStatefulWidget {
  final Category category;
  final double amount;
  final double percentage;
  final String recordType;
  final DateTime startDate;
  final DateTime endDate;

  const CategoryDetailItem({
    super.key,
    required this.category,
    required this.amount,
    required this.percentage,
    required this.recordType,
    required this.startDate,
    required this.endDate,
  });

  @override
  ConsumerState<CategoryDetailItem> createState() => _CategoryDetailItemState();
}

class _CategoryDetailItemState extends ConsumerState<CategoryDetailItem> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final color = _parseHexColor(widget.category.color) ?? AppColors.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          // 可点击主行
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(8),
            child: Row(
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
                  widget.category.icon,
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.category.name,
                    style: AppTypography.bodyLarge,
                  ),
                ),
                Text(
                  CurrencyFormatter.format(widget.amount),
                  style: AppTypography.amountMedium.copyWith(fontSize: 14),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 50,
                  child: Text(
                    '${widget.percentage.toStringAsFixed(1)}%',
                    style: AppTypography.labelSmall,
                    textAlign: TextAlign.right,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  _expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  size: 16,
                  color: AppColors.textHint,
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: widget.percentage / 100,
              backgroundColor: AppColors.background,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
            ),
          ),
          // B3：展开子明细
          if (_expanded) ...[
            const SizedBox(height: 4),
            _CategoryDetailSubList(
              params: (
                start: widget.startDate,
                end: widget.endDate,
                type: widget.recordType,
                categoryId: widget.category.id,
              ),
              isIncome: widget.recordType == 'income',
            ),
          ],
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

/// 展开后的子明细：M月d日 + 金额；无记录时提示。
class _CategoryDetailSubList extends ConsumerWidget {
  final CategoryRangeParams params;
  final bool isIncome;

  const _CategoryDetailSubList({required this.params, required this.isIncome});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(recentRecordsByCategoryProvider(params));

    return async.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      error: (_, __) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          '明细加载失败',
          style: TextStyle(fontSize: 10, color: AppColors.textHint),
        ),
      ),
      data: (records) {
        if (records.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              '本期无记录',
              style: TextStyle(fontSize: 10, color: AppColors.textHint),
            ),
          );
        }
        return Container(
          margin: const EdgeInsets.only(top: 4),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: records.map((r) {
              final sign = isIncome ? '+' : '-';
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${r.recordDate.month}月${r.recordDate.day}日',
                        style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
                      ),
                    ),
                    Text(
                      '$sign${CurrencyFormatter.format(r.amount)}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isIncome ? AppColors.income : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
