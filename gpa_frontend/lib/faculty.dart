import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const String baseUrl = 'http://10.0.2.2:8000'; // Example base URL

class FacultyService {
  final storage = FlutterSecureStorage();

  Future<List<Map<String, dynamic>>> fetchStudentsByFaculty() async {
    final authToken = await storage.read(key: 'auth_token'); // Retrieve token
    final url = Uri.parse('$baseUrl/fetch_students_by_faculty/');
    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
        },
      );

      // Log the response body for debugging
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is! Map || !data.containsKey('students')) {
          throw Exception('Unexpected response format');
        }
        return List<Map<String, dynamic>>.from(data['students'].map((student) {
          return {
            'name': student['name'] ?? 'No Name',
            'KTUID': student['KTUID'] ?? 'N/A',
            'degree': student['degree'] ?? 'Not Specified',
            'semester': student['semester']?.toString() ?? '0',
            'cgpa': student['cgpa']?.toString() ?? '0.0',
          };
        }).toList());
      } else {
        throw Exception('Failed to fetch students: ${response.body}');
      }
    } catch (e) {
      print('Error: $e'); // Log the error for debugging
      throw Exception('Error occurred while fetching students: $e');
    }
  }
}

class FacultyPage extends StatelessWidget {
  final FacultyService facultyService = FacultyService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Faculty Dashboard'),
        backgroundColor: const Color.fromARGB(255, 20, 53, 89),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: facultyService.fetchStudentsByFaculty(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No students found.'));
          } else {
            final students = snapshot.data!;
            return ListView.builder(
              itemCount: students.length,
              itemBuilder: (context, index) {
                final student = students[index];
                return ListTile(
                  title: Text(student['name']),
                  subtitle: Text(
                    'Reg No: ${student['KTUID'] ?? 'N/A'}\n'
                    'Degree: ${student['degree'] ?? 'Unknown'}, '
                    'Semester: ${student['semester'] ?? ''}\n'
                    'CGPA: ${student['cgpa'] ?? ''}',
                  ),
                  isThreeLine: true,
                );
              },
            );
          }
        },
      ),
    );
  }
}
