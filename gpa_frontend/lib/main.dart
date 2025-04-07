import 'package:flutter/material.dart';
import 'auth/signup_page.dart';
import 'auth/login_page.dart';
import 'gpa.dart';
import 'minor.dart';
import 'grade.dart';
import 'start.dart'; // Example additional page
import 'export.dart'; // Example additional page
import 'theme/colors.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter App',
      theme: ThemeData(
        primaryColor: AppColors.blue,
        scaffoldBackgroundColor: AppColors.lightBlue,
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.blue,
          foregroundColor: AppColors.lightYellow,
        ),
        buttonTheme: ButtonThemeData(
          buttonColor: AppColors.yellow,
          textTheme: ButtonTextTheme.primary,
        ),
        textTheme: TextTheme(
          bodyLarge: TextStyle(color: AppColors.blue), // Updated
          bodyMedium: TextStyle(color: AppColors.blue), // Updated
          displayLarge: TextStyle(color: AppColors.yellow), // Updated
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: AppColors.yellow,
          foregroundColor: AppColors.lightBlue,
        ),
      ),
      home: LoginPage(),
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

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home Page'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {},
          child: Text('Click Me'),
        ),
      ),
    );
  }
}
