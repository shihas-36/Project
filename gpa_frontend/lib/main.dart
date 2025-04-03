import 'package:flutter/material.dart';
import 'auth/signup_page.dart';
import 'auth/login_page.dart';
import 'gpa.dart';
import 'minor.dart';
import 'grade.dart';
import 'start.dart'; // Example additional page
import 'export.dart'; // Example additional page

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GPA Frontend',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: LoginPage(), // Set the home property to LoginPage
      routes: {
        '/login': (context) => LoginPage(),
        '/signup': (context) => SignUpPage(),
        '/gpa': (context) => GpaCalculator(),
        '/minor_calculator': (context) => MinorCalculatorPage(),
        '/grade': (context) => GradeCalculatorPage(),
        '/home': (context) => StartPage(), // Example additional route
        '/profile': (context) => ExportPage(), // Example additional route
      },
    );
  }
}
