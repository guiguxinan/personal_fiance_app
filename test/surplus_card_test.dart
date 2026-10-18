import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_finance_app/core/utils/currency_formatter.dart';
import 'package:personal_finance_app/features/home/widgets/surplus_card.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('M4a 正结余显示绿色结余文案', (tester) async {
    await tester.pumpWidget(
      wrap(
        SurplusCard(
          income: 5000,
          expense: 3000,
          onTap: () {},
        ),
      ),
    );
    expect(find.text('本月结余'), findsOneWidget);
    expect(find.text('结余'), findsOneWidget);
    expect(find.text(CurrencyFormatter.format(2000)), findsOneWidget);
  });

  testWidgets('M4a 负结余显示红色透支文案', (tester) async {
    await tester.pumpWidget(
      wrap(
        SurplusCard(
          income: 1000,
          expense: 2000,
          onTap: () {},
        ),
      ),
    );
    expect(find.text('透支'), findsOneWidget);
    // 负数时 SurplusCard 在金额前加 "-" 前缀（"-(CurrencyFormatter.format(1000))"）
    expect(find.text('-${CurrencyFormatter.format(1000)}'), findsOneWidget);
  });

  testWidgets('M4a 收入/支出小行展示', (tester) async {
    await tester.pumpWidget(
      wrap(
        SurplusCard(income: 4000, expense: 1000, onTap: () {}),
      ),
    );
    expect(find.textContaining('收入'), findsOneWidget);
    expect(find.textContaining('支出'), findsOneWidget);
  });

  testWidgets('M4a 点击卡片触发 onTap', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      wrap(
        SurplusCard(
          income: 5000,
          expense: 3000,
          onTap: () => tapped = true,
        ),
      ),
    );
    await tester.tap(find.byType(SurplusCard));
    await tester.pump();
    expect(tapped, isTrue);
  });
}
