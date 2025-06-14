import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/airtable_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? email;
  double totalExpense = 0;

  @override
  void initState() {
    super.initState();
    _loadEmailAndExpense();
  }

  Future<void> _loadEmailAndExpense() async {
    final prefs = await SharedPreferences.getInstance();
    final storedEmail = prefs.getString('email');

    if (storedEmail == null || storedEmail.isEmpty) {
      if (mounted) {
        // ➤ 強制導回登入頁（清空 navigation stack）
        Future.microtask(() {
          Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
        });
      }
      return;
    }

    final total = await AirtableService().calculateTotalExpense();
    if (mounted) {
      setState(() {
        email = storedEmail;
        totalExpense = total;
      });
    }
  }

  void _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('email');

    if (mounted) {
      // ➤ 登出後清空堆疊回首頁
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('記帳主畫面'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: '登出',
          )
        ],
      ),
      body: email == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text('登入帳號：$email', style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 8),
                Text(
                  '目前支出總額：\$${totalExpense.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/addRecord')
                        .then((_) => _loadEmailAndExpense());
                  },
                  child: const Text('新增記帳'),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/transactions')
                        .then((_) => _loadEmailAndExpense());
                  },
                  child: const Text('記帳紀錄'),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/budget');
                  },
                  child: const Text('預算設定'),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/chart')
                        .then((_) => _loadEmailAndExpense());
                  },
                  child: const Text('圖表分析'),
                ),
              ],
            ),
    );
  }
}
