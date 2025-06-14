import 'package:flutter/material.dart';
import 'home_page.dart';
import 'chart_page.dart';
import 'budget_page.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const HomePage(),
    const ChartPage(),
    const BudgetPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: '記帳',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.pie_chart),
            label: '分析',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: '預算',
          ),
        ],
      ),
    );
  }
}
