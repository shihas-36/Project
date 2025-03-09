import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class GradeCalculatorPage extends StatefulWidget {
  @override
  _GradeCalculatorPageState createState() => _GradeCalculatorPageState();
}

class _GradeCalculatorPageState extends State<GradeCalculatorPage> {
  final storage = FlutterSecureStorage();
  Map<String, Map<String, int>> subjectsCredits = {};
  Map<String, Map<String, String>> semesterGrades = {};
  String currentSemester = 'semester_1';
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    try {
      currentSemester =
          await storage.read(key: 'current_semester') ?? 'semester_1';
      await fetchSubjects();
    } catch (e) {
      setState(() {
        errorMessage = 'Initialization error: $e';
        isLoading = false;
      });
    }
  }

  Future<void> fetchSubjects() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final token = await storage.read(key: 'auth_token');
      if (token == null) throw Exception('No authentication token found');

      final response = await http.get(
        Uri.parse('http://10.0.2.2:8000/get_subjects/'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        setState(() {
          subjectsCredits = data.map((semesterKey, subjectsMap) {
            return MapEntry(
              semesterKey,
              (subjectsMap as Map<String, dynamic>).map<String, int>(
                (subject, credit) => MapEntry(subject, credit as int),
              ),
            );
          });

          // Initialize with default grade "S"
          semesterGrades = subjectsCredits.map((semester, subjects) => MapEntry(
              semester, subjects.map((subject, _) => MapEntry(subject, "S"))));
        });
      } else {
        throw Exception('Failed to load subjects: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error fetching subjects: $e';
      });
      _showErrorDialog('Failed to fetch subjects: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showMarksDialog(String subject) {
    final TextEditingController internalController =
        TextEditingController(text: '0');
    final TextEditingController universityController =
        TextEditingController(text: '0');
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Enter Marks for $subject'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: internalController,
                    decoration: InputDecoration(labelText: 'Internal Marks'),
                    keyboardType: TextInputType.number,
                  ),
                  TextField(
                    controller: universityController,
                    decoration: InputDecoration(labelText: 'University Marks'),
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
              actions: [
                if (isSubmitting)
                  CircularProgressIndicator()
                else
                  TextButton(
                    onPressed: () async {
                      final internal =
                          double.tryParse(internalController.text) ?? 0;
                      final university =
                          double.tryParse(universityController.text) ?? 0;
                      final total = internal + university;

                      setState(() => isSubmitting = true);

                      try {
                        final token = await storage.read(key: 'auth_token');
                        if (token == null)
                          throw Exception('No authentication token found');

                        final requestBody = json.encode({'marks': total});
                        print(
                            "Sent request to /calculate_grade with body: $requestBody"); // Log request body

                        final response = await http.post(
                          Uri.parse('http://10.0.2.2:8000/calculate_grade/'),
                          headers: {
                            'Content-Type': 'application/json',
                            'Authorization': 'Bearer $token',
                          },
                          body: requestBody,
                        );

                        if (response.statusCode == 200) {
                          final result = json.decode(response.body);
                          print(
                              "Received response from /calculate_grade: $result"); // Log response body
                          this.setState(() {
                            semesterGrades[currentSemester]![subject] =
                                result['grade'];
                          });
                          Navigator.of(context).pop();
                        } else {
                          final error = jsonDecode(response.body)['error'] ??
                              'Unknown error';
                          print(
                              "Received error response from /calculate_grade: $error"); // Log error response
                          throw Exception('Grade calculation failed: $error');
                        }
                      } catch (e) {
                        _showErrorDialog('Grade calculation failed: $e');
                      } finally {
                        setState(() => isSubmitting = false);
                      }
                    },
                    child: Text('Calculate Grade'),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Error'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentSubjects =
        subjectsCredits[currentSemester]?.keys.toList() ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text('Grade Calculator'),
        actions: [
          DropdownButton<String>(
            value: currentSemester,
            items: subjectsCredits.keys.map((semester) {
              return DropdownMenuItem(
                value: semester,
                child: Text(semester.replaceAll('_', ' ').toUpperCase()),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => currentSemester = value);
              }
            },
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(child: Text(errorMessage!))
              : currentSubjects.isEmpty
                  ? Center(child: Text('No subjects found for this semester'))
                  : ListView.builder(
                      itemCount: currentSubjects.length,
                      itemBuilder: (context, index) {
                        final subject = currentSubjects[index];
                        final credits =
                            subjectsCredits[currentSemester]![subject]!;
                        final grade =
                            semesterGrades[currentSemester]![subject]!;

                        return ListTile(
                          title: Text(subject),
                          subtitle: Text('Credits: $credits'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Chip(
                                label: Text(grade),
                                backgroundColor: Colors.blue[100],
                              ),
                              IconButton(
                                icon: Icon(Icons.edit),
                                onPressed: () => _showMarksDialog(subject),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
    );
  }
}
