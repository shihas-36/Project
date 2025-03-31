import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class GpaCalculator extends StatefulWidget {
  @override
  _GpaCalculatorState createState() => _GpaCalculatorState();
}

class _GpaCalculatorState extends State<GpaCalculator>
    with TickerProviderStateMixin {
  final storage = FlutterSecureStorage();
  late TabController _tabController;
  Map<String, Map<String, Map<String, int>>> subjectsStructure = {};
  Map<String, Map<String, String?>> selectedSubjects = {};
  Map<String, Map<String, String?>> selectedGrades = {};
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
    _tabController = TabController(length: 1, vsync: this);
    fetchSubjects();
    fetchUserData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _updateTabController() {
    final newLength = subjectsStructure.keys.length;
    if (_tabController.length != newLength) {
      _tabController.dispose();
      _tabController = TabController(
        length: newLength,
        vsync: this,
      );
    }
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
        print('API Response: $data');

        final parsedData = data.map<String, Map<String, Map<String, int>>>(
            (semesterKey, semesterValue) {
          final slots = (semesterValue as Map<String, dynamic>)
              .map<String, Map<String, int>>((slotKey, slotValue) {
            return MapEntry(
              slotKey,
              (slotValue as Map<String, dynamic>).map<String, int>(
                (subject, credit) => MapEntry(subject, (credit as num).toInt()),
              ),
            );
          });
          return MapEntry(semesterKey, slots);
        });

        if (mounted) {
          setState(() {
            subjectsStructure = parsedData;

            // Initialize selections
            selectedSubjects = {};
            selectedGrades = {};

            parsedData.forEach((semester, slots) {
              selectedSubjects[semester] = {};
              selectedGrades[semester] = {};

              slots.forEach((slot, courses) {
                if (courses.isNotEmpty) {
                  // Select first course by default
                  selectedSubjects[semester]![slot] = courses.keys.first;
                  selectedGrades[semester]![courses.keys.first] = null;
                }
              });
            });

            _updateTabController();
          });
        }
      } else {
        throw Exception('Failed to load subjects: ${response.statusCode}');
      }
    } catch (e) {
      print("Error fetching subjects: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to fetch subjects: $e')),
        );
      }
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
        if (mounted) {
          setState(() {
            cgpa = responseData['cgpa']?.toDouble();
            for (var semesterData in responseData['semesters']) {
              String semesterKey = semesterData['semester'];
              for (var subject in semesterData['subjects']) {
                String subjectName = subject['name'];
                String? grade = subject['grade'];

                // Find which slot contains this subject
                subjectsStructure[semesterKey]?.forEach((slot, courses) {
                  if (courses.containsKey(subjectName)) {
                    // Set this as the selected subject for the slot
                    selectedSubjects[semesterKey] ??= {};
                    selectedSubjects[semesterKey]![slot] = subjectName;

                    // Set the grade if it exists
                    selectedGrades[semesterKey] ??= {};
                    if (grade != null) {
                      selectedGrades[semesterKey]![subjectName] = grade;
                    }
                  }
                });
              }
            }
          });
        }
      }
    } catch (e) {
      print("Error fetching user data: $e");
    }
  }

  Future<void> calculateGPA() async {
    setState(() {
      isLoading = true;
    });

    try {
      final token = await storage.read(key: 'auth_token');
      if (token == null) throw Exception('No authentication token found');

      final semester = subjectsStructure.keys.elementAt(_tabController.index);

      // Prepare grades for currently selected subjects
      Map<String, String?> gradesToSend = {};
      selectedSubjects[semester]!.forEach((slot, subject) {
        if (subject != null && selectedGrades[semester]!.containsKey(subject)) {
          gradesToSend[subject] = selectedGrades[semester]![subject];
        }
      });

      // Check if all grades are selected
      if (gradesToSend.values.any((grade) => grade == null)) {
        throw Exception('Please select grades for all subjects');
      }

      final payload = json.encode({
        'semester': semester,
        'grades': gradesToSend,
      });
      print('Payload: $payload');
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
        if (mounted) {
          setState(() {
            gpa = responseData['semester_gpa']?.toDouble();
            cgpa = responseData['cgpa']?.toDouble();
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('GPA calculated successfully!')),
          );
        }
      } else {
        throw Exception('Failed to calculate GPA: ${response.statusCode}');
      }
    } catch (e) {
      print("An error occurred: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to calculate GPA: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Widget _buildCourseCard(
      String semester, String slot, Map<String, int> courses) {
    // Get current subject with null check
    final currentSubject = selectedSubjects[semester]?[slot];
    // Verify the subject exists in current courses
    final validSubject = courses.containsKey(currentSubject)
        ? currentSubject
        : (courses.isNotEmpty ? courses.keys.first : null);

    // Get current grade with null check
    final currentGrade =
        (validSubject != null && selectedGrades[semester] != null)
            ? selectedGrades[semester]![validSubject]
            : null;

    return Container(
      margin: EdgeInsets.symmetric(vertical: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, Colors.blue[50]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: courses.isEmpty
                ? Text(
                    'No courses available',
                    style: TextStyle(color: Colors.black, fontSize: 16),
                  )
                : DropdownButton<String>(
                    value: validSubject,
                    isExpanded: true,
                    underline: Container(),
                    style: TextStyle(fontSize: 16, color: Colors.black),
                    items: [
                      // Remove duplicates using Set
                      ...Set.from(courses.keys).map((course) {
                        return DropdownMenuItem<String>(
                          value: course,
                          child: Text(course),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        selectedSubjects[semester] ??= {};
                        selectedGrades[semester] ??= {};

                        // Clear previous grade
                        final prev = selectedSubjects[semester]![slot];
                        if (prev != null) {
                          selectedGrades[semester]!.remove(prev);
                        }

                        // Set new subject
                        selectedSubjects[semester]![slot] = value;
                      });
                    },
                  ),
          ),
          if (validSubject != null)
            Container(
              width: 80,
              height: 40,
              margin: EdgeInsets.only(left: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: DropdownButton<String>(
                value: currentGrade,
                underline: Container(),
                icon:
                    Icon(Icons.arrow_drop_down, size: 18, color: Colors.black),
                style: TextStyle(fontSize: 16, color: Colors.black),
                items: gradeValues.keys.map((grade) {
                  return DropdownMenuItem<String>(
                    value: grade,
                    child: Center(
                      child: Text(
                        grade,
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    selectedGrades[semester]![validSubject] = value;
                  });
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSemesterView(String semester) {
    final slots = subjectsStructure[semester] ?? {};
    final grades = selectedGrades[semester] ?? {};
    final credits = slots.values.fold<Map<String, int>>({}, (map, courses) {
      map.addAll(courses);
      return map;
    });

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            semester.replaceAll('_', ' ').toUpperCase(),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.blue[800],
            ),
          ),
          SizedBox(height: 16),
          SemesterSummaryCard(
            grades: grades,
            credits: credits,
            gradeValues: gradeValues,
            subjectsStructure: subjectsStructure,
          ),
          ...slots.entries.map((slotEntry) {
            final slotName = slotEntry.key;
            final courses = slotEntry.value;
            return _buildCourseCard(semester, slotName, courses);
          }),
          if (gpa != null &&
              semester ==
                  subjectsStructure.keys.elementAt(_tabController.index))
            Column(
              children: [
                SizedBox(height: 20),
                Divider(),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Column(
                      children: [
                        Text('SEMESTER GPA',
                            style: TextStyle(
                                fontSize: 14, color: Colors.grey[700])),
                        Text(gpa?.toStringAsFixed(2) ?? 'N/A',
                            style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[800])),
                      ],
                    ),
                    Column(
                      children: [
                        Text('CGPA',
                            style: TextStyle(
                                fontSize: 14, color: Colors.grey[700])),
                        Text(cgpa?.toStringAsFixed(2) ?? 'N/A',
                            style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[800])),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 20),
              ],
            ),
          CalculateButton(
            isLoading: isLoading,
            onPressed: calculateGPA,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('GPA Calculator'),
        bottom: subjectsStructure.isNotEmpty
            ? TabBar(
                controller: _tabController,
                isScrollable: true,
                tabs: subjectsStructure.keys.map((semester) {
                  return Tab(text: semester.replaceAll('_', ' ').toUpperCase());
                }).toList(),
              )
            : null,
      ),
      body: subjectsStructure.isNotEmpty
          ? TabBarView(
              controller: _tabController,
              children: subjectsStructure.keys.map((semester) {
                return _buildSemesterView(semester);
              }).toList(),
            )
          : Center(child: CircularProgressIndicator()),
    );
  }
}

class CalculateButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;

  const CalculateButton({
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        minimumSize: Size(double.infinity, 50),
        padding: EdgeInsets.symmetric(vertical: 12),
        backgroundColor: Colors.blue[800],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: isLoading
          ? CircularProgressIndicator(color: Colors.white)
          : Text(
              'CALCULATE GPA',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
    );
  }
}

class SemesterSummaryCard extends StatelessWidget {
  final Map<String, String?> grades;
  final Map<String, int> credits;
  final Map<String, double> gradeValues;
  final Map<String, Map<String, Map<String, int>>> subjectsStructure;

  const SemesterSummaryCard({
    required this.grades,
    required this.credits,
    required this.gradeValues,
    required this.subjectsStructure,
  });

  @override
  Widget build(BuildContext context) {
    final Set<String> processedSlots = {}; // Track processed slots

    int totalCredits = grades.entries.fold(0, (sum, entry) {
      final grade = entry.value;
      final credit = credits[entry.key] ?? 0;

      // Check if the subject belongs to a slot already processed
      final slot = subjectsStructure.entries
          .firstWhere(
            (e) => e.value.values.any((c) => c.containsKey(entry.key)),
            orElse: () =>
                MapEntry('', {}), // Return an empty MapEntry if not found
          )
          .key;

      if (slot.isNotEmpty && processedSlots.contains(slot)) {
        print(
            'Skipping subject: ${entry.key} in slot: $slot, Grade: $grade, Credits: $credit'); // Log skipped subject
        return sum;
      }

      if (grade != 'F') {
        print(
            'Adding credits for subject: ${entry.key}, Grade: $grade, Credits: $credit'); // Log calculation
        if (slot != null) processedSlots.add(slot); // Mark slot as processed
        return sum + credit;
      } else {
        print(
            'Skipping subject: ${entry.key}, Grade: $grade, Credits: $credit'); // Log skipped subject
        return sum;
      }
    });

    int earnedCredits = grades.entries.fold(0, (sum, entry) {
      final grade = entry.value;
      final credit = credits[entry.key] ?? 0;
      if (grade != null && grade != 'F') {
        print(
            'Adding earned credits for subject: ${entry.key}, Grade: $grade, Credits: $credit'); // Log calculation
        return sum + credit;
      } else {
        print(
            'Skipping earned credits for subject: ${entry.key}, Grade: $grade, Credits: $credit'); // Log skipped subject
        return sum;
      }
    });

    double totalPoints = grades.entries.fold(0.0, (sum, entry) {
      final grade = entry.value;
      final credit = credits[entry.key] ?? 0;
      if (grade != null) {
        final points = (gradeValues[grade] ?? 0) * credit;
        print(
            'Adding points for subject: ${entry.key}, Grade: $grade, Credits: $credit, Points: $points'); // Log calculation
        return sum + points;
      } else {
        print(
            'Skipping points for subject: ${entry.key}, Grade: $grade, Credits: $credit'); // Log skipped subject
        return sum;
      }
    });

    bool allGradesSelected = grades.values.every((grade) => grade != null);

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Semester Summary',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSummaryItem('Total Credits', '$totalCredits'),
                _buildSummaryItem('Earned Credits', '$earnedCredits'),
              ],
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSummaryItem(
                  'Completion',
                  '${grades.values.where((g) => g != null).length}/${grades.length}',
                ),
                _buildSummaryItem(
                  'Estimated GPA',
                  allGradesSelected
                      ? (totalPoints / totalCredits).toStringAsFixed(2)
                      : 'N/A',
                  isHighlighted: allGradesSelected,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value,
      {bool isHighlighted = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isHighlighted ? Colors.blue : Colors.black,
          ),
        ),
      ],
    );
  }
}
