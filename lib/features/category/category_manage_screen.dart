import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../data/database/app_database.dart';
import '../../providers/category_provider.dart';
import '../../providers/database_provider.dart';

const List<String> availableIcons = [
  '🍜', '🚗', '🛒', '🎮', '🏠', '💊', '📚', '📌',
  '☕', '🍕', '🎬', '✈️', '💰', '🎁', '👔', '📱',
  '🏋️', '🎵', '📖', '🐱', '🌸', '⚽',
];

class CategoryManageScreen extends ConsumerWidget {
  const CategoryManageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('分类管理', style: AppTypography.titleLarge),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddCategoryDialog(context, ref),
          ),
        ],
      ),
      body: categoriesAsync.when(
        data: (categories) => _buildCategoryList(context, ref, categories),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('😕', style: TextStyle(fontSize: 40)),
                const SizedBox(height: 12),
                Text('分类加载失败', style: AppTypography.titleMedium),
                const SizedBox(height: 6),
                Text(
                  '请稍后重试',
                  style: AppTypography.bodyMedium
                      .copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => ref.invalidate(categoriesStreamProvider),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('重试'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryList(BuildContext context, WidgetRef ref, List<Category> categories) {
    if (categories.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            '暂无分类，点右上角 + 新增',
            style: TextStyle(color: AppColors.textHint),
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return _buildCategoryItem(context, ref, category);
      },
    );
  }

  Widget _buildCategoryItem(BuildContext context, WidgetRef ref, Category category) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          leading: Text(category.icon, style: const TextStyle(fontSize: 28)),
          title: Text(category.name, style: AppTypography.bodyLarge),
          subtitle: Text(
            category.isDefault ? '默认分类' : '自定义',
            style: AppTypography.labelSmall.copyWith(
              color: category.isDefault ? AppColors.textHint : AppColors.primary,
            ),
          ),
          // V3.3 优化 (O3)：自定义分类行加 隐藏 Switch（对齐 PRD §10.6.4）
          // 排序列：上移 / 下移 / 隐藏 Switch / 更多菜单
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildSortButton(context, ref, category, up: true),
              _buildSortButton(context, ref, category, up: false),
              if (!category.isDefault)
                _buildHiddenSwitch(context, ref, category),
              if (!category.isDefault)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) {
                    if (value == 'edit') {
                      _showEditCategoryDialog(context, ref, category);
                    } else if (value == 'delete') {
                      _confirmDelete(context, ref, category);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'edit', child: Text('编辑')),
                    const PopupMenuItem(value: 'delete', child: Text('删除')),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSortButton(
    BuildContext context,
    WidgetRef ref,
    Category category, {
    required bool up,
  }) {
    return IconButton(
      icon: Icon(
        up ? Icons.arrow_upward : Icons.arrow_downward,
        size: 18,
        color: AppColors.textHint,
      ),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      visualDensity: VisualDensity.compact,
      tooltip: up ? '上移' : '下移',
      onPressed: () async {
        final database = await ref.read(databaseProvider.future);
        if (up) {
          await database.moveCategoryUp(category.id);
        } else {
          await database.moveCategoryDown(category.id);
        }
        // stream emit → 列表自动重建
      },
    );
  }

  /// V3.3 优化 (O3)：自定义分类行右侧加「隐藏」Switch（PRD §10.6.4）
  /// 默认分类不可隐藏
  Widget _buildHiddenSwitch(
    BuildContext context,
    WidgetRef ref,
    Category category,
  ) {
    return Tooltip(
      message: category.isHidden ? '已隐藏（仍可被「最近使用」选中）' : '隐藏后不出现在常规分类区与统计图例',
      child: SizedBox(
        width: 44,
        height: 28,
        child: Switch(
          value: category.isHidden,
          onChanged: (v) async {
            final database = await ref.read(databaseProvider.future);
            await database.setCategoryHidden(category.id, v);
            // stream emit → 列表自动 rebuild（隐藏状态更新）
          },
        ),
      ),
    );
  }

  void _showAddCategoryDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    String selectedIcon = availableIcons[0];
    String selectedType = 'expense';

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('新增分类'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('分类类型',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => selectedType = 'income'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: selectedType == 'income'
                                ? AppColors.income.withValues(alpha: 0.1)
                                : AppColors.background,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: selectedType == 'income'
                                  ? AppColors.income
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '收入',
                              style: TextStyle(
                                color: selectedType == 'income'
                                    ? AppColors.income
                                    : AppColors.textSecondary,
                                fontWeight: selectedType == 'income'
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => selectedType = 'expense'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: selectedType == 'expense'
                                ? AppColors.primary.withValues(alpha: 0.1)
                                : AppColors.background,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: selectedType == 'expense'
                                  ? AppColors.primary
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '支出',
                              style: TextStyle(
                                color: selectedType == 'expense'
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
                                fontWeight: selectedType == 'expense'
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  maxLength: 10,
                  decoration: const InputDecoration(
                    labelText: '分类名称',
                    hintText: '例如：零食',
                  ),
                ),
                const SizedBox(height: 16),
                const Text('选择图标', style: TextStyle(fontSize: 12)),
                const SizedBox(height: 8),
                SizedBox(
                  height: 150,
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 6,
                      mainAxisSpacing: 4,
                      crossAxisSpacing: 4,
                    ),
                    itemCount: availableIcons.length,
                    itemBuilder: (context, index) {
                      final icon = availableIcons[index];
                      final isSelected = icon == selectedIcon;
                      return GestureDetector(
                        onTap: () => setState(() => selectedIcon = icon),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary.withValues(alpha: 0.2)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Center(
                              child: Text(icon, style: const TextStyle(fontSize: 24))),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty) return;
                final database = await ref.read(databaseProvider.future);
                await database.insertCategory(
                  nameController.text.trim(),
                  selectedIcon,
                  type: selectedType,
                );
                if (dialogCtx.mounted) {
                  Navigator.pop(dialogCtx);
                }
              },
              child: const Text('添加'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditCategoryDialog(BuildContext context, WidgetRef ref, Category category) {
    final nameController = TextEditingController(text: category.name);
    String selectedIcon = category.icon;
    String selectedType = category.type; // V3.3 优化：编辑也支持切换 type

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('编辑分类'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // V3.3 优化：编辑对话框排版对齐「新增分类」——补齐 type 切换
                const Text('分类类型',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => selectedType = 'income'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: selectedType == 'income'
                                ? AppColors.income.withValues(alpha: 0.1)
                                : AppColors.background,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: selectedType == 'income'
                                  ? AppColors.income
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '收入',
                              style: TextStyle(
                                color: selectedType == 'income'
                                    ? AppColors.income
                                    : AppColors.textSecondary,
                                fontWeight: selectedType == 'income'
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => selectedType = 'expense'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: selectedType == 'expense'
                                ? AppColors.primary.withValues(alpha: 0.1)
                                : AppColors.background,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: selectedType == 'expense'
                                  ? AppColors.primary
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '支出',
                              style: TextStyle(
                                color: selectedType == 'expense'
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
                                fontWeight: selectedType == 'expense'
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  maxLength: 10,
                  decoration: const InputDecoration(
                    labelText: '分类名称',
                    hintText: '例如：零食',
                  ),
                ),
                const SizedBox(height: 16),
                const Text('选择图标', style: TextStyle(fontSize: 12)),
                const SizedBox(height: 8),
                SizedBox(
                  height: 150,
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 6,
                      mainAxisSpacing: 4,
                      crossAxisSpacing: 4,
                    ),
                    itemCount: availableIcons.length,
                    itemBuilder: (context, index) {
                      final icon = availableIcons[index];
                      final isSelected = icon == selectedIcon;
                      return GestureDetector(
                        onTap: () => setState(() => selectedIcon = icon),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary.withValues(alpha: 0.2)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Center(
                              child: Text(icon, style: const TextStyle(fontSize: 24))),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty) return;
                final database = await ref.read(databaseProvider.future);
                await database.updateCategory(
                  category.id,
                  nameController.text.trim(),
                  selectedIcon,
                  type: selectedType, // V3.3 优化：透传 type 修改
                );
                if (dialogCtx.mounted) {
                  Navigator.pop(dialogCtx);
                }
              },
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
  }

  /// V3.3 优化 (O4)：删除含记录的自定义分类时，弹二次确认「记录归入『其他』」
  /// PRD §10.6.6：默认分类不可删除；自定义分类删除 → 关联记录归入「其他」并二次确认
  void _confirmDelete(BuildContext context, WidgetRef ref, Category category) async {
    final database = await ref.read(databaseProvider.future);
    // 检查该分类下是否有记录
    final allRecords = await database.getAllRecords();
    final hasRecords = allRecords.any((r) => r.categoryId == category.id);

    if (!hasRecords) {
      _showDeleteDialog(context, ref, category, migrateToOther: false);
    } else {
      // 含记录 → 弹二次确认，提示"将归入『其他』"
      _showDeleteDialog(context, ref, category, migrateToOther: true);
    }
  }

  void _showDeleteDialog(
    BuildContext context,
    WidgetRef ref,
    Category category, {
    required bool migrateToOther,
  }) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('确定删除？'),
        content: Text(
          migrateToOther
              ? '删除分类「${category.name}」后，其下所有记账记录将归入「其他」，分类移除。'
              : '删除分类「${category.name}」？',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogCtx);
              try {
                final database = await ref.read(databaseProvider.future);
                if (migrateToOther) {
                  // 找到同类型的「其他」分类
                  final otherCategory = (await database.getAllCategories())
                      .firstWhere(
                        (c) => c.name == '其他' && c.type == category.type,
                        orElse: () => category, // 兜底：找不到就用原分类（应该不会发生）
                      );
                  // 把该分类下的所有记录迁移到「其他」
                  final recordsToMigrate = (await database.getAllRecords())
                      .where((r) => r.categoryId == category.id)
                      .toList();
                  for (final r in recordsToMigrate) {
                    await database.updateRecord(RecordsCompanion(
                      id: drift.Value(r.id),
                      amount: drift.Value(r.amount),
                      categoryId: drift.Value(otherCategory.id),
                      recordDate: drift.Value(r.recordDate),
                      note: drift.Value(r.note),
                      type: drift.Value(r.type),
                      createdAt: drift.Value(r.createdAt),
                      updatedAt: drift.Value(DateTime.now()),
                    ));
                  }
                }
                await database.deleteCategory(category.id);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('删除失败：$e'),
                      backgroundColor: AppColors.expense,
                    ),
                  );
                }
              }
            },
            child: Text('删除', style: TextStyle(color: AppColors.expense)),
          ),
        ],
      ),
    );
  }
}
