import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../config.dart'; // ✅ 引入 config.dart

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool isLoading = false;

  final String apiKey = airtableApiKey; // ✅ 從 config.dart 取得
  final String baseId = airtableBaseId;
  final String tableName = 'account';

  Future<void> registerUser() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    setState(() => isLoading = true);

    try {
      final headers = {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      };

      // ✅ 正確處理 Airtable 的 filterByFormula 查詢語法
      final formula = 'email="$email"';
      final checkUrl = Uri.parse(
        'https://api.airtable.com/v0/$baseId/$tableName?filterByFormula=${Uri.encodeComponent(formula)}',
      );
      final checkResponse = await http.get(checkUrl, headers: headers);
      final existing = json.decode(checkResponse.body)['records'];

      if (existing != null && existing.isNotEmpty) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email 已被註冊')),
        );
        return;
      }

      // ✅ 建立帳號
      final url = Uri.parse('https://api.airtable.com/v0/$baseId/$tableName');
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode({
          'fields': {
            'email': email,
            'password': password,
          }
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('email', email);

        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        if (!mounted) return;
        debugPrint('註冊錯誤回傳：${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('註冊失敗，請稍後再試')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('發生錯誤：$e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('註冊')),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              TextFormField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) =>
                    value == null || value.isEmpty ? '請輸入 Email' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: passwordController,
                decoration: const InputDecoration(labelText: '密碼'),
                obscureText: true,
                validator: (value) =>
                    value == null || value.isEmpty ? '請輸入密碼' : null,
              ),
              const SizedBox(height: 24),
              isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          registerUser();
                        }
                      },
                      child: const Text('註冊'),
                    ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pushReplacementNamed(context, '/'),
                child: const Text('已經有帳號？登入'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
