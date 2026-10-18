import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_finance_app/features/home/widgets/budget_card.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('M4b 50% 进度显示粉色 + 剩余日均', (tester) async {
    await tester.pumpWidget(
      wrap(
        const BudgetCard(budgetAmount: 1000, expenseAmount: 500),
      ),
    );
    expect(find.text('本月预算'), findsOneWidget);
    expect(find.text('50%'), findsOneWidget);
    expect(find.textContaining('剩余日均'), findsOneWidget);
  });

  testWidgets('M4b 85% 进度（70-100% 警示色）', (tester) async {
    await tester.pumpWidget(
      wrap(
        const BudgetCard(budgetAmount: 1000, expenseAmount: 850),
      ),
    );
    expect(find.text('85%'), findsOneWidget);
    expect(find.textContaining('剩余日均'), findsOneWidget);
  });

  testWidgets('M4b 120% 进度显示已超支 + 红字', (tester) async {
    await tester.pumpWidget(
      wrap(
        const BudgetCard(budgetAmount: 1000, expenseAmount: 1200),
      ),
    );
    expect(find.text('120%'), findsOneWidget);
    expect(find.textContaining('已超支'), findsOneWidget);
    expect(find.textContaining('剩余日均'), findsNothing);
  });

  testWidgets('M4b 0 进度（刚开始）', (tester) async {
    await tester.pumpWidget(
      wrap(
        const BudgetCard(budgetAmount: 5000, expenseAmount: 0),
      ),
    );
    expect(find.text('0%'), findsOneWidget);
    expect(find.textContaining('剩余日均'), findsOneWidget);
  });
}
