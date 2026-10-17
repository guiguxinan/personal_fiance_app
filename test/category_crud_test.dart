import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_finance_app/data/database/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  test('插入自定义分类', () async {
    final id = await db.insertCategory('零食', '🍫');
    expect(id, greaterThan(0));

    final categories = await db.getAllCategories();
    expect(categories.length, 9); // 8 defaults + 1 custom
  });

  test('更新自定义分类', () async {
    final id = await db.insertCategory('零食', '🍫');

    final success = await db.updateCategory(id, '甜品', '🍰');
    expect(success, true);

    final category = await db.getCategoryById(id);
    expect(category?.name, '甜品');
    expect(category?.icon, '🍰');
    expect(category?.isDefault, false);
  });

  test('删除自定义分类', () async {
    final id = await db.insertCategory('零食', '🍫');

    final deleted = await db.deleteCategory(id);
    expect(deleted, 1);

    final categories = await db.getAllCategories();
    expect(categories.length, 8); // back to 8 defaults
  });

  test('watchAllCategories 流式监听', () async {
    // Stream should emit initial value
    final stream = db.watchAllCategories().first;
    final results = await stream;
    expect(results.length, 8); // initial 8 defaults
  });
}
