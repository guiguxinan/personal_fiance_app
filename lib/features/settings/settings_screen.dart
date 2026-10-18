import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/utils/data_exporter.dart';
import '../../core/utils/data_importer.dart';
import '../../data/database/app_database.dart' show Budget;
import '../../providers/database_provider.dart';
import '../../providers/record_provider.dart';
import '../category/category_manage_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(selectedMonthProvider);
    final budgetAsync = ref.watch(monthlyBudgetProvider(month));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('设置', style: AppTypography.titleLarge),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          const SizedBox(height: 16),

          // ── 段 1: 数据 ──
          _buildSectionHeader('数据'),
          // N3/I10：对齐原型「📤 导出数据（CSV）· 全部记录 ›」一行两列 + emoji 图标
          _buildSettingsItem(
            emoji: '📤',
            title: '导出数据（CSV）',
            rightText: '全部记录',
            onTap: () => _exportCsv(context, ref),
          ),
          _buildSettingsItem(
            emoji: '💾',
            title: '备份（JSON）',
            rightText: '记录+分类+预算',
            onTap: () => _exportJson(context, ref),
          ),
          _buildSettingsItem(
            emoji: '♻️',
            title: '恢复备份',
            rightText: '选择文件',
            onTap: () => _restoreJson(context, ref),
          ),
          const SizedBox(height: 24),

          // ── 段 2: 预算 ──
          _buildSectionHeader('预算'),
          _buildBudgetToggleRow(ref, budgetAsync),
          _buildBudgetAmountRow(context, ref, budgetAsync),
          const SizedBox(height: 24),

          // ── 段 3: 分类管理 ──
          _buildSectionHeader('分类管理'),
          _buildSettingsItem(
            key: const Key('settings-category-manage'),
            emoji: '🏷️',
            title: '支出 / 收入分类',
            rightText: '新增/隐藏/排序',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const CategoryManageScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 24),

          // ── 段 4: 关于 ──
          _buildSectionHeader('关于'),
          _buildSettingsItem(
            emoji: 'ℹ️',
            title: '版本',
            rightText: '轻记 v3.3 (build 4)',
            onTap: null,
          ),
          _buildSettingsItem(
            emoji: '🔒',
            title: '隐私',
            rightText: '纯本地 · 无账号 · 无广告',
            onTap: null,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title,
        style: AppTypography.labelLarge.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  /// I10/N3：设置行对齐原型（左 emoji 图标 13px + 文字；右辅助文 10px/占位色 + › 箭头）
  Widget _buildSettingsItem({
    String? emoji,
    required String title,
    String? subtitle,
    String? rightText,
    required VoidCallback? onTap,
    Key? key,
  }) {
    return Container(
      key: key,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      // 用 Material 包裹以提供 ListTile 的 ink splash 所需背景
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          leading: emoji != null
              ? Text(
                  emoji,
                  style: const TextStyle(fontSize: 18),
                )
              : null,
          title: Text(title, style: AppTypography.bodyLarge),
          subtitle: subtitle != null
              ? Text(subtitle, style: AppTypography.labelSmall)
              : null,
          trailing: (rightText != null || onTap != null)
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (rightText != null)
                      Text(
                        rightText,
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.textHint,
                        ),
                      ),
                    if (onTap != null) ...[
                      const SizedBox(width: 2),
                      const Icon(Icons.chevron_right, size: 16, color: AppColors.textHint),
                    ],
                  ],
                )
              : null,
          onTap: onTap,
        ),
      ),
    );
  }

  /// M1 修复：导出 CSV 改为「先预览内容 + 用户确认后保存/分享」
  /// 修复原因：原版点击后直接弹系统分享，用户期望"在 App 内选保存或取消"
  Future<void> _exportCsv(BuildContext context, WidgetRef ref) async {
    try {
      final database = await ref.read(databaseProvider.future);
      final file = await DataExporter(database).exportToCsv();
      // 文件已生成；弹预览对话框让用户选择「分享」或「取消」
      if (!context.mounted) return;
      final action = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('导出 CSV'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('已生成 ${file.uri.pathSegments.last}',
                    style: AppTypography.bodyMedium),
                const SizedBox(height: 8),
                Text('路径：${file.path}',
                    style: AppTypography.labelSmall.copyWith(color: AppColors.textHint)),
                const SizedBox(height: 12),
                const Text('点击"分享"唤起系统分享面板（可保存到文件或分享到其他 App）。',
                    style: AppTypography.bodyMedium),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'cancel'),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'share'),
              child: const Text('分享'),
            ),
          ],
        ),
      );
      if (action == 'share' && context.mounted) {
        await Share.shareXFiles(
          [XFile(file.path)],
          text: '轻记收支记录 ${DateTime.now().toIso8601String().substring(0, 10)}',
        );
      }
    } on EmptyExportException {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('暂无记录可导出')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('导出失败：$e'),
            backgroundColor: AppColors.expense,
          ),
        );
      }
    }
  }

  /// M1 修复：备份 JSON 改为「先预览内容 + 用户确认后保存/分享」
  Future<void> _exportJson(BuildContext context, WidgetRef ref) async {
    try {
      final database = await ref.read(databaseProvider.future);
      final file = await DataExporter(database).exportToJson(suffix: '备份');
      if (!context.mounted) return;
      final action = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('备份 (JSON)'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('已生成 ${file.uri.pathSegments.last}',
                    style: AppTypography.bodyMedium),
                const SizedBox(height: 8),
                Text('路径：${file.path}',
                    style: AppTypography.labelSmall.copyWith(color: AppColors.textHint)),
                const SizedBox(height: 12),
                const Text('点击"分享"唤起系统分享面板（可保存到文件或分享到其他 App）。',
                    style: AppTypography.bodyMedium),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'cancel'),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'share'),
              child: const Text('分享'),
            ),
          ],
        ),
      );
      if (action == 'share' && context.mounted) {
        await Share.shareXFiles(
          [XFile(file.path)],
          text: '轻记备份 ${DateTime.now().toIso8601String().substring(0, 10)}',
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('备份失败：$e'),
            backgroundColor: AppColors.expense,
          ),
        );
      }
    }
  }

  Future<void> _restoreJson(BuildContext context, WidgetRef ref) async {
    try {
      // 1) 让用户选择备份文件
      final picked = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        allowMultiple: false,
      );
      if (picked == null || picked.files.single.path == null) return;
      final backupFile = File(picked.files.single.path!);

      if (!context.mounted) return;
      // 2) 第一步确认
      final first = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('恢复备份'),
          content: const Text('恢复将覆盖当前数据，继续前会自动备份当前状态。是否继续？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('继续'),
            ),
          ],
        ),
      );
      if (first != true) return;

      // 3) 自动备份当前状态
      final database = await ref.read(databaseProvider.future);
      final preRestore = await DataExporter(database).exportToJson(suffix: '恢复前备份');

      if (!context.mounted) return;
      // 4) 第二步确认（最终）
      final second = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('确认恢复？'),
          content: Text(
            '即将覆盖当前数据。\n当前数据已备份到：${preRestore.uri.pathSegments.last}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('恢复', style: TextStyle(color: AppColors.expense)),
            ),
          ],
        ),
      );
      if (second != true) return;

      // 5) 执行导入
      final result = await DataImporter(database).importFromJson(backupFile);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: result.success ? AppColors.primary : AppColors.expense,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('恢复失败：$e'),
            backgroundColor: AppColors.expense,
          ),
        );
      }
    }
  }

  /// N11：预算开关行对齐原型（🎯 月度预算 + 40×24 圆角12 粉色开关，滑块 20px 白圆带轻投影）
  Widget _buildBudgetToggleRow(
    WidgetRef ref,
    AsyncValue<Budget?> budgetAsync,
  ) {
    final month = ref.watch(selectedMonthProvider);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: budgetAsync.when(
          data: (b) {
            final enabled = b?.enabled ?? false;
            return InkWell(
              onTap: () async {
                final db = await ref.read(databaseProvider.future);
                await db.upsertMonthlyBudget(
                  month: month,
                  amount: b?.amount ?? 0,
                  enabled: !enabled,
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    const Text('🎯', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text('月度预算', style: AppTypography.bodyLarge),
                    ),
                    _PinkSwitch(value: enabled),
                  ],
                ),
              ),
            );
          },
          loading: () => const ListTile(title: Text('加载中...')),
          error: (_, __) => const ListTile(title: Text('预算加载失败')),
        ),
      ),
    );
  }

  Widget _buildBudgetAmountRow(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<Budget?> budgetAsync,
  ) {
    final month = ref.watch(selectedMonthProvider);
    return budgetAsync.when(
      data: (b) {
        final amt = b?.amount ?? 0;
        // V3.3 P0 优化：预算金额行前加 💰 emoji 图标（与 🎯 月度预算开关行风格一致）
        return _buildSettingsItem(
          emoji: '💰',
          title: '预算金额',
          rightText: amt == 0 ? '未设置' : '¥${amt.toStringAsFixed(2)}',
          onTap: () async {
            final controller = TextEditingController(
              text: amt == 0 ? '' : amt.toStringAsFixed(2),
            );
            final formKey = GlobalKey<FormState>();
            final newAmount = await showDialog<double>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('设置月度预算'),
                content: Form(
                  key: formKey,
                  child: TextFormField(
                    controller: controller,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      hintText: '请输入金额',
                      prefixText: '¥ ',
                    ),
                    // V3.3 (O2)：PRD §10.7.3 校验 > 0
                    validator: (v) {
                      final parsed = double.tryParse((v ?? '').trim());
                      if (parsed == null || parsed <= 0) {
                        return '请输入大于 0 的金额';
                      }
                      return null;
                    },
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('取消'),
                  ),
                  TextButton(
                    onPressed: () {
                      if (!(formKey.currentState?.validate() ?? false)) return;
                      final v = double.tryParse(controller.text.trim());
                      Navigator.pop(ctx, v);
                    },
                    child: const Text('确定'),
                  ),
                ],
              ),
            );
            if (newAmount != null && newAmount > 0) {
              final db = await ref.read(databaseProvider.future);
              await db.upsertMonthlyBudget(
                month: month,
                amount: newAmount,
                enabled: b?.enabled ?? true,
              );
            }
          },
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

/// N11：对齐原型 .switch：40×24 圆角12（关闭 #E0D5DA / 开启粉 #E88BA3），滑块 20px 白圆带轻投影。
/// 纯展示组件：点击由外层 InkWell 处理，此处不拦截。
class _PinkSwitch extends StatelessWidget {
  final bool value;

  const _PinkSwitch({required this.value});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 40,
        height: 24,
        decoration: BoxDecoration(
          color: value ? AppColors.primary : const Color(0xFFE0D5DA),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(2),
        child: Align(
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 20,
            height: 20,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Color(0x26000000),
                  blurRadius: 4,
                  offset: Offset(0, 1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
