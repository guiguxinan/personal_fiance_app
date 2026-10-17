import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/utils/data_exporter.dart';
import '../../core/utils/data_importer.dart';
import '../../providers/database_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          _buildSectionHeader('数据管理'),
          _buildSettingsItem(
            icon: Icons.upload,
            title: '备份数据',
            subtitle: '导出所有记账记录到本地',
            onTap: () => _exportData(context, ref),
          ),
          _buildSettingsItem(
            icon: Icons.download,
            title: '恢复数据',
            subtitle: '从备份文件导入数据',
            onTap: () => _showImportDialog(context, ref),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('关于'),
          _buildSettingsItem(
            icon: Icons.info,
            title: '版本信息',
            subtitle: '个人财务管理 App v1.0.0',
            onTap: null,
          ),
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
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
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
    );
  }

  Future<void> _exportData(BuildContext context, WidgetRef ref) async {
    try {
      final database = await ref.read(databaseProvider.future);
      final exporter = DataExporter(database);
      final file = await exporter.exportToJson();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('备份已保存到: ${file.path}'),
            backgroundColor: AppColors.primary,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('备份失败: $e'),
            backgroundColor: AppColors.expense,
          ),
        );
      }
    }
  }

  void _showImportDialog(BuildContext context, WidgetRef ref) {
    final importPathController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('恢复数据'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('请输入备份文件路径:'),
            const SizedBox(height: 12),
            TextField(
              controller: importPathController,
              decoration: const InputDecoration(
                hintText: '/storage/emulated/0/.../personal_finance_backup_xxx.json',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              final path = importPathController.text.trim();
              if (path.isEmpty) return;

              try {
                final database = await ref.read(databaseProvider.future);
                final importer = DataImporter(database);
                final result = await importer.importFromJson(File(path));

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(result.message),
                      backgroundColor:
                          result.success ? AppColors.primary : AppColors.expense,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('恢复失败: $e'),
                      backgroundColor: AppColors.expense,
                    ),
                  );
                }
              }
            },
            child: const Text('导入'),
          ),
        ],
      ),
    );
  }
}
