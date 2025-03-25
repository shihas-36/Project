import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class MinorCalculatorPage extends StatefulWidget {
  @override
  _MinorCalculatorPageState createState() => _MinorCalculatorPageState();
}

class _MinorCalculatorPageState extends State<MinorCalculatorPage> {
  final FlutterSecureStorage storage = FlutterSecureStorage();
  Map<String, Map<String, Map<String, int>>> _minorBuckets = {};
  Map<String, Map<String, Map<String, int>>> _honorBuckets = {};
  Map<String, TextEditingController> _gradeControllers = {};
  Map<String, double> _sgpaMap = {}; // Store SGPA for each semester
  String _selectedMinorBucket = 'Bucket 1';
  String _selectedHonorBucket = 'Bucket 1';
  Map<String, String> _selectedMinorSubjects = {};
  Map<String, String> _selectedHonorSubjects = {};
  List<String> _grades = ['S', 'A', 'A+', 'B+', 'B', 'C+', 'C', 'D+', 'P', 'F'];
  bool _isMinorStudent = false; // Flag to check if the user is a minor student
  bool _isHonorStudent = false; // Flag to check if the user is an honor student

  @override
  void initState() {
    super.initState();
    _checkMinorStatus();
  }

  Future<void> _checkMinorStatus() async {
    try {
      final token = await storage.read(key: 'auth_token');
      if (token == null) throw Exception('No authentication token found');

      final response = await http.get(
        Uri.parse('http://10.0.2.2:8000/check_minor_status/'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      print("Response body: ${response.body}");
      print("Response status code: ${response.statusCode}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        setState(() {
          _isMinorStudent = data['is_minor_student'];
          _isHonorStudent = data['is_honor_student'];
          if (_isMinorStudent || _isHonorStudent) {
            _fetchSubjects();
          }
        });
      } else {
        throw Exception('Failed to check minor status: ${response.statusCode}');
      }
    } catch (e) {
      print("Error checking minor status: $e");
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Error'),
            content: Text('Failed to check minor status: $e'),
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

  Future<void> _fetchSubjects() async {
    try {
      final token = await storage.read(key: 'auth_token');
      if (token == null) throw Exception('No authentication token found');

      final response = await http.get(
        Uri.parse('http://10.0.2.2:8000/get_minor_subjects/'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      print("Response status code: ${response.statusCode}");
      print("Response body: ${response.body}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        setState(() {
          _minorBuckets =
              (data['Minor'] as Map<String, dynamic>).map((bucket, semesters) {
            return MapEntry(
                bucket,
                (semesters as Map<String, dynamic>).map((semester, subjects) {
                  return MapEntry(
                      semester,
                      (subjects as Map<String, dynamic>)
                          .map((subject, credits) {
                        return MapEntry(subject, credits as int);
                      }));
                }));
          }).cast<String, Map<String, Map<String, int>>>();

          _honorBuckets =
              (data['Honor'] as Map<String, dynamic>).map((bucket, semesters) {
            return MapEntry(
                bucket,
                (semesters as Map<String, dynamic>).map((semester, subjects) {
                  return MapEntry(
                      semester,
                      (subjects as Map<String, dynamic>)
                          .map((subject, credits) {
                        return MapEntry(subject, credits as int);
                      }));
                }));
          }).cast<String, Map<String, Map<String, int>>>();

          _minorBuckets[_selectedMinorBucket]?.forEach((semester, subjects) {
            _selectedMinorSubjects[semester] = subjects.keys.first;
            subjects.forEach((subject, credits) {
              _gradeControllers[subject] = TextEditingController(text: 'S');
            });
          });

          _honorBuckets[_selectedHonorBucket]?.forEach((semester, subjects) {
            _selectedHonorSubjects[semester] = subjects.keys.first;
            subjects.forEach((subject, credits) {
              _gradeControllers[subject] = TextEditingController(text: 'S');
            });
          });
        });
      } else {
        throw Exception('Failed to fetch subjects: ${response.statusCode}');
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

  Future<void> _calculateNewSgpa(String semester, String type) async {
    try {
      final token = await storage.read(key: 'auth_token');
      if (token == null) throw Exception('No authentication token found');

      // Get the selected subject and its grade for the selected semester
      final selectedSubject = type == 'Minor'
          ? _selectedMinorSubjects[semester]
          : _selectedHonorSubjects[semester];
      final selectedGrade = _gradeControllers[selectedSubject]?.text ?? 'S';

      if (selectedSubject == null || selectedGrade == null) {
        throw Exception(
            'No selected subject or grade found for the selected semester');
      }

      final minorGrades = {selectedSubject: selectedGrade};

      final response = await http.post(
        Uri.parse('http://10.0.2.2:8000/calculate_minor/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'semester': semester,
          'minor_grades': minorGrades,
          'Type': type, // Include the selected type (Minor or Honor)
          'Bucket': type == 'Minor'
              ? _selectedMinorBucket
              : _selectedHonorBucket, // Include the selected bucket
        }),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        setState(() {
          _sgpaMap[semester] = responseData['semester_sgpa'];
        });
      } else {
        throw Exception('Failed to calculate new SGPA: ${response.statusCode}');
      }
    } catch (e) {
      print("Error calculating new SGPA: $e");
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Error'),
            content: Text('Failed to calculate new SGPA: $e'),
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

  Widget _buildDropdowns(String type) {
    final buckets = type == 'Minor' ? _minorBuckets : _honorBuckets;
    final selectedBucket =
        type == 'Minor' ? _selectedMinorBucket : _selectedHonorBucket;
    final selectedSubjects =
        type == 'Minor' ? _selectedMinorSubjects : _selectedHonorSubjects;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min, // Add this to prevent unbounded height
      children: [
        Center(
          child: DropdownButton<String>(
            value: selectedBucket,
            onChanged: (String? newValue) {
              setState(() {
                if (type == 'Minor') {
                  _selectedMinorBucket = newValue!;
                } else {
                  _selectedHonorBucket = newValue!;
                }
                _fetchSubjects(); // Fetch subjects based on the selected type
              });
            },
            items: buckets.keys.map<DropdownMenuItem<String>>((String bucket) {
              return DropdownMenuItem<String>(
                value: bucket,
                child: Text(bucket),
              );
            }).toList(),
          ),
        ),
        SizedBox(height: 16),
        SizedBox(
          height: 300, // Set a reasonable fixed height or calculate dynamically
          child: ListView.builder(
            shrinkWrap: true, // Add this
            physics:
                ClampingScrollPhysics(), // Add this for better scrolling behavior
            itemCount: buckets[selectedBucket]?.length ?? 0,
            itemBuilder: (context, index) {
              String semester =
                  buckets[selectedBucket]?.keys.elementAt(index) ?? '';
              String selectedSubject = selectedSubjects[semester] ?? '';
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      semester.split('_').last,
                      style: TextStyle(fontSize: 16),
                    ),
                    DropdownButton<String>(
                      value: selectedSubject,
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedSubjects[semester] = newValue!;
                        });
                      },
                      items: buckets[selectedBucket]?[semester]
                          ?.keys
                          .map<DropdownMenuItem<String>>((String subject) {
                        return DropdownMenuItem<String>(
                          value: subject,
                          child: Text(subject),
                        );
                      }).toList(),
                    ),
                    DropdownButton<String>(
                      value: _gradeControllers[selectedSubject]?.text,
                      onChanged: (String? newValue) {
                        setState(() {
                          _gradeControllers[selectedSubject]?.text = newValue!;
                          _calculateNewSgpa(
                              semester, type); // Calculate SGPA on grade change
                        });
                      },
                      items:
                          _grades.map<DropdownMenuItem<String>>((String grade) {
                        return DropdownMenuItem<String>(
                          value: grade,
                          child: Text(grade),
                        );
                      }).toList(),
                    ),
                    if (_sgpaMap[semester] != null)
                      Text(
                        'SGPA: ${_sgpaMap[semester]!.toStringAsFixed(2)}',
                        style: TextStyle(fontSize: 16),
                      )
                    else
                      Text(
                        'SGPA: 0.00',
                        style: TextStyle(fontSize: 16),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Minor Calculator'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: _isMinorStudent || _isHonorStudent
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min, // Add this
                  children: [
                    if (_isMinorStudent) ...[
                      Text(
                        'MINOR',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      _buildDropdowns('Minor'),
                      SizedBox(height: 20), // Add some spacing between sections
                    ],
                    if (_isHonorStudent) ...[
                      Text(
                        'HONOR',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      _buildDropdowns('Honor'),
                    ],
                  ],
                )
              : Center(
                  child: Text(
                    "You're not chosen minor/honour course",
                    style: TextStyle(fontSize: 18),
                  ),
                ),
        ),
      ),
    );
  }
}
