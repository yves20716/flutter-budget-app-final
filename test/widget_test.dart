import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budget_tracker/main.dart';

void main() {
  testWidgets('Login page renders correctly', (WidgetTester tester) async {
    // 直接提供初始路徑來避開 SharedPreferences 的 async 問題
    await tester.pumpWidget(const BudgetTrackerApp(initialRoute: '/'));

    // 檢查 Email 和密碼欄位
    expect(find.byType(TextFormField), findsNWidgets(2));

    // 檢查登入按鈕
    expect(find.widgetWithText(ElevatedButton, '登入'), findsOneWidget);
  });
}
