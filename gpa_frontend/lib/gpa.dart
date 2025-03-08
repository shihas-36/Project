import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class GpaCalculator extends StatefulWidget {
  @override
  _GpaCalculatorState createState() => _GpaCalculatorState();
}

class _GpaCalculatorState extends State<GpaCalculator> {
  final storage = FlutterSecureStorage(); // Instantiate secure storage
  Map<String, Map<String, int>> subjectsCredits = {};
  Map<String, Map<String, String?>> semesterGrades = {};
  String currentSemester = 'semester_1';
  double? gpa;
  double? cgpa;
  bool isLoading = false;

  final Map<String, double> gradeValues = {
    'S': 10,
    'A': 9,
    'A+': 8.5,
    'B+': 8,
    'B': 7.5,
    'C+': 7,
    'C': 6.5,
    'D+': 6,
    'P': 5.5,
    'F': 0,
  };

  @override
  void initState() {
    super.initState();
    fetchInitialSemester();
    fetchSubjects();
    fetchUserData();
  }

  Future<void> fetchInitialSemester() async {
    final initialSemester = await storage.read(key: 'current_semester');
    setState(() {
      currentSemester = initialSemester ?? 'semester_1';
    });
  }

  Future<void> fetchSubjects() async {
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

          // Initialize semesterGrades with normalized keys
          semesterGrades = subjectsCredits.map((semester, subjects) => MapEntry(
              semester, subjects.map((subject, _) => MapEntry(subject, null))));
        });
      } else {
        throw Exception('Failed to load subjects: ${response.statusCode}');
      }
    } catch (e) {
      print("Error fetching subjects: $e");
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Error'),
            content: Text('Failed to fetch subjects: $e'),
            actions: <Widget>[
              TextButton(
                child: Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }
  }

  Future<void> fetchUserData() async {
    try {
      final token = await storage.read(key: 'auth_token');
      if (token == null) throw Exception('No authentication token found');

      final response = await http.get(
        Uri.parse('http://10.0.2.2:8000/get_user_data/'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        setState(() {
          cgpa = responseData['cgpa']?.toDouble();
          for (var semesterData in responseData['semesters']) {
            String semesterKey = semesterData['semester'];
            semesterGrades[semesterKey] = {};
            for (var subject in semesterData['subjects']) {
              // Normalize subject keys to match subjectsCredits
              String normalizedSubject = subject['name']
                  .toLowerCase()
                  .replaceAll(' ', '_')
                  .replaceAll('&', '_and_')
                  .replaceAll(RegExp(r'[^a-z0-9_]'), '');

              if (subjectsCredits[semesterKey]!
                  .containsKey(normalizedSubject)) {
                semesterGrades[semesterKey]![normalizedSubject] =
                    subject['grade'];
              }
            }
          }
        });
      } else {
        throw Exception('Failed to fetch user data: ${response.statusCode}');
      }
    } catch (e) {
      print("Error fetching user data: $e");
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Error'),
            content: Text('Failed to fetch user data: $e'),
            actions: <Widget>[
              TextButton(
                child: Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }
  }

  Future<void> calculateGPA() async {
    setState(() {
      isLoading = true;
      print("Calculate button pressed, loading set to true.");
    });

    try {
      final token = await storage.read(key: 'auth_token');
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final semester = currentSemester; // Ensure this is set correctly

      Map<String, String?> formattedSubjectGrades = {
        for (var entry in semesterGrades[semester]!.entries)
          entry.key: entry.value // Use original subject names
      };

      final payload = json.encode({
        'semester': semester, // Ensure this field is sent correctly
        'grades': formattedSubjectGrades,
      });

      print("Request payload: $payload");

      final response = await http.post(
        Uri.parse('http://10.0.2.2:8000/calculate_gpa/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: payload,
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        setState(() {
          gpa = responseData['semester_gpa']?.toDouble();
          cgpa = responseData['cgpa']?.toDouble();
          print("GPA calculated successfully: $gpa");
          print("CGPA calculated successfully: $cgpa");
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text('Success'),
                content: Text(
                    'Data sent successfully! Your GPA is ${gpa?.toStringAsFixed(2) ?? 'N/A'}\nYour CGPA is ${cgpa?.toStringAsFixed(2) ?? 'N/A'}'),
                actions: <Widget>[
                  TextButton(
                    child: Text('OK'),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              );
            },
          );
        });
      } else {
        print("Error response: ${response.body}");
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Error'),
              content: Text('Failed to calculate GPA. Error: ${response.body}'),
              actions: <Widget>[
                TextButton(
                  child: Text('OK'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
        throw Exception('Failed to calculate GPA');
      }
    } catch (e) {
      print("An error occurred: $e");
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Error'),
            content: Text('An error occurred: $e'),
            actions: <Widget>[
              TextButton(
                child: Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    } finally {
      setState(() {
        isLoading = false;
        print("Loading set to false.");
      });
    }
  }

  DropdownButtonFormField<String> buildSubjectDropdown(
      String subject, String? value, void Function(String?) onChanged) {
    return DropdownButtonFormField(
      value: value,
      items: gradeValues.keys.map((grade) {
        return DropdownMenuItem(
          value: grade,
          child: Text(grade),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          semesterGrades[currentSemester]![subject] = value;
          print("$subject grade set to $value");
        });
        onChanged(value);
      },
      decoration: InputDecoration(
        labelText: subject,
        border: OutlineInputBorder(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('GPA Calculator')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: subjectsCredits.isEmpty
            ? Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  DropdownButton<String>(
                    value: currentSemester,
                    onChanged: (String? newValue) {
                      setState(() {
                        currentSemester = newValue!;
                      });
                    },
                    items: subjectsCredits.keys
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: subjectsCredits[currentSemester]!
                            .keys
                            .map((subject) => Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 10),
                                  child: buildSubjectDropdown(
                                    subject,
                                    semesterGrades[currentSemester]![subject],
                                    (value) {
                                      setState(() => semesterGrades[
                                          currentSemester]![subject] = value);
                                    },
                                  ),
                                ))
                            .toList(),
                      ),
                    ),
                  ),
                  SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: () {
                      if (semesterGrades[currentSemester]!
                          .values
                          .every((grade) => grade != null)) {
                        calculateGPA();
                      }
                    },
                    child: isLoading
                        ? CircularProgressIndicator(color: Colors.white)
                        : Text('Calculate GPA'),
                  ),
                  if (gpa != null && cgpa != null) ...[
                    SizedBox(height: 20),
                    Container(
                      padding: EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.blue),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Text(
                        'Your SGPA: ${gpa!.toStringAsFixed(2)}',
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                    ),
                    SizedBox(height: 20),
                    Container(
                      padding: EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.blue),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Text(
                        'Your CGPA: ${cgpa!.toStringAsFixed(2)}',
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}
