import 'package:flutter/material.dart';
import 'package:gpa_frontend/gpa.dart';
import 'package:gpa_frontend/grade.dart';
import 'package:gpa_frontend/minor_calculator.dart'; // Import the new Minor Calculator page

class StartPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Start Page'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => GpaCalculator()),
                );
              },
              child: Text('Calculate GPA'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => GradeCalculatorPage()),
                );
              },
              child: Text('Calculate Marks'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          MinorCalculatorPage()), // Navigate to Minor Calculator page
                );
              },
              child: Text('Calculate Minor'),
            ),
          ],
        ),
      ),
    );
  }
}
