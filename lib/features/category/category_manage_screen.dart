import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../data/database/app_database.dart';
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
      body: _buildCategoryList(context, ref),
    );
  }

  Widget _buildCategoryList(BuildContext context, WidgetRef ref) {
    return FutureBuilder<List<Category>>(
      future: _getCategories(ref),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final categories = snapshot.data ?? [];
        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            return _buildCategoryItem(context, ref, category);
          },
        );
      },
    );
  }

  Future<List<Category>> _getCategories(WidgetRef ref) async {
    final database = await ref.read(databaseProvider.future);
    return database.getAllCategories();
  }

  Widget _buildCategoryItem(BuildContext context, WidgetRef ref, Category category) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      // Material 包装：避免 ListTile 在 DecoratedBox 内 ink splash 不可见 + pumpAndSettle 卡住
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
          trailing: category.isDefault
              ? null
              : PopupMenuButton<String>(
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
        ),
      ),
    );
  }

  void _showAddCategoryDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    String selectedIcon = availableIcons[0];
    String selectedType = 'expense'; // O3 修复：新增分类支持选择类型

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('新增分类'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // O3 修复：类型选择
                const Text('分类类型', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
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
                              color: selectedType == 'income' ? AppColors.income : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '收入',
                              style: TextStyle(
                                color: selectedType == 'income' ? AppColors.income : AppColors.textSecondary,
                                fontWeight: selectedType == 'income' ? FontWeight.w600 : FontWeight.normal,
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
                              color: selectedType == 'expense' ? AppColors.primary : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '支出',
                              style: TextStyle(
                                color: selectedType == 'expense' ? AppColors.primary : AppColors.textSecondary,
                                fontWeight: selectedType == 'expense' ? FontWeight.w600 : FontWeight.normal,
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
                              color: isSelected ? AppColors.primary : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Center(child: Text(icon, style: const TextStyle(fontSize: 24))),
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
              onPressed: () => Navigator.pop(context),
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
                if (context.mounted) {
                  Navigator.pop(context);
                  (context as Element).markNeedsBuild();
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

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('编辑分类'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                maxLength: 10,
                decoration: const InputDecoration(labelText: '分类名称'),
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
                            color: isSelected ? AppColors.primary : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Center(child: Text(icon, style: const TextStyle(fontSize: 24))),
                      ),
                    );
                  },
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
                if (nameController.text.trim().isEmpty) return;
                final database = await ref.read(databaseProvider.future);
                await database.updateCategory(category.id, nameController.text.trim(), selectedIcon);
                if (context.mounted) {
                  Navigator.pop(context);
                  (context as Element).markNeedsBuild();
                }
              },
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Category category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确定删除？'),
        content: Text('删除分类「${category.name}」后，相关记账记录将保留但无法选择该分类。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              try {
                final database = await ref.read(databaseProvider.future);
                await database.deleteCategory(category.id);
                if (context.mounted) {
                  Navigator.pop(context);
                  (context as Element).markNeedsBuild();
                }
              } catch (e) {
                // M2 修复：外键约束（分类有历史记录）异常 → 友好 Toast 提示
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('该分类已有 ${category.name} 的记账记录，请先迁移或删除记录'),
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
