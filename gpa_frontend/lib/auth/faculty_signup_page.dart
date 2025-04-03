import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:gpa_frontend/faculty.dart';

class FacultySignUpPage extends StatefulWidget {
  @override
  _FacultySignUpPageState createState() => _FacultySignUpPageState();
}

class _FacultySignUpPageState extends State<FacultySignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _collegeCodeController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final storage = FlutterSecureStorage();
  bool _isLoading = false;

  Future<void> _signupFaculty() async {
    if (!_formKey.currentState!.validate()) return;
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userData = {
        'email': _emailController.text,
        'password': _passwordController.text,
        'college_code':
            _collegeCodeController.text, // Changed key to match backend
        'username': _usernameController.text,
      };

      print("Request payload: $userData"); // Log the request payload

      final signUpResponse = await http.post(
        Uri.parse('http://10.0.2.2:8000/api/faculty/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(userData),
      );

      print("Signup response: ${signUpResponse.body}"); // Log signup response

      if (signUpResponse.statusCode != 201) {
        throw jsonDecode(signUpResponse.body)['error'] ?? 'Signup failed';
      }

      final loginResponse = await http.post(
        Uri.parse('http://10.0.2.2:8000/token/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _emailController.text,
          'password': _passwordController.text,
        }),
      );

      print("Login response: ${loginResponse.body}"); // Log login response

      if (loginResponse.statusCode != 200) {
        throw jsonDecode(loginResponse.body)['error'] ?? 'Login failed';
      }

      final loginData = jsonDecode(loginResponse.body);
      await storage.write(key: 'auth_token', value: loginData['access']);
      await storage.write(key: 'refresh_token', value: loginData['refresh']);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Faculty account created successfully!')),
      );

      // Navigate to FacultyPage
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => FacultyPage()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Faculty Sign Up'),
        backgroundColor: const Color.fromARGB(255, 20, 53, 89),
      ),
      backgroundColor: const Color.fromARGB(255, 20, 53, 89),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),
                  const Center(
                    child: Text(
                      'Faculty Sign Up',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  _buildTextField(_emailController, 'Email', isEmail: true),
                  _buildTextField(_passwordController, 'Password',
                      isPassword: true),
                  _buildTextField(
                      _confirmPasswordController, 'Confirm Password',
                      isPassword: true),
                  _buildTextField(_collegeCodeController, 'College Code'),
                  _buildTextField(_usernameController, 'Username'),
                  const SizedBox(height: 30),
                  Center(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _signupFaculty,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF8F0E3),
                        padding: const EdgeInsets.symmetric(
                            vertical: 15, horizontal: 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.black)
                          : const Text(
                              'Sign Up',
                              style:
                                  TextStyle(color: Colors.black, fontSize: 18),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {bool isEmail = false, bool isPassword = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword,
        decoration: InputDecoration(
          filled: true,
          fillColor: const Color(0xFFF8F0E3),
          hintText: label,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) return 'Please enter $label';
          if (isEmail && !value.contains('@')) return 'Invalid email';
          if (isPassword && value.length < 6) return 'Minimum 6 characters';
          return null;
        },
      ),
    );
  }
}
