import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import '../config.dart'; // ✅ 匯入共用設定檔

class ChartPage extends StatefulWidget {
  const ChartPage({super.key});

  @override
  State<ChartPage> createState() => _ChartPageState();
}

class _ChartPageState extends State<ChartPage> {
  final String apiKey = airtableApiKey;
  final String baseId = airtableBaseId;
  final String recordTable = 'record';
  final String budgetTable = 'budget';

  double dailyBudget = 0;
  double monthlyBudget = 0;
  double dailyTotal = 0;
  double monthlyTotal = 0;
  bool isLoading = true;
  String? email;

  @override
  void initState() {
    super.initState();
    fetchAllData();
  }

  Future<void> fetchAllData() async {
    setState(() => isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    final storedEmail = prefs.getString('email');
    if (storedEmail == null || storedEmail.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('未登入，請先登入帳號')),
        );
        Navigator.pushReplacementNamed(context, '/login');
      }
      return;
    }

    email = storedEmail;

    await fetchBudgetData();
    await fetchSpendingData();

    setState(() => isLoading = false);
  }

  Future<void> fetchBudgetData() async {
    if (email == null) return;

    final filter = Uri.encodeComponent('email="$email"');
    final url = Uri.parse(
      'https://api.airtable.com/v0/$baseId/$budgetTable?filterByFormula=$filter',
    );
    final headers = {
      'Authorization': 'Bearer $apiKey',
      'Content-Type': 'application/json',
    };

    final response = await http.get(url, headers: headers);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['records'] != null && data['records'].isNotEmpty) {
        final record = data['records'][0];
        dailyBudget = (record['fields']['daily_budget'] ?? 0).toDouble();
        monthlyBudget = (record['fields']['monthly_budget'] ?? 0).toDouble();
      }
    } else {
      debugPrint('預算取得錯誤: ${response.body}');
    }
  }

  Future<void> fetchSpendingData() async {
    if (email == null) return;

    final filter = Uri.encodeComponent('AND(email="$email", type="支出")');
    final url = Uri.parse(
      'https://api.airtable.com/v0/$baseId/$recordTable?filterByFormula=$filter',
    );
    final headers = {
      'Authorization': 'Bearer $apiKey',
      'Content-Type': 'application/json',
    };

    final response = await http.get(url, headers: headers);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final today = DateTime.now();
      double todaySum = 0;
      double monthSum = 0;

      for (var record in data['records']) {
        final fields = record['fields'];
        final dateStr = fields['date'] ?? '';
        final amount = (fields['amount'] ?? 0).toDouble();

        if (dateStr.isEmpty) continue;

        try {
          final date = DateTime.parse(dateStr);
          if (date.year == today.year && date.month == today.month) {
            monthSum += amount;
            if (date.day == today.day) {
              todaySum += amount;
            }
          }
        } catch (e) {
          debugPrint('日期格式錯誤：$dateStr');
        }
      }

      dailyTotal = todaySum;
      monthlyTotal = monthSum;
    } else {
      debugPrint('支出資料取得錯誤: ${response.body}');
    }
  }

  Widget buildPieChart(double total, double budget, String title) {
    final percent = budget == 0 ? 0 : (total / budget).clamp(0.0, 1.0);
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              sections: [
                PieChartSectionData(
                  value: total,
                  color: Colors.red,
                  title: '支出 ${(percent * 100).toStringAsFixed(1)}%',
                  radius: 60,
                ),
                PieChartSectionData(
                  value: (budget - total).clamp(0, double.infinity),
                  color: Colors.green,
                  title:
                      '剩餘 ${(100 - percent * 100).clamp(0, 100).toStringAsFixed(1)}%',
                  radius: 60,
                ),
              ],
              sectionsSpace: 2,
              centerSpaceRadius: 40,
            ),
          ),
        ),
        Text('預算：$budget 元，支出：$total 元'),
        const SizedBox(height: 20),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('圖表分析')),
      body: RefreshIndicator(
        onRefresh: fetchAllData,
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    buildPieChart(dailyTotal, dailyBudget, '每日預算分析'),
                    buildPieChart(monthlyTotal, monthlyBudget, '每月預算分析'),
                  ],
                ),
              ),
      ),
    );
  }
}
