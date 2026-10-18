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
          _buildSettingsItem(
            icon: Icons.table_chart_outlined,
            title: '导出 CSV',
            subtitle: '导出所有记账记录为 CSV 文件',
            onTap: () => _exportCsv(context, ref),
          ),
          _buildSettingsItem(
            icon: Icons.backup_outlined,
            title: '备份 (JSON)',
            subtitle: '导出完整数据备份（含自定义分类）',
            onTap: () => _exportJson(context, ref),
          ),
          _buildSettingsItem(
            icon: Icons.restore,
            title: '恢复备份',
            subtitle: '从备份文件恢复数据',
            onTap: () => _restoreJson(context, ref),
          ),
          const SizedBox(height: 24),

          // ── 段 2: 预算 ──
          _buildSectionHeader('预算'),
          _buildBudgetToggle(ref, budgetAsync),
          _buildBudgetAmountRow(context, ref, budgetAsync),
          const SizedBox(height: 24),

          // ── 段 3: 分类管理 ──
          _buildSectionHeader('分类'),
          _buildSettingsItem(
            key: const Key('settings-category-manage'),
            icon: Icons.category_outlined,
            title: '分类管理',
            subtitle: '管理自定义分类',
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
            icon: Icons.info_outline,
            title: '版本信息',
            subtitle: '轻记 v3.1 (build 2)',
            onTap: null,
          ),
          _buildSettingsItem(
            icon: Icons.lock_outline,
            title: '隐私',
            subtitle: '纯本地 · 无账号 · 无广告',
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

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required String subtitle,
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
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.primary),
          ),
          title: Text(title, style: AppTypography.bodyLarge),
          subtitle: Text(subtitle, style: AppTypography.labelSmall),
          trailing: onTap != null ? const Icon(Icons.chevron_right) : null,
          onTap: onTap,
        ),
      ),
    );
  }

  Future<void> _exportCsv(BuildContext context, WidgetRef ref) async {
    try {
      final database = await ref.read(databaseProvider.future);
      final file = await DataExporter(database).exportToCsv();
      // share_plus 10.x：使用 Share.shareXFiles（兼容 API）
      await Share.shareXFiles(
        [XFile(file.path)],
        text: '轻记收支记录 ${DateTime.now().toIso8601String().substring(0, 10)}',
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('已导出 CSV'),
            backgroundColor: AppColors.primary,
          ),
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

  Future<void> _exportJson(BuildContext context, WidgetRef ref) async {
    try {
      final database = await ref.read(databaseProvider.future);
      final file = await DataExporter(database).exportToJson(suffix: '备份');
      await Share.shareXFiles(
        [XFile(file.path)],
        text: '轻记备份 ${DateTime.now().toIso8601String().substring(0, 10)}',
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('已保存到 ${file.uri.pathSegments.last}'),
            backgroundColor: AppColors.primary,
          ),
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

  Widget _buildBudgetToggle(
    WidgetRef ref,
    AsyncValue<Budget?> budgetAsync,
  ) {
    final month = ref.watch(selectedMonthProvider);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      // Material 包装避免 ListTile 在 DecoratedBox 内部报"ink splash 不可见"
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: budgetAsync.when(
          data: (b) {
            final enabled = b?.enabled ?? false;
            return SwitchListTile(
              secondary: Icon(
                Icons.pie_chart_outline,
                color: enabled ? AppColors.primary : AppColors.textHint,
              ),
              title: const Text('启用月度预算'),
              subtitle: const Text('关闭后保留金额数据'),
              value: enabled,
              onChanged: (v) async {
                final db = await ref.read(databaseProvider.future);
                await db.upsertMonthlyBudget(
                  month: month,
                  amount: b?.amount ?? 0,
                  enabled: v,
                );
              },
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
        return _buildSettingsItem(
          icon: Icons.account_balance_wallet_outlined,
          title: '预算金额',
          subtitle: amt == 0 ? '未设置' : '¥${amt.toStringAsFixed(2)}',
          onTap: () async {
            final controller = TextEditingController(
              text: amt == 0 ? '' : amt.toStringAsFixed(2),
            );
            final newAmount = await showDialog<double>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('设置月度预算'),
                content: TextField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    hintText: '请输入金额',
                    prefixText: '¥ ',
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('取消'),
                  ),
                  TextButton(
                    onPressed: () {
                      final v = double.tryParse(controller.text.trim());
                      Navigator.pop(ctx, v);
                    },
                    child: const Text('确定'),
                  ),
                ],
              ),
            );
            if (newAmount != null && newAmount >= 0) {
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
