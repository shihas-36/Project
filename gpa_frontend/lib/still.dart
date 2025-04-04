import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SubjectCard extends StatefulWidget {
  final String subjectName;
  final int credits;
  final String? selectedGrade;
  final ValueChanged<String?> onGradeChanged;
  final Map<String, double> gradeValues;

  const SubjectCard({
    required this.subjectName,
    required this.credits,
    required this.selectedGrade,
    required this.onGradeChanged,
    required this.gradeValues,
  });

  @override
  _SubjectCardState createState() => _SubjectCardState();
}

class _SubjectCardState extends State<SubjectCard> {
  bool _isTapped = false;

  Color _getGradeColor(String grade) {
    switch (grade) {
      case 'S':
        return Colors.green[800]!;
      case 'A':
        return Colors.green;
      case 'A+':
        return Colors.lightGreen;
      case 'B+':
        return Colors.blue;
      case 'B':
        return Colors.blue[400]!;
      case 'C+':
        return Colors.orange;
      case 'C':
        return Colors.orange[400]!;
      case 'D+':
        return Colors.red[400]!;
      case 'P':
        return Colors.red[300]!;
      case 'F':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isTapped = true),
      onTapUp: (_) => setState(() => _isTapped = false),
      onTapCancel: () => setState(() => _isTapped = false),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 100),
        transform: Matrix4.identity()..scale(_isTapped ? 0.98 : 1.0),
        child: Card(
          elevation: 2,
          margin: EdgeInsets.symmetric(vertical: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: Padding(
            padding: EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.subjectName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Credits: ${widget.credits}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: widget.selectedGrade != null
                        ? _getGradeColor(widget.selectedGrade!)
                        : Colors.grey[200],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: widget.selectedGrade,
                      hint: Text(
                        'Select',
                        style: TextStyle(
                          color: Colors.grey[600],
                        ),
                      ),
                      dropdownColor: Colors.white,
                      icon: Icon(Icons.arrow_drop_down),
                      style: TextStyle(
                        color: widget.selectedGrade != null
                            ? Colors.white
                            : Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                      onChanged: (value) {
                        widget.onGradeChanged(value);
                      },
                      items: widget.gradeValues.keys.map((String grade) {
                        return DropdownMenuItem<String>(
                          value: grade,
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              color: _getGradeColor(grade),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                grade,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SemesterSummaryCard extends StatelessWidget {
  final Map<String, String?> grades;
  final Map<String, int> credits;
  final Map<String, double> gradeValues;

  const SemesterSummaryCard({
    required this.grades,
    required this.credits,
    required this.gradeValues,
  });

  @override
  Widget build(BuildContext context) {
    int totalCredits = 0;
    int earnedCredits = 0;
    double totalPoints = 0;
    bool allGradesSelected = true;

    grades.forEach((subject, grade) {
      final subjectCredits = credits[subject] ?? 0;
      totalCredits += subjectCredits;

      if (grade != null && gradeValues.containsKey(grade)) {
        totalPoints += gradeValues[grade]! * subjectCredits;
        if (grade != 'F') {
          earnedCredits += subjectCredits;
        }
      } else {
        allGradesSelected = false;
      }
    });

    final estimatedGpa = totalCredits > 0 ? totalPoints / totalCredits : 0;

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
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
                _buildSummaryItem('Completion',
                    '${grades.values.where((g) => g != null).length}/${grades.length}'),
                _buildSummaryItem(
                  'Estimated GPA',
                  allGradesSelected ? estimatedGpa.toStringAsFixed(2) : 'N/A',
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

class GPADisplay extends StatelessWidget {
  final double? gpa;
  final double? cgpa;

  const GPADisplay({required this.gpa, required this.cgpa});

  Color _getGpaColor(double? gpa) {
    if (gpa == null) return Colors.grey;
    if (gpa >= 9) return Colors.green;
    if (gpa >= 8) return Colors.lightGreen;
    if (gpa >= 7) return Colors.blue;
    if (gpa >= 6) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            'Results',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blue[800],
            ),
          ),
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildResultItem('Semester GPA', gpa?.toStringAsFixed(2) ?? 'N/A',
                  _getGpaColor(gpa)),
              _buildResultItem('CGPA', cgpa?.toStringAsFixed(2) ?? 'N/A',
                  _getGpaColor(cgpa)),
            ],
          ),
          SizedBox(height: 8),
          LinearProgressIndicator(
            value: (gpa ?? 0) / 10,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(
              _getGpaColor(gpa),
            ),
            minHeight: 8,
          ),
        ],
      ),
    );
  }

  Widget _buildResultItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        SizedBox(height: 4),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color, width: 1),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

class GpaCalculator extends StatefulWidget {
  @override
  _GpaCalculatorState createState() => _GpaCalculatorState();
}

class _GpaCalculatorState extends State<GpaCalculator>
    with TickerProviderStateMixin {
  final storage = FlutterSecureStorage();
  late TabController _tabController;
  Map<String, Map<String, int>> subjectsCredits = {};
  Map<String, Map<String, String?>> semesterGrades = {};
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
    final newLength = subjectsCredits.keys.length;
    if (_tabController.length != newLength) {
      _tabController.dispose();
      _tabController = TabController(length: newLength, vsync: this);
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
        setState(() {
          subjectsCredits = data.map((semesterKey, subjectsMap) {
            return MapEntry(
              semesterKey,
              (subjectsMap as Map<String, dynamic>).map<String, int>(
                (subject, credit) => MapEntry(subject, credit as int),
              ),
            );
          });

          semesterGrades = subjectsCredits.map((semester, subjects) => MapEntry(
              semester, subjects.map((subject, _) => MapEntry(subject, null))));

          _updateTabController();
        });
      } else {
        throw Exception('Failed to load subjects: ${response.statusCode}');
      }
    } catch (e) {
      print("Error fetching subjects: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch subjects: $e')),
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
              String subjectName = subject['name'];
              semesterGrades[semesterKey]![subjectName] = subject['grade'];
            }
          }
        });
      } else {
        throw Exception('Failed to fetch user data: ${response.statusCode}');
      }
    } catch (e) {
      print("Error fetching user data: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch user data: $e')),
      );
    }
  }

  Future<void> calculateGPA() async {
    setState(() {
      isLoading = true;
    });

    try {
      final token = await storage.read(key: 'auth_token');
      if (token == null) throw Exception('No authentication token found');

      final semester = subjectsCredits.keys.elementAt(_tabController.index);

      Map<String, String?> formattedSubjectGrades = {
        for (var entry in semesterGrades[semester]!.entries)
          entry.key: entry.value
      };

      final payload = json.encode({
        'semester': semester,
        'grades': formattedSubjectGrades,
      });

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
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('GPA calculated successfully!')),
        );
      } else {
        throw Exception('Failed to calculate GPA: ${response.statusCode}');
      }
    } catch (e) {
      print("An error occurred: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to calculate GPA: $e')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Widget _buildSubjectCard(String semester, String subject, int credits) {
    return SubjectCard(
      subjectName: subject,
      credits: credits,
      selectedGrade: semesterGrades[semester]![subject],
      onGradeChanged: (value) {
        setState(() => semesterGrades[semester]![subject] = value);
      },
      gradeValues: gradeValues,
    );
  }

  Widget _buildSemesterView(String semester) {
    final semesterData = subjectsCredits[semester]!;
    final grades = semesterGrades[semester]!;

    int totalCredits =
        semesterData.values.fold(0, (sum, credit) => sum + credit);
    int completedSubjects =
        grades.values.where((grade) => grade != null).length;
    int totalSubjects = grades.length;

    double? estimatedGpa;
    if (completedSubjects == totalSubjects) {
      double totalPoints = 0;
      int totalCreditsForGpa = 0;
      grades.forEach((subject, grade) {
        if (grade != null && gradeValues.containsKey(grade)) {
          final credit = semesterData[subject] ?? 0;
          totalPoints += gradeValues[grade]! * credit;
          totalCreditsForGpa += credit;
        }
      });
      estimatedGpa =
          totalCreditsForGpa > 0 ? totalPoints / totalCreditsForGpa : 0;
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          SemesterSummaryCard(
            grades: grades,
            credits: semesterData,
            gradeValues: gradeValues,
          ),
          SizedBox(height: 16),
          ...semesterData.entries.map((entry) => Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: _buildSubjectCard(semester, entry.key, entry.value),
              )),
          if (gpa != null &&
              semester == subjectsCredits.keys.elementAt(_tabController.index))
            GPADisplay(gpa: gpa, cgpa: cgpa),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('GPA Calculator'),
        bottom: subjectsCredits.isNotEmpty
            ? TabBar(
                controller: _tabController,
                isScrollable: true,
                tabs: subjectsCredits.keys.map((semester) {
                  return Tab(text: semester.replaceAll('_', ' ').toUpperCase());
                }).toList(),
              )
            : null,
      ),
      body: subjectsCredits.isNotEmpty
          ? TabBarView(
              controller: _tabController,
              children: subjectsCredits.keys.map(_buildSemesterView).toList(),
            )
          : Center(child: CircularProgressIndicator()),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final currentSemester =
              subjectsCredits.keys.elementAt(_tabController.index);
          if (semesterGrades[currentSemester]!
              .values
              .any((grade) => grade == null)) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Please select grades for all subjects')),
            );
            return;
          }
          calculateGPA();
        },
        child: isLoading
            ? CircularProgressIndicator(color: Colors.white)
            : Icon(Icons.calculate),
      ),
    );
  }
}
