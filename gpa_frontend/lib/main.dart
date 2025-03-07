import 'package:flutter/material.dart';
import 'auth/signup_page.dart';
import 'auth/login_page.dart';
import 'gpa.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Django Auth',
      initialRoute: '/login',
      routes: {
        '/login': (context) => LoginPage(),
        '/signup': (context) => SignUpPage(),
        '/gpa': (context) => GpaCalculator()
        // Add home page route here
      },
    );
  }
}
