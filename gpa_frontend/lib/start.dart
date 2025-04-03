import 'package:flutter/material.dart';
import 'package:gpa_frontend/gpa.dart';
import 'package:gpa_frontend/grade.dart';
import 'package:gpa_frontend/export.dart';
import 'package:gpa_frontend/minor.dart';
import 'package:gpa_frontend/summary.dart';
import 'package:syncfusion_flutter_charts/charts.dart'; // For GPA chart

class StartPage extends StatelessWidget {
  StartPage({Key? key}) : super(key: key); // Removed 'const'

  // Sample GPA data for the chart
  final Map<String, double> semesterGpas = {
    'Sem 1': 3.2,
    'Sem 2': 3.5,
    'Sem 3': 3.7,
    'Sem 4': 3.8,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Academic Dashboard'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade800, Colors.indigo.shade900],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade50, Colors.white],
          ),
        ),
        child: Column(
          children: [
            // Layer 1: GPA Graph
            Expanded(
              flex: 3,
              child: InkWell(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => GpaCalculator()),
                ),
                child: Card(
                  margin: const EdgeInsets.all(16),
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Text(
                          'Your GPA Progress',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueGrey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: SfCartesianChart(
                            primaryXAxis: CategoryAxis(),
                            series: <ChartSeries>[
                              LineSeries<MapEntry<String, double>, String>(
                                dataSource: semesterGpas.entries.toList(),
                                xValueMapper: (entry, _) => entry.key,
                                yValueMapper: (entry, _) => entry.value,
                                markerSettings:
                                    const MarkerSettings(isVisible: true),
                                color: Colors.blue,
                              )
                            ],
                          ),
                        ),
                        const Text(
                          'Tap to view details',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Layer 2: Current Semester & Target CGPA
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  // Current Semester
                  Expanded(
                    child: InkWell(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => GradeCalculatorPage()),
                      ),
                      child: Card(
                        margin: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                        elevation: 6,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.school, size: 40, color: Colors.blue),
                              SizedBox(height: 8),
                              Text(
                                'Current Semester',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text('3.75 GPA', style: TextStyle(fontSize: 20)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Target CGPA
                  Expanded(
                    child: InkWell(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => GradeCalculatorPage()),
                      ),
                      child: Card(
                        margin: const EdgeInsets.fromLTRB(8, 8, 16, 8),
                        elevation: 6,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.flag, size: 40, color: Colors.green),
                              SizedBox(height: 8),
                              Text(
                                'Target CGPA',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text('3.90', style: TextStyle(fontSize: 20)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Layer 3: Fixed Bottom Buttons
            Container(
              height: 120,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Left Button - Export
                  Expanded(
                    child: InkWell(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ExportPage()),
                      ),
                      child: Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        color: Colors.blue.shade100,
                        child: const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.download, size: 30),
                              Text('Export'),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Center Button - Minor Calculator
                  const SizedBox(width: 8),
                  Expanded(
                    child: InkWell(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => MinorCalculatorPage()),
                      ),
                      child: Card(
                        elevation: 6,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        color: Colors.blue.shade200,
                        child: const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.calculate, size: 36),
                              Text('Minor Calc'),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Right Button - Summary
                  const SizedBox(width: 8),
                  Expanded(
                    child: InkWell(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => SummaryPage()),
                      ),
                      child: Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        color: Colors.blue.shade100,
                        child: const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.summarize, size: 30),
                              Text('Summary'),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
