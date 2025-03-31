import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SummaryPage extends StatefulWidget {
  @override
  _SummaryPageState createState() => _SummaryPageState();
}

final FlutterSecureStorage storage = FlutterSecureStorage();

class _SummaryPageState extends State<SummaryPage> {
  Map<String, dynamic>? summaryData; // Initialize as nullable

  @override
  void initState() {
    super.initState();
    fetchSummaryData();
  }

  Future<void> fetchSummaryData() async {
    final token = await storage.read(key: 'auth_token');
    if (token == null) throw Exception('No authentication token found');
    final response = await http.get(
      Uri.parse('http://10.0.2.2:8000/Summary/'), // Fix the typo in the URL
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      setState(() {
        summaryData = json.decode(response.body);
      });
    } else {
      throw Exception('Failed to load summary data');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Summary Page'),
      ),
      body: summaryData == null
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  SummaryBox(
                    title: 'Best Semester',
                    value: summaryData?['best_semester']?.toString() ?? 'N/A',
                  ),
                  SummaryBox(
                    title: 'Worst Semester',
                    value: summaryData?['worst_semester']?.toString() ?? 'N/A',
                  ),
                  SummaryBox(
                    title: 'Topper Count',
                    value: summaryData?['topper_count']?.toString() ?? 'N/A',
                  ),
                  SummaryBox(
                    title: 'Supply Count',
                    value: summaryData?['supply_count']?.toString() ?? 'N/A',
                  ),
                  SummaryBox(
                    title: 'Yearback Required',
                    value:
                        summaryData?['yearback_required']?.toString() ?? 'N/A',
                  ),
                  SummaryBox(
                    title: 'SGPA Required',
                    value: summaryData?['sgpa_required'] != null
                        ? double.parse(summaryData!['sgpa_required'].toString())
                            .toStringAsFixed(2)
                        : 'N/A', // Ensure SGPA is formatted correctly
                  ),
                ],
              ),
            ),
    );
  }
}

class SummaryBox extends StatelessWidget {
  final String title;
  final String value;

  SummaryBox({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8.0),
      padding: EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.blueAccent),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
          ),
          Text(
            value,
            style: TextStyle(fontSize: 18.0),
          ),
        ],
      ),
    );
  }
}
