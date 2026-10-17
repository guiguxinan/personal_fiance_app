import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../data/database/app_database.dart';
import '../../../../providers/category_provider.dart';

/// 首页记录条目（严格对齐原型「轻记 V2」）：
/// 白卡圆角 14、图标块 38×38 圆角 11（收入绿底）、名称 14/备注 11、金额 14 粗体（支出深色、收入绿色）
class RecordListItem extends ConsumerWidget {
  final Record record;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const RecordListItem({
    super.key,
    required this.record,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final category = ref.watch(categoryByIdProvider(record.categoryId));
    final isExpense = record.type == 'expense';

    return Dismissible(
      key: Key('record_${record.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: AppColors.expense,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(
          Icons.delete_outline,
          color: Colors.white,
        ),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('确定删除？'),
            content: const Text('删除后无法恢复'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(
                  '删除',
                  style: TextStyle(color: AppColors.expense),
                ),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) => onDelete(),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: const Color(0x0A1F2A27),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: isExpense ? AppColors.primaryLight : AppColors.incomeLight,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Center(
                child: Text(
                  category?.icon ?? '📌',
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category?.name ?? '未知',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (record.note != null && record.note!.isNotEmpty)
                    Text(
                      record.note!,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textHint,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            Text(
              isExpense
                  ? '-${CurrencyFormatter.format(record.amount)}'
                  : '+${CurrencyFormatter.format(record.amount)}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()],
                // 原型：支出为深色主文字，收入为绿色
                color: isExpense ? AppColors.textPrimary : AppColors.income,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
