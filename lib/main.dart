import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'pages/login_page.dart';
import 'pages/register_page.dart';
import 'pages/home_page.dart';
import 'pages/add_record_page.dart';
import 'pages/budget_page.dart';
import 'pages/chart_page.dart';
import 'pages/settings_page.dart';
import 'pages/transaction_list_page.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  Future<String> getInitialRoute() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('email');
    return (email != null && email.isNotEmpty) ? '/home' : '/';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: getInitialRoute(),
      builder: (context, snapshot) {
        final initial = snapshot.data ?? '/';
        return BudgetTrackerApp(initialRoute: initial);
      },
    );
  }
}

class BudgetTrackerApp extends StatelessWidget {
  final String initialRoute;
  const BudgetTrackerApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Budget Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        scaffoldBackgroundColor: const Color(0xFFFEF6FF),
      ),
      initialRoute: initialRoute,
      routes: {
        '/': (context) => const LoginPage(),
        '/signup': (context) => const SignUpPage(),
        '/home': (context) => const HomePage(),
        '/addRecord': (context) => const AddRecordPage(),
        '/budget': (context) => const BudgetPage(),
        '/chart': (context) => const ChartPage(),
        '/settings': (context) => const SettingsPage(),
        '/transactions': (context) => const TransactionListPage(),
      },
    );
  }
}
