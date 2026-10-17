class CategoryModel {
  final int id;
  final String name;
  final String icon;
  final bool isDefault;

  const CategoryModel({
    required this.id,
    required this.name,
    required this.icon,
    this.isDefault = true,
  });

  CategoryModel copyWith({
    int? id,
    String? name,
    String? icon,
    bool? isDefault,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CategoryModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

// Default categories
const List<CategoryModel> defaultCategories = [
  CategoryModel(id: 1, name: '餐饮', icon: '🍜'),
  CategoryModel(id: 2, name: '交通', icon: '🚗'),
  CategoryModel(id: 3, name: '购物', icon: '🛒'),
  CategoryModel(id: 4, name: '娱乐', icon: '🎮'),
  CategoryModel(id: 5, name: '居住', icon: '🏠'),
  CategoryModel(id: 6, name: '医疗', icon: '💊'),
  CategoryModel(id: 7, name: '教育', icon: '📚'),
  CategoryModel(id: 8, name: '其他', icon: '📌'),
];

CategoryModel? getCategoryById(int id) {
  try {
    return defaultCategories.firstWhere((c) => c.id == id);
  } catch (_) {
    return null;
  }
}
