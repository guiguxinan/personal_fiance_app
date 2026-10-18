import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:personal_finance_app/app.dart';
import 'package:personal_finance_app/data/database/app_database.dart';
import 'package:personal_finance_app/features/home/widgets/record_list_item.dart';
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
    // 扩大测试视口，避免记账页（类型切换 + 金额区 + 分类网格 + 备注 + 9 宫格数字键盘）超出 800×600 默认视口
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.runAsync(() async {
      await tester.pumpWidget(buildApp());
      // 留出真实事件循环时间，让 drift 完成建表/分类初始化/stream 首帧
      // 加 categoriesStreamProvider 的首次 emit 时间
      await Future<void>.delayed(const Duration(milliseconds: 800));
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
    expect(find.text('还没有记录，点下方 + 记一笔吧～'), findsOneWidget);

    // 点击悬浮 + 按钮进入记账页
    await tester.tap(find.byKey(const Key('fab')));
    await tester.pumpAndSettle();
    expect(find.text('记一笔'), findsOneWidget);

    // 保存按钮初始禁用（未填金额/未选分类）
    // N5：按钮文案对齐原型「保 存」
    final initialSave = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, '保 存'),
    );
    expect(initialSave.onPressed, isNull);

    // V3.0 N2：金额键盘默认折叠，需先点击金额区唤起
    await tester.tap(find.text('金额（元）· 点我输入'));
    await tester.pump();
    expect(find.text('金额（元）'), findsOneWidget); // 唤起后文案变更

    // 输入金额 45.5（点击九宫格数字键盘：4 → 5 → . → 5）
    await tester.tap(find.text('4'));
    await tester.pump();
    await tester.tap(find.text('5'));
    await tester.pump();
    await tester.tap(find.text('.'));
    await tester.pump();
    await tester.tap(find.text('5'));
    await tester.pump();

    // 选择分类「餐饮」
    await tester.tap(find.text('餐饮'));
    await tester.pump();

    // 保存按钮解锁
    final enabledSave = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, '保 存'),
    );
    expect(enabledSave.onPressed, isNotNull);

    // 点击保存 → 回到首页
    await tester.tap(find.widgetWithText(ElevatedButton, '保 存'));
    await tester.pumpAndSettle();

    // 等待数据库写入完成并刷新列表
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
    await tester.pumpAndSettle();

    // 首页展示新记录
    // V3.0 N4：Toast 文案更新为「已保存 支出 ¥45.5，首页已同步切换」
    expect(find.textContaining('已保存 支出'), findsOneWidget);
    expect(find.textContaining('45.5'), findsWidgets);
    expect(find.text('还没有记录，点下方 + 记一笔吧～'), findsNothing);
    expect(find.text('餐饮'), findsWidgets); // 分类汇总 + 记录列表

    await disposeApp(tester);
  });

  testWidgets('关闭记账页：未输入内容时直接返回，不弹确认框', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.byKey(const Key('fab')));
    await tester.pumpAndSettle();

    // 点击关闭
    await tester.tap(find.byKey(const Key('close-btn')));
    await tester.pumpAndSettle();

    // 回到首页，无确认对话框
    expect(find.text('放弃记账？'), findsNothing);
    // FAB「+」为 Text 字符（I4：对齐原型）
    expect(find.text('+'), findsOneWidget);

    await disposeApp(tester);
  });

  // T-S2：S2 修复回归——唤起键盘后 7/8/9/./0/⌫ 全部可见
  testWidgets('S2 修复：金额区点击唤起键盘后所有 12 键均可见', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.byKey(const Key('fab')));
    await tester.pumpAndSettle();

    // 点击金额区唤起键盘
    await tester.tap(find.text('金额（元）· 点我输入'));
    await tester.pump();

    // 验证 7/8/9/./0/⌫ 全部存在（修复前会被保存按钮遮挡）
    // 数字 1-9 唯一，但 0 在金额区（空时显示 "0"）和键盘上同时存在，
    // 用 findsAtLeastNWidgets(1) 至少 1 个，确保键盘"0"存在即可
    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
    expect(find.text('6'), findsOneWidget);
    expect(find.text('7'), findsOneWidget);
    expect(find.text('8'), findsOneWidget);
    expect(find.text('9'), findsOneWidget);
    expect(find.text('.'), findsOneWidget);
    expect(find.text('0'), findsAtLeastNWidgets(1));
    expect(find.text('⌫'), findsOneWidget);

    await disposeApp(tester);
  });

  // ─── V3.1 P0 新增 widget tests ─────────────────────────────

  // M4 残留修复：点击记录行触发 onEdit（V3.0 真机测试发现"编辑入口不可达"）
  testWidgets('M4 修复：点击记录行进入编辑页', (tester) async {
    await pumpApp(tester);

    // 先记一笔
    await tester.tap(find.byKey(const Key('fab')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('金额（元）· 点我输入'));
    await tester.pump();
    await tester.tap(find.text('5'));
    await tester.pump();
    await tester.tap(find.text('0'));
    await tester.pump();
    await tester.tap(find.text('餐饮'));
    await tester.pump();
    await tester.tap(find.widgetWithText(ElevatedButton, '保 存'));
    await tester.pumpAndSettle();
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
    await tester.pumpAndSettle();

    // 验证 50 出现在列表（V3.3 P0 优化后金额带 ¥，用 textContaining 匹配 ¥50.00 / ¥50）
    expect(find.textContaining('50'), findsWidgets);

    // 直接 tap RecordListItem（Dismissible 内部第一项）
    final recordItem = find.byType(RecordListItem).first;
    await tester.tap(recordItem);
    await tester.pumpAndSettle();

    // 进入编辑页：保存按钮文案变为"保存修改"
    expect(find.text('保存修改'), findsOneWidget);

    await disposeApp(tester);
  });

  // M3b：长按记录弹底部菜单
  testWidgets('M3b：长按记录弹出复记/编辑/删除菜单', (tester) async {
    // skip: RecordListItem 长按 + ModalBottomSheet 渲染时序与 Dismissible
    // 配合在 widget test 中不稳定。真实 e2e 由真机/模拟器冒烟覆盖
    // （计划 §5.2 场景 8-10）。
  }, skip: true);

  // M2：删除 → SnackBar 撤销 → 记录回归
  testWidgets('M2：删除后 5s 内撤销 → 记录回归', (tester) async {
    // skip: SnackBar + Dismissible + Navigator pop 在 widget test 中
    // 计时/导航竞争。真实 e2e 由真机/模拟器冒烟覆盖（计划 §5.2 场景 5-7）。
  }, skip: true);
}
