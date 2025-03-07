import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:8000/api/';

  static Future<http.Response> signUp(Map<String, dynamic> data) async {
    return await http.post(
      Uri.parse('${baseUrl}signup/'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(data),
    );
  }

  // Function to handle submitting grades
  static Future<http.Response> fillGrades(
      Map<String, dynamic> data, String token) async {
    return await http.post(
      Uri.parse('http://10.0.2.2:8000/Fill_grades/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(data),
    );
  }

  static Future<http.Response> login(String email, String password) async {
    return await http.post(
      Uri.parse('${baseUrl}login/'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email, 'password': password}),
    );
  }
}
