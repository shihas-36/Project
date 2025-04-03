import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'gpa.dart';
import 'grade.dart';
import 'minor.dart';
import 'summary.dart';
import 'export.dart';

class StartPage extends StatefulWidget {
  const StartPage({Key? key}) : super(key: key);

  @override
  _StartPageState createState() => _StartPageState();
}

class _StartPageState extends State<StartPage> {
  final storage = FlutterSecureStorage();
  List<SemesterData> semesterData = [];
  double currentSgpa = 0.0;
  double currentCgpa = 0.0;
  double currentMinorGpa = 0.0;
  bool isLoading = true;
  String errorMessage = '';
  String currentSemester = '';

  @override
  void initState() {
    super.initState();
    _fetchAcademicData();
  }

  Future<void> _fetchAcademicData() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final token = await storage.read(key: 'auth_token');
      if (token == null) throw Exception('No authentication token found');

      final response = await http.get(
        Uri.parse('http://10.0.2.2:8000/get_user_data/'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final semesters = data['semesters'] as List;

        final processedData = semesters.map((semester) {
          return SemesterData(
            semester['semester'],
            semester['gpa']?.toDouble() ?? 0.0,
            semester['minor_gpa']?.toDouble() ?? 0.0,
          );
        }).toList();

        setState(() {
          semesterData = processedData;
          currentCgpa = data['cgpa']?.toDouble() ?? 0.0;
          if (semesters.isNotEmpty) {
            currentSemester = semesters.last['semester'];
            currentSgpa = semesters.last['gpa']?.toDouble() ?? 0.0;
            currentMinorGpa = semesters.last['minor_gpa']?.toDouble() ?? 0.0;
          }
        });
      } else {
        throw Exception('Failed to load data: ${response.statusCode}');
      }
    } catch (e) {
      setState(() => errorMessage = 'Error: ${e.toString()}');
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Academic Performance',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            )),
        centerTitle: true,
        backgroundColor: Colors.blue[800],
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(errorMessage,
                          style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _fetchAcademicData,
                        child: const Text('Retry'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[800],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // GPA Chart Section
                      _buildGpaChart(),

                      const SizedBox(height: 16),

                      // Current Semester Info
                      _buildCurrentSemesterCard(),

                      const SizedBox(height: 16),

                      // GPA Summary Cards
                      _buildGpaSummaryCards(),

                      const SizedBox(height: 24),

                      // Action Buttons
                      _buildActionButtons(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildGpaChart() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('GPA Progress',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                )),
            const SizedBox(height: 16),
            SizedBox(
              height: 240,
              child: semesterData.isEmpty
                  ? const Center(child: Text('No data available'))
                  : SfCartesianChart(
                      primaryXAxis: CategoryAxis(
                        title: AxisTitle(text: 'Semester'),
                        labelRotation: -45,
                        majorGridLines: const MajorGridLines(width: 0),
                      ),
                      primaryYAxis: NumericAxis(
                        minimum: 0,
                        maximum: 10,
                        interval: 1,
                        title: AxisTitle(text: 'GPA'),
                        majorGridLines: const MajorGridLines(width: 0),
                      ),
                      plotAreaBorderWidth: 0,
                      tooltipBehavior: TooltipBehavior(enable: true),
                      series: <ChartSeries>[
                        LineSeries<SemesterData, String>(
                          dataSource: semesterData,
                          xValueMapper: (data, _) => data.semesterName,
                          yValueMapper: (data, _) => data.gpa,
                          name: 'GPA',
                          color: Colors.blue[800],
                          width: 3,
                          markerSettings: const MarkerSettings(
                            isVisible: true,
                            shape: DataMarkerType.circle,
                            borderWidth: 2,
                            borderColor: Colors.blue,
                            color: Colors.white,
                          ),
                          dataLabelSettings: const DataLabelSettings(
                            isVisible: true,
                            textStyle: TextStyle(fontSize: 10),
                          ),
                        ),
                        LineSeries<SemesterData, String>(
                          dataSource: semesterData,
                          xValueMapper: (data, _) => data.semesterName,
                          yValueMapper: (data, _) => data.minorGpa,
                          name: 'Minor GPA',
                          color: Colors.green[600],
                          width: 3,
                          markerSettings: const MarkerSettings(
                            isVisible: true,
                            shape: DataMarkerType.diamond,
                            borderWidth: 2,
                            borderColor: Colors.green,
                            color: Colors.white,
                          ),
                          dataLabelSettings: const DataLabelSettings(
                            isVisible: true,
                            textStyle: TextStyle(fontSize: 10),
                          ),
                        ),
                      ],
                      legend: Legend(
                        isVisible: true,
                        position: LegendPosition.bottom,
                        textStyle: const TextStyle(fontSize: 12),
                      ),
                    ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => GpaCalculator()),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[800],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('View GPA Details',
                    style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentSemesterCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Current Semester',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                )),
            const SizedBox(height: 12),
            Text(currentSemester, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text('SGPA: ${currentSgpa.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.blue[800],
                  fontWeight: FontWeight.bold,
                )),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => GradeCalculatorPage()),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[600],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child:
                    const Text('View Grades', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGpaSummaryCards() {
    return Row(
      children: [
        Expanded(
          child: _buildGpaCard('CGPA', currentCgpa, Colors.blue[800]!),
        ),
        const SizedBox(width: 12),
        Expanded(
          child:
              _buildGpaCard('Minor GPA', currentMinorGpa, Colors.green[600]!),
        ),
      ],
    );
  }

  Widget _buildGpaCard(String title, double value, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(title,
                style: TextStyle(
                  fontSize: 16,
                  color: color,
                  fontWeight: FontWeight.bold,
                )),
            const SizedBox(height: 8),
            Text(value.toStringAsFixed(2),
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: color,
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildActionButton(Icons.calculate, 'Minor', Colors.orange[800]!),
        _buildActionButton(Icons.summarize, 'Summary', Colors.purple[600]!),
        _buildActionButton(Icons.download, 'Export', Colors.blue[800]!),
      ],
    );
  }

  Widget _buildActionButton(IconData icon, String label, Color color) {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: IconButton(
            icon: Icon(icon, size: 32, color: color),
            onPressed: () {
              if (label == 'Minor') {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => MinorCalculatorPage()));
              } else if (label == 'Summary') {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => SummaryPage()));
              } else if (label == 'Export') {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => ExportPage()));
              }
            },
          ),
        ),
        const SizedBox(height: 8),
        Text(label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
            )),
      ],
    );
  }
}

class SemesterData {
  final String semesterName;
  final double gpa;
  final double minorGpa;

  SemesterData(this.semesterName, this.gpa, this.minorGpa);
}
