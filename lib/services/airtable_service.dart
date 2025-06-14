import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart'; // ✅ 匯入共用設定檔

class AirtableService {
  final String apiKey = airtableApiKey;
  final String baseId = airtableBaseId;

  // ----------------------
  // 原有功能保留
  // ----------------------

  Future<List<Map<String, dynamic>>> fetchAccounts() async {
    final url = Uri.parse('https://api.airtable.com/v0/$baseId/account');
    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $apiKey'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['records'] as List).map((record) {
        return {
          'email': record['fields']['email'],
          'password': record['fields']['password'],
        };
      }).toList();
    } else {
      throw Exception('Failed to fetch accounts');
    }
  }

  Future<bool> registerAccount(String email, String password) async {
    final url = Uri.parse('https://api.airtable.com/v0/$baseId/account');

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'fields': {'email': email, 'password': password},
      }),
    );

    return response.statusCode == 200 || response.statusCode == 201;
  }

  Future<bool> createRecord(Map<String, dynamic> record) async {
    final email = await getCurrentUser(); // 綁定使用者
    if (email == null) return false;

    final url = Uri.parse('https://api.airtable.com/v0/$baseId/record');
    final enrichedRecord = Map<String, dynamic>.from(record);
    enrichedRecord['email'] = email;

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'fields': enrichedRecord}),
    );

    return response.statusCode == 200 || response.statusCode == 201;
  }

  Future<bool> updateBudget(double daily, double monthly) async {
    final email = await getCurrentUser(); // 綁定帳號唯一預算
    if (email == null) return false;

    final url = Uri.parse('https://api.airtable.com/v0/$baseId/budget');

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'fields': {
          'daily_budget': daily,
          'monthly_budget': monthly,
          'email': email,
        },
      }),
    );

    return response.statusCode == 200 || response.statusCode == 201;
  }

  Future<Map<String, double>> fetchBudget() async {
    final email = await getCurrentUser();
    final url = Uri.parse('https://api.airtable.com/v0/$baseId/budget');

    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $apiKey'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      for (var rec in data['records']) {
        final fields = rec['fields'];
        if (fields['email'] == email) {
          return {
            'daily': (fields['daily_budget'] ?? 0).toDouble(),
            'monthly': (fields['monthly_budget'] ?? 0).toDouble(),
          };
        }
      }
    }
    return {'daily': 0, 'monthly': 0};
  }

  Future<double> calculateTotalExpense() async {
    final email = await getCurrentUser();
    final url = Uri.parse('https://api.airtable.com/v0/$baseId/record');

    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $apiKey'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final records = data['records'] as List;
      double total = 0;

      for (var record in records) {
        final fields = record['fields'];
        if (fields['type'] == '支出' && fields['email'] == email) {
          total += (fields['amount'] ?? 0).toDouble();
        }
      }

      return total;
    }

    return 0;
  }

  // ----------------------
  // 新增功能
  // ----------------------

  Future<bool> loginAccount(String email, String password) async {
    final accounts = await fetchAccounts();
    final match = accounts.firstWhere(
      (acc) => acc['email'] == email && acc['password'] == password,
      orElse: () => {},
    );
    if (match.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('email', email);
      return true;
    }
    return false;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('email');
  }

  Future<String?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('email');
  }

  Future<List<Map<String, dynamic>>> fetchRecords() async {
    final email = await getCurrentUser();
    final url = Uri.parse('https://api.airtable.com/v0/$baseId/record');
    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $apiKey'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['records'] as List)
          .map<Map<String, dynamic>>((record) => record['fields'])
          .where((fields) => fields['email'] == email)
          .toList();
    } else {
      throw Exception('Failed to fetch records');
    }
  }
}
