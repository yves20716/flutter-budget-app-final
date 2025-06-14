import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config.dart'; // ✅ 使用共用設定

class BudgetPage extends StatefulWidget {
  const BudgetPage({super.key});

  @override
  State<BudgetPage> createState() => _BudgetPageState();
}

class _BudgetPageState extends State<BudgetPage> {
  final TextEditingController dailyController = TextEditingController();
  final TextEditingController monthlyController = TextEditingController();
  bool isLoading = false;
  String? email;
  String? recordId; // Airtable 中對應的紀錄 ID

  final String apiKey = airtableApiKey; // ✅ 來自 config.dart
  final String baseId = airtableBaseId;
  final String tableName = 'budget';

  @override
  void initState() {
    super.initState();
    loadUserEmailAndBudget();
  }

  Future<void> loadUserEmailAndBudget() async {
    final prefs = await SharedPreferences.getInstance();
    final storedEmail = prefs.getString('email');

    if (storedEmail == null || storedEmail.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('未登入，請先登入帳號')),
      );
      return;
    }

    setState(() => email = storedEmail);

    final url = Uri.parse('https://api.airtable.com/v0/$baseId/$tableName?filterByFormula={email}="$storedEmail"');
    final headers = {
      'Authorization': 'Bearer $apiKey',
      'Content-Type': 'application/json',
    };

    final response = await http.get(url, headers: headers);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['records'] != null && data['records'].isNotEmpty) {
        final record = data['records'][0];
        setState(() {
          recordId = record['id'];
          dailyController.text = record['fields']['daily_budget'].toString();
          monthlyController.text = record['fields']['monthly_budget'].toString();
        });
      }
    }
  }

  Future<void> submitBudget() async {
    final dailyBudget = double.tryParse(dailyController.text.trim());
    final monthlyBudget = double.tryParse(monthlyController.text.trim());

    if (dailyBudget == null || monthlyBudget == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('請輸入有效的預算數字')),
      );
      return;
    }

    if (email == null || email!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('無法取得使用者 email')),
      );
      return;
    }

    setState(() => isLoading = true);

    final headers = {
      'Authorization': 'Bearer $apiKey',
      'Content-Type': 'application/json',
    };

    final body = jsonEncode({
      "fields": {
        "email": email,
        "daily_budget": dailyBudget,
        "monthly_budget": monthlyBudget,
      }
    });

    final url = recordId != null
        ? Uri.parse('https://api.airtable.com/v0/$baseId/$tableName/$recordId')
        : Uri.parse('https://api.airtable.com/v0/$baseId/$tableName');

    final response = recordId != null
        ? await http.patch(url, headers: headers, body: body)
        : await http.post(url, headers: headers, body: body);

    setState(() => isLoading = false);

    if (response.statusCode == 200 || response.statusCode == 201) {
      if (recordId == null && jsonDecode(response.body)['id'] != null) {
        setState(() => recordId = jsonDecode(response.body)['id']);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('預算設定成功')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('設定失敗：${response.body}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('預算設定')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: dailyController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: '每日預算金額'),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: monthlyController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: '每月預算金額'),
            ),
            const SizedBox(height: 30),
            isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: submitBudget,
                    child: const Text('提交'),
                  ),
          ],
        ),
      ),
    );
  }
}
