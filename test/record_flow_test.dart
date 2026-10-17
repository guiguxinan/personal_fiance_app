import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:personal_finance_app/app.dart';
import 'package:personal_finance_app/data/database/app_database.dart';
import 'package:personal_finance_app/providers/database_provider.dart';

void main() {
  late AppDatabase db;

  setUpAll(() async {
    // 初始化 zh_CN locale（应用代码依赖 DateFormat zh_CN）
    await initializeDateFormatting('zh_CN');
  });

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  Widget buildApp() {
    return ProviderScope(
      overrides: [
        databaseProvider.overrideWith((ref) async => db),
      ],
      child: const PersonalFinanceApp(),
    );
  }

  /// 在真实异步环境中等候数据库 stream 完成首次 emit，
  /// 再切回 FakeAsync 做交互断言。
  Future<void> pumpApp(WidgetTester tester) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(buildApp());
      // 留出真实事件循环时间，让 drift 完成建表/分类初始化/stream 首帧
      await Future<void>.delayed(const Duration(milliseconds: 300));
    });
    await tester.pumpAndSettle();
  }

  /// 手动卸载 widget 树并 flush 一次：
  /// riverpod 销毁 StreamProvider 时 drift 会创建零时长关闭 Timer，
  /// 若留到框架自动卸载后检查，会报 "Timer is still pending"。
  Future<void> disposeApp(WidgetTester tester) async {
    // 先清空 widget 树，让 riverpod 触发 StreamProvider dispose
    await tester.pumpWidget(const SizedBox.shrink());
    // Drift 的 stream close timer 需要事件循环来清理
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));
  }

  testWidgets('核心流程：空首页 → 记一笔 → 首页展示新记录', (tester) async {
    await pumpApp(tester);

    // 初始为空状态
    expect(find.text('还没有记录'), findsOneWidget);

    // 点击悬浮 + 按钮进入记账页
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    expect(find.text('记账'), findsOneWidget);

    // 保存按钮初始禁用（未填金额/未选分类）
    final initialSave = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, '保存'),
    );
    expect(initialSave.onPressed, isNull);

    // 输入金额 45.5
    await tester.enterText(find.byType(TextField).first, '45.5');
    await tester.pump();

    // 选择分类「餐饮」
    await tester.tap(find.text('餐饮'));
    await tester.pump();

    // 保存按钮解锁
    final enabledSave = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, '保存'),
    );
    expect(enabledSave.onPressed, isNotNull);

    // 点击保存 → 回到首页
    await tester.tap(find.widgetWithText(ElevatedButton, '保存'));
    await tester.pumpAndSettle();

    // 等待数据库写入完成并刷新列表
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
    await tester.pumpAndSettle();

    // 首页展示新记录
    expect(find.text('记账成功'), findsOneWidget); // SnackBar 提示
    expect(find.text('还没有记录'), findsNothing);
    expect(find.text('餐饮'), findsWidgets); // 分类汇总 + 记录列表
    expect(find.textContaining('45.5'), findsWidgets);

    await disposeApp(tester);
  });

  testWidgets('关闭记账页：未输入内容时直接返回，不弹确认框', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    // 点击关闭
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    // 回到首页，无确认对话框
    expect(find.text('放弃记账？'), findsNothing);
    expect(find.byIcon(Icons.add), findsOneWidget);

    await disposeApp(tester);
  });
}
