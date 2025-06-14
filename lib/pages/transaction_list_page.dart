import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config.dart'; // ✅ 共用設定檔

class TransactionListPage extends StatefulWidget {
  const TransactionListPage({super.key});

  @override
  State<TransactionListPage> createState() => _TransactionListPageState();
}

class _TransactionListPageState extends State<TransactionListPage> {
  final String apiKey = airtableApiKey;
  final String baseId = airtableBaseId;
  final String tableName = 'record';

  List<Map<String, dynamic>> records = [];
  bool isLoading = true;
  String? email;
  String filterType = '全部';
  String filterMonth = '全部';

  @override
  void initState() {
    super.initState();
    fetchUserTransactions();
  }

  Future<void> fetchUserTransactions() async {
    setState(() => isLoading = true);
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

    email = storedEmail;
    final formula = '{email} = "$storedEmail"';
    final url = Uri.parse(
      'https://api.airtable.com/v0/$baseId/$tableName'
      '?filterByFormula=${Uri.encodeComponent(formula)}'
      '&sort[0][field]=date&sort[0][direction]=desc',
    );

    final headers = {
      'Authorization': 'Bearer $apiKey',
      'Content-Type': 'application/json',
    };

    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final fetchedRecords = data['records'] as List;

      setState(() {
        records = fetchedRecords.map((record) {
          final fields = record['fields'] ?? {};
          final createdTime = record['createdTime'] ?? '';
          final date = fields['date'] ?? createdTime.substring(0, 10);
          return {
            'id': record['id'],
            'name': fields['name'] ?? '',
            'amount': fields['amount'] ?? 0,
            'category': fields['category'] ?? '',
            'note': fields['note'] ?? '',
            'method': fields['method'] ?? '',
            'type': fields['type'] ?? '',
            'date': date,
          };
        }).toList();
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('取得資料失敗：${response.body}')),
      );
    }
  }

  List<Map<String, dynamic>> get filteredRecords {
    return records.where((r) {
      final matchesType = filterType == '全部' || r['type'] == filterType;
      final matchesMonth = filterMonth == '全部' ||
          (r['date'].toString().length >= 7 &&
              r['date'].toString().substring(5, 7) == filterMonth);
      return matchesType && matchesMonth;
    }).toList();
  }

  void showRecordDetail(Map<String, dynamic> record) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(record['name']),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('金額：${record['amount']} 元'),
            Text('類別：${record['category']}'),
            Text('方式：${record['method']}'),
            Text('備註：${record['note']}'),
            Text('類型：${record['type']}'),
            Text('日期：${record['date']}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('關閉'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await deleteRecord(record['id']);
            },
            child: const Text('刪除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> deleteRecord(String id) async {
    final url = Uri.parse('https://api.airtable.com/v0/$baseId/$tableName/$id');
    final headers = {'Authorization': 'Bearer $apiKey'};

    final response = await http.delete(url, headers: headers);

    if (response.statusCode == 200) {
      setState(() => records.removeWhere((r) => r['id'] == id));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('刪除成功')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('刪除失敗：${response.body}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('記帳紀錄')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      DropdownButton<String>(
                        value: filterType,
                        items: ['全部', '支出', '收入']
                            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                            .toList(),
                        onChanged: (value) => setState(() => filterType = value!),
                      ),
                      const SizedBox(width: 20),
                      DropdownButton<String>(
                        value: filterMonth,
                        items: ['全部', for (var i = 1; i <= 12; i++) i.toString().padLeft(2, '0')]
                            .map((e) => DropdownMenuItem(value: e, child: Text('$e 月')))
                            .toList(),
                        onChanged: (value) => setState(() => filterMonth = value!),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: filteredRecords.isEmpty
                      ? const Center(child: Text('目前沒有紀錄'))
                      : ListView.builder(
                          itemCount: filteredRecords.length,
                          itemBuilder: (context, index) {
                            final record = filteredRecords[index];
                            return Card(
                              margin: const EdgeInsets.all(8.0),
                              child: ListTile(
                                title: Text('${record['name']} - ${record['amount']} 元'),
                                subtitle: Text(
                                  '${record['category']}｜${record['method']}｜${record['note']}',
                                ),
                                trailing: Text(
                                  record['date'],
                                  style: const TextStyle(color: Colors.grey),
                                ),
                                onTap: () => showRecordDetail(record),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
