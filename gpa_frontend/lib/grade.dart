import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class GradeCalculatorPage extends StatefulWidget {
  @override
  _GradeCalculatorPageState createState() => _GradeCalculatorPageState();
}

class _GradeCalculatorPageState extends State<GradeCalculatorPage>
    with TickerProviderStateMixin {
  final storage = FlutterSecureStorage();
  late TabController _tabController;
  Map<String, Map<String, Map<String, int>>> subjectsStructure = {};
  Map<String, Map<String, String?>> selectedSubjects = {};
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 1, vsync: this);
    _initializeData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    try {
      final savedSemester = await storage.read(key: 'current_semester');
      await fetchSubjects();
      if (savedSemester != null &&
          subjectsStructure.containsKey(savedSemester)) {
        _tabController = TabController(
          length: subjectsStructure.length,
          initialIndex: subjectsStructure.keys.toList().indexOf(savedSemester),
          vsync: this,
        );
      } else {
        _updateTabController();
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Initialization error: $e';
        isLoading = false;
      });
    }
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

        final parsedData = data.map<String, Map<String, Map<String, int>>>(
            (semesterKey, semesterValue) {
          final slots = (semesterValue as Map<String, dynamic>)
              .map<String, Map<String, int>>((slotKey, slotValue) {
            return MapEntry(
                slotKey,
                (slotValue as Map<String, dynamic>).map<String, int>(
                  (subject, credit) =>
                      MapEntry(subject, (credit as num).toInt()),
                ));
          });
          return MapEntry(semesterKey, slots);
        });

        setState(() {
          subjectsStructure = parsedData;
          selectedSubjects = {};

          // Initialize with first subject in each slot
          parsedData.forEach((semester, slots) {
            selectedSubjects[semester] = {};
            slots.forEach((slot, courses) {
              if (courses.isNotEmpty) {
                selectedSubjects[semester]![slot] = courses.keys.first;
              }
            });
          });
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

  void _showMarksDialog(String subject, String semester) {
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

                        final response = await http.post(
                          Uri.parse('http://10.0.2.2:8000/calculate_grade/'),
                          headers: {
                            'Content-Type': 'application/json',
                            'Authorization': 'Bearer $token',
                          },
                          body: json.encode({'marks': total}),
                        );

                        if (response.statusCode == 200) {
                          final result = json.decode(response.body);
                          Navigator.of(context).pop();
                          _showGradeResultDialog(subject, result['grade']);
                        } else {
                          throw Exception(
                              'Grade calculation failed: ${response.statusCode}');
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

  void _showGradeResultDialog(String subject, String grade) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Grade Result'),
          content: Text('$subject: $grade'),
          actions: [
            TextButton(
              child: Text('OK'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
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

  Widget _buildSemesterView(String semester) {
    final slots = subjectsStructure[semester] ?? {};

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
          SizedBox(height: 20),
          ...slots.entries.map((slotEntry) {
            final slotName = slotEntry.key;
            final courses = slotEntry.value;
            final currentSubject = selectedSubjects[semester]?[slotName];

            return Card(
              margin: EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                title: Text(currentSubject ?? 'No subject selected'),
                subtitle: Text('Credits: ${courses[currentSubject] ?? 'N/A'}'),
                trailing: currentSubject != null
                    ? IconButton(
                        icon: Icon(Icons.edit),
                        onPressed: () =>
                            _showMarksDialog(currentSubject, semester),
                      )
                    : null,
              ),
            );
          }),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Grade Calculator'),
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
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(child: Text(errorMessage!))
              : subjectsStructure.isEmpty
                  ? Center(child: Text('No subjects found'))
                  : TabBarView(
                      controller: _tabController,
                      children: subjectsStructure.keys.map((semester) {
                        return _buildSemesterView(semester);
                      }).toList(),
                    ),
    );
  }
}
