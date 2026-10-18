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
                  // I3：左滑按钮图标对齐原型 emoji（✏️ 编辑 / 🗑 删除）
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('✏️', style: TextStyle(fontSize: 15)),
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
                    Text('🗑', style: TextStyle(fontSize: 15)),
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
        // 弹中央菜单让用户选择"编辑/删除"（N12：对齐原型中央弹窗样式）
        final action = await showDialog<String>(
          context: context,
          builder: (dialogCtx) => Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 96),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _menuAction(
                    dialogCtx,
                    '✏️',
                    '编辑',
                    AppColors.textPrimary,
                    () => Navigator.pop(dialogCtx, 'edit'),
                    key: const Key('swipe-action-edit'),
                  ),
                  _menuAction(
                    dialogCtx,
                    '🗑',
                    '删除',
                    AppColors.expense,
                    () => Navigator.pop(dialogCtx, 'delete'),
                    key: const Key('swipe-action-delete'),
                  ),
                ],
              ),
            ),
          ),
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

  // V3.1 (M3b) + N12：长按弹中央菜单（复记/编辑/删除），对齐原型 longpress-menu 中央 200px 弹窗
  Future<void> _showActions(
    BuildContext context,
    VoidCallback onEdit,
    VoidCallback onDelete,
    VoidCallback onCopy,
  ) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogCtx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 96),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _menuAction(
                dialogCtx,
                '🔁',
                '复记一笔',
                AppColors.textPrimary,
                () {
                  Navigator.pop(dialogCtx);
                  onCopy();
                },
                key: const Key('action-copy'),
              ),
              _menuAction(
                dialogCtx,
                '✏️',
                '编辑',
                AppColors.textPrimary,
                () {
                  Navigator.pop(dialogCtx);
                  onEdit();
                },
                key: const Key('action-edit'),
              ),
              _menuAction(
                dialogCtx,
                '🗑',
                '删除',
                AppColors.expense,
                () {
                  Navigator.pop(dialogCtx);
                  onDelete();
                },
                key: const Key('action-delete'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 中央弹窗菜单项（emoji 图标 + 文案，对齐原型）
  Widget _menuAction(
    BuildContext context,
    String emoji,
    String label,
    Color color,
    VoidCallback onTap, {
    Key? key,
  }) {
    return InkWell(
      key: key,
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 15)),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(fontSize: 14, color: color),
            ),
          ],
        ),
      ),
    );
  }
}

