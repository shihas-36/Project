import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:gpa_frontend/auth/login_page.dart';
import 'package:gpa_frontend/export.dart'; // Import the existing export package

const String baseUrl = 'http://10.0.2.2:8000'; // Example base URL

class FacultyService {
  final storage = FlutterSecureStorage();

  Future<List<Map<String, dynamic>>> fetchStudentsByFaculty() async {
    final authToken = await storage.read(key: 'auth_token'); // Retrieve token
    final url = Uri.parse('$baseUrl/fetch_students_by_faculty/');
    try {
      print('Sending GET request to $url'); // Log the request URL
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
        },
      );

      // Log the response
      print('Fetch Students Response: ${response.statusCode}');
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
      print('Error occurred while fetching students: $e');
      throw Exception('Error occurred while fetching students: $e');
    }
  }

  Future<void> fetchAndGeneratePDF(BuildContext context, String ktuid) async {
    print('fetchAndGeneratePDF method called'); // Add this
    try {
      final authToken = await storage.read(key: 'auth_token');
      if (authToken == null) throw Exception('No authentication token found');

      final url = Uri.parse('$baseUrl/export-pdf/');
      print(
          'Sending POST request to $url with KTUID: $ktuid'); // Log the request
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
        },
        body: json.encode({'ktuid': ktuid}), // Pass the KTUID to the backend
      );

      // Log the response
      print('Export PDF Response: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final pdfBytes = response.bodyBytes;

        // Save the PDF locally
        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/$ktuid-gpa-report.pdf');
        await file.writeAsBytes(pdfBytes);

        // Open the PDF
        await OpenFile.open(file.path);
      } else {
        throw Exception('Failed to export PDF: ${response.body}');
      }
    } catch (e) {
      print('Error occurred while exporting PDF: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
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
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              // Clear stored tokens
              final storage = FlutterSecureStorage();
              await storage.delete(key: 'auth_token');
              await storage.delete(key: 'refresh_token');

              // Navigate to the correct page
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => LoginPage()),
              );
            },
          ),
        ],
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
                  trailing: IconButton(
                    icon: const Icon(Icons.download),
                    onPressed: () async {
                      try {
                        // Use the existing export functionality
                        await ExportPage().fetchAndGeneratePDF(
                          context, // Pass the BuildContext
                          student['KTUID'] ?? 'N/A', // Pass the KTUID
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e')),
                        );
                      }
                    },
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
