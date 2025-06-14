import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../config.dart'; // 使用共用設定檔

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;

  final String apiKey = airtableApiKey;
  final String baseId = airtableBaseId;
  final String tableName = 'account';

  Future<void> loginUser() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('請輸入 Email 和密碼')),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      // ✅ 正確處理 filterByFormula
      final formula = 'AND(email="$email", password="$password")';
      final url = Uri.parse(
        'https://api.airtable.com/v0/$baseId/$tableName?filterByFormula=${Uri.encodeComponent(formula)}',
      );

      final headers = {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      };

      final response = await http.get(url, headers: headers);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['records'].isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('email', email);

        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        debugPrint('登入失敗回傳：${response.body}');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('登入失敗，帳號或密碼錯誤')),
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
      appBar: AppBar(title: const Text('登入')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(labelText: '密碼'),
              obscureText: true,
            ),
            const SizedBox(height: 24),
            isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: loginUser,
                    child: const Text('登入'),
                  ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, '/signup'),
              child: const Text('還沒有帳號？註冊'),
            ),
          ],
        ),
      ),
    );
  }
}
