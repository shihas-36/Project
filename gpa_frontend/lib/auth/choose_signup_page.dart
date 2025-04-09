import 'package:flutter/material.dart';
import 'signup_page.dart';
import 'faculty_signup_page.dart';
import '../theme/colors.dart'; // Import AppColors

class ChooseSignupPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Signup Type'),
        backgroundColor: AppColors.blue, // Use AppColors for AppBar background
      ),
      backgroundColor: AppColors.blue, // Use AppColors for background
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SignUpPage()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    AppColors.lightYellow, // Use AppColors for button
                padding:
                    const EdgeInsets.symmetric(vertical: 15, horizontal: 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text(
                'Student Signup',
                style: TextStyle(
                  color: AppColors.blue, // Use AppColors for button text
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => FacultySignUpPage()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    AppColors.lightYellow, // Use AppColors for button
                padding:
                    const EdgeInsets.symmetric(vertical: 15, horizontal: 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text(
                'Faculty Signup',
                style: TextStyle(
                  color: AppColors.blue, // Use AppColors for button text
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
