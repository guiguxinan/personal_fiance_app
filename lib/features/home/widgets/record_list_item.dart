import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/database/app_database.dart';
import '../../../providers/category_provider.dart';

/// 首页记录条目（V3.1）：
/// - V3.0：白卡圆角 14、图标块 38×38 圆角 11（收入绿底）、名称 14/备注 11、金额 14 粗体（支出深色、收入绿色）
/// - V3.1 (M3b)：长按弹出底部菜单（复记一笔 / 编辑 / 删除）
/// - V3.1 (M4 残留修复)：单击触发 onEdit
/// - V3.3 P0 优化：左滑只露出 46px 宽的【编辑 + 删除】两个按钮（不撑满容器），点击即生效不弹中间菜单
class RecordListItem extends ConsumerStatefulWidget {
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
  ConsumerState<RecordListItem> createState() => _RecordListItemState();
}

class _RecordListItemState extends ConsumerState<RecordListItem> {
  bool _swiped = false;

  @override
  Widget build(BuildContext context) {
    final record = widget.record;
    final category = ref.watch(categoryByIdProvider(record.categoryId));
    final isExpense = record.type == 'expense';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: const Color(0x0A1F2A27),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          children: [
            // 主内容（向左偏移露出右侧按钮区）
            Transform.translate(
              offset: _swiped ? const Offset(-92, 0) : Offset.zero,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  if (_swiped) {
                    setState(() => _swiped = false);
                    return;
                  }
                  widget.onEdit();
                },
                onLongPress: _swiped
                    ? null
                    : () => _showActions(
                        context,
                        widget.onEdit,
                        widget.onDelete,
                        widget.onCopy,
                      ),
                child: Container(
                  color: AppColors.surface,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: isExpense
                              ? AppColors.primaryLight
                              : AppColors.incomeLight,
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
                          color: isExpense
                              ? AppColors.textPrimary
                              : AppColors.income,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // 右侧 46px 宽操作按钮：编辑 + 删除（不撑满容器，原型 V3.1 act-btn 宽 46px）
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 150),
                opacity: _swiped ? 1.0 : 0.0,
                child: Row(
                  children: [
                    _buildActionButton(
                      emoji: '✏️',
                      label: '编辑',
                      color: const Color(0xFFE8A857),
                      onTap: () {
                        setState(() => _swiped = false);
                        widget.onEdit();
                      },
                    ),
                    _buildActionButton(
                      emoji: '🗑',
                      label: '删除',
                      color: AppColors.expense,
                      onTap: () {
                        setState(() => _swiped = false);
                        widget.onDelete();
                      },
                    ),
                  ],
                ),
              ),
            ),
            // 手势识别层：左滑露按钮 / 右滑收回（避免与主内容点击冲突）
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onHorizontalDragEnd: (details) {
                  final v = details.primaryVelocity ?? 0;
                  if (v < -150) {
                    setState(() => _swiped = true);
                  } else if (v > 150) {
                    setState(() => _swiped = false);
                  }
                },
                onTap: () {
                  if (_swiped) {
                    setState(() => _swiped = false);
                  } else {
                    widget.onEdit();
                  }
                },
                onLongPress: () {
                  if (!_swiped) {
                    _showActions(
                      context,
                      widget.onEdit,
                      widget.onDelete,
                      widget.onCopy,
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 操作按钮：宽 46px、高撑满容器，emoji + 文字竖排
  Widget _buildActionButton({
    required String emoji,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 46,
        color: color,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 15)),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // V3.1 (M3b) + N12：长按弹中央菜单（复记/编辑/删除）
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

  /// 中央弹窗菜单项
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
