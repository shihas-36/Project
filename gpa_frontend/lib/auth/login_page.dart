import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:gpa_frontend/gpa.dart';
import 'signup_page.dart'; // Import your GPA calculator page
import 'package:gpa_frontend/start.dart';
import 'package:gpa_frontend/admin.dart'; // Import your ChooseSignupPage
import 'choose_signup_page.dart';
import 'package:gpa_frontend/faculty.dart'; // Import your Faculty page

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final storage = FlutterSecureStorage();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:8000/token/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': _emailController.text,
          'password': _passwordController.text,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final accessToken = responseData['access'];

        // Store tokens
        await storage.write(key: 'auth_token', value: accessToken);
        await storage.write(
            key: 'refresh_token', value: responseData['refresh']);

        // First check superuser status via API
        final isSuperuserResponse = await http.get(
          Uri.parse('http://10.0.2.2:8000/api/is_admin/'),
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Content-Type': 'application/json',
          },
        );

        if (isSuperuserResponse.statusCode == 200) {
          final superuserData = json.decode(isSuperuserResponse.body);
          final isSuperuser = superuserData['is_superuser'] ?? false;

          if (isSuperuser) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => AdminDashboardPage()),
            );
            return;
          }

          // If not superuser, check faculty status
          final isFacultyResponse = await http.get(
            Uri.parse('http://10.0.2.2:8000/api/is_faculty/'),
            headers: {
              'Authorization': 'Bearer $accessToken',
              'Content-Type': 'application/json',
            },
          );

          if (isFacultyResponse.statusCode == 200) {
            final isFacultyData = json.decode(isFacultyResponse.body);
            final isFaculty = isFacultyData['is_faculty'] ?? false;

            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => isFaculty ? FacultyPage() : StartPage(),
              ),
            );
          } else {
            throw Exception(
                'Failed to fetch faculty status: ${isFacultyResponse.body}');
          }
        } else {
          throw Exception(
              'Failed to fetch superuser status: ${isSuperuserResponse.body}');
        }
      } else {
        throw Exception('Failed to login: ${response.body}');
      }
    } catch (e) {
      print("Login error: $e");
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Error'),
            content: Text('Login failed: $e'),
            actions: <Widget>[
              TextButton(
                child: Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacementNamed(context, '/');
          },
        ),
        backgroundColor: const Color.fromARGB(
            255, 20, 53, 89), // Set AppBar background color
      ),
      backgroundColor:
          const Color.fromARGB(255, 20, 53, 89), // Set background color
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo
                Center(
                  child: Image.asset(
                    'assets/Edula.png', // Path to your logo
                    width: 150, // Adjust the width as needed
                    height: 150, // Adjust the height as needed
                  ),
                ),
                const SizedBox(height: 40),

                // Login Title
                const Text(
                  'Login',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 40),

                // Email Field
                _buildTextField('Email', _emailController),

                // Password Field
                _buildTextField('Password', _passwordController,
                    isPassword: true),

                const SizedBox(height: 30),

                // Login Button
                Center(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF8F0E3),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 50, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: _isLoading
                        ? CircularProgressIndicator()
                        : const Text(
                            'Login',
                            style: TextStyle(
                              color: Color(
                                  0xFF6750A4), // Purple color for the login text
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 20),

                // Don't have an account text
                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => ChooseSignupPage()),
                      );
                    },
                    child: RichText(
                      text: const TextSpan(
                        text: "Don't have an account? ",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                        children: [
                          TextSpan(
                            text: 'Sign Up',
                            style: TextStyle(
                              color: Color(
                                  0xFF6750A4), // Purple color for Sign Up text
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper method to build text fields
  Widget _buildTextField(
    String placeholder,
    TextEditingController controller, {
    bool isPassword = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            placeholder,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 5),
          TextField(
            controller: controller,
            obscureText: isPassword,
            style: const TextStyle(color: Colors.black),
            decoration: InputDecoration(
              filled: true,
              fillColor: Color(0xFFF8F0E3),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.transparent, width: 1.0),
                borderRadius: BorderRadius.circular(30.0),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.transparent, width: 2.0),
                borderRadius: BorderRadius.circular(30.0),
              ),
              contentPadding:
                  EdgeInsets.symmetric(vertical: 10, horizontal: 20),
            ),
          ),
        ],
      ),
    );
  }
}
