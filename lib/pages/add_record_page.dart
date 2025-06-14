import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config.dart'; // 共用 API 金鑰與 Base ID

class AddRecordPage extends StatefulWidget {
  const AddRecordPage({super.key});

  @override
  State<AddRecordPage> createState() => _AddRecordPageState();
}

class _AddRecordPageState extends State<AddRecordPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController noteController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController dateController = TextEditingController();

  String type = '支出';
  String category = '飲食';
  String method = '現金';
  DateTime selectedDate = DateTime.now();
  bool isLoading = false;
  String? email;

  final String apiKey = airtableApiKey;
  final String baseId = airtableBaseId;
  final String tableName = 'record';

  @override
  void initState() {
    super.initState();
    _loadEmail();
    dateController.text = selectedDate.toIso8601String().split('T').first;
  }

  Future<void> _loadEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final storedEmail = prefs.getString('email');
    if (storedEmail == null || storedEmail.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('請先登入帳號')),
        );
        Navigator.pushReplacementNamed(context, '/login');
      }
      return;
    }
    setState(() => email = storedEmail);
  }

  Future<void> _submitRecord() async {
    final name = nameController.text.trim();
    final note = noteController.text.trim();
    final amount = double.tryParse(amountController.text.trim()) ?? 0;
    final date = dateController.text.trim();

    if (email == null || email!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('未登入，請先登入帳號')),
      );
      return;
    }

    if (name.isEmpty || amount <= 0 || date.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('請填寫正確的名稱、金額與日期')),
      );
      return;
    }

    setState(() => isLoading = true);

    final url = Uri.parse('https://api.airtable.com/v0/$baseId/$tableName');
    final headers = {
      'Authorization': 'Bearer $apiKey',
      'Content-Type': 'application/json',
    };

    final body = jsonEncode({
      'fields': {
        'email': email,
        'type': type,
        'category': category,
        'method': method,
        'name': name,
        'note': note,
        'amount': amount,
        'date': date, // ✅ 正確送出日期欄位
      },
    });

    final response = await http.post(url, headers: headers, body: body);
    setState(() => isLoading = false);

    if (response.statusCode == 200 || response.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('新增成功')),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('新增失敗：${response.body}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('新增記帳')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            DropdownButtonFormField<String>(
              value: type,
              items: const [
                DropdownMenuItem(value: '支出', child: Text('支出')),
                DropdownMenuItem(value: '收入', child: Text('收入')),
              ],
              onChanged: (value) => setState(() => type = value!),
              decoration: const InputDecoration(labelText: '類型'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: category,
              items: const [
                DropdownMenuItem(value: '飲食', child: Text('飲食')),
                DropdownMenuItem(value: '交通', child: Text('交通')),
                DropdownMenuItem(value: '購物', child: Text('購物')),
                DropdownMenuItem(value: '娛樂', child: Text('娛樂')),
                DropdownMenuItem(value: '醫療', child: Text('醫療')),
                DropdownMenuItem(value: '寵物', child: Text('寵物')),
              ],
              onChanged: (value) => setState(() => category = value!),
              decoration: const InputDecoration(labelText: '分類'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: method,
              items: const [
                DropdownMenuItem(value: '現金', child: Text('現金')),
                DropdownMenuItem(value: '信用卡', child: Text('信用卡')),
                DropdownMenuItem(value: '行動支付', child: Text('行動支付')),
              ],
              onChanged: (value) => setState(() => method = value!),
              decoration: const InputDecoration(labelText: '付款方式'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: '名稱（消費事項）'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(labelText: '備註'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: '金額'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: dateController,
              readOnly: true,
              decoration: const InputDecoration(labelText: '日期'),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                );
                if (picked != null) {
                  setState(() {
                    selectedDate = picked;
                    dateController.text = picked.toIso8601String().split('T').first;
                  });
                }
              },
            ),
            const SizedBox(height: 20),
            isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _submitRecord,
                    child: const Text('送出'),
                  ),
          ],
        ),
      ),
    );
  }
}
