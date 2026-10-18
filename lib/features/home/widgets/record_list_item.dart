import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../data/database/app_database.dart';
import '../../../../providers/category_provider.dart';

/// 首页记录条目（V3.1）：
/// - V3.0：白卡圆角 14、图标块 38×38 圆角 11（收入绿底）、名称 14/备注 11、金额 14 粗体（支出深色、收入绿色）
/// - V3.1 (M3b)：长按弹出底部菜单（复记一笔 / 编辑 / 删除）
/// - V3.1 (M4 残留修复)：单击触发 onEdit
/// - V3.1 P0 优化：左滑露出【编辑 + 删除】双按钮
class RecordListItem extends ConsumerWidget {
  final Record record;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onCopy;

  const RecordListItem({
    super.key,
    required this.record,
    required this.onEdit,
    required this.onDelete,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final category = ref.watch(categoryByIdProvider(record.categoryId));
    final isExpense = record.type == 'expense';

    return Dismissible(
      key: Key('record_${record.id}'),
      // 仅左滑（endToStart = 从右向左滑）
      direction: DismissDirection.endToStart,
      // P0 优化：左滑露出【编辑 + 删除】两个操作按钮（而非只露删除）
      background: const SizedBox.shrink(),
      secondaryBackground: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            // 编辑按钮（橙色，左侧）
            Expanded(
              child: GestureDetector(
                onTap: () {
                  // 触发编辑：绕过 Dismissible 关闭，直接回调 onEdit
                  // 实际需要在 confirmDismiss 中处理；这里只作为 UI 占位
                },
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8A56A),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(14),
                      bottomLeft: Radius.circular(14),
                    ),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.edit_outlined, color: Colors.white, size: 20),
                      SizedBox(height: 2),
                      Text('编辑',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            ),
            // 删除按钮（红色，右侧）
            Expanded(
              child: Container(
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.expense,
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(14),
                    bottomRight: Radius.circular(14),
                  ),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.delete_outline, color: Colors.white, size: 20),
                    SizedBox(height: 2),
                    Text('删除',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        // 弹底部菜单让用户选择"编辑/删除"
        final action = await showModalBottomSheet<String>(
          context: context,
          backgroundColor: AppColors.surface,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (sheetCtx) {
            return SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.line,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    key: const Key('swipe-action-edit'),
                    leading:
                        const Icon(Icons.edit_outlined, color: AppColors.textPrimary),
                    title: const Text('编辑'),
                    onTap: () => Navigator.pop(sheetCtx, 'edit'),
                  ),
                  ListTile(
                    key: const Key('swipe-action-delete'),
                    leading: Icon(Icons.delete_outline, color: AppColors.expense),
                    title:
                        Text('删除', style: TextStyle(color: AppColors.expense)),
                    onTap: () => Navigator.pop(sheetCtx, 'delete'),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            );
          },
        );
        if (action == 'edit') {
          // 不关闭 Dismissible（return false 阻止 dismiss），但触发编辑
          // 用 Future.microtask 推迟到 confirmDismiss 返回后
          Future.microtask(onEdit);
          return false;
        }
        if (action == 'delete') {
          // 用户选删除 → 真删除
          return true;
        }
        // 取消（点空白或返回）
        return false;
      },
      onDismissed: (direction) {
        // 仅在用户确认删除时触发
        onDelete();
      },
      child: GestureDetector(
        // M4 残留修复 + M3b：单击编辑、长按弹菜单
        behavior: HitTestBehavior.opaque,
        onTap: onEdit,
        onLongPress: () => _showActions(context, onEdit, onDelete, onCopy),
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
      ),
    );
  }

  // V3.1 (M3b)：长按弹底部菜单（复记/编辑/删除）
  Future<void> _showActions(
    BuildContext context,
    VoidCallback onEdit,
    VoidCallback onDelete,
    VoidCallback onCopy,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.line,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                key: const Key('action-copy'),
                leading: const Icon(Icons.copy_rounded, color: AppColors.textPrimary),
                title: const Text('复记一笔'),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  onCopy();
                },
              ),
              ListTile(
                key: const Key('action-edit'),
                leading: const Icon(Icons.edit_outlined, color: AppColors.textPrimary),
                title: const Text('编辑'),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  onEdit();
                },
              ),
              ListTile(
                key: const Key('action-delete'),
                leading: Icon(Icons.delete_outline, color: AppColors.expense),
                title: Text('删除', style: TextStyle(color: AppColors.expense)),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  onDelete();
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}

