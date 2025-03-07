import 'package:flutter/material.dart';
import 'dart:convert';
import 'login_page.dart'; // Import the login page
import '../services/api_service.dart'; // Import the API service
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../gpa.dart'; // Import the GPA calculation page

class SignUpPage extends StatefulWidget {
  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _ktuidController = TextEditingController();
  final storage = FlutterSecureStorage();

  String? _selectedSemester;
  bool _isMinorSelected = false;
  bool _isLetSelected = false;
  bool _isHonorSelected = false;
  bool _showOptions = false;
  bool _showHonor = false;
  bool _isLoading = false;
  final Map<String, dynamic> _grades = {};

  void _checkSemester(String? value) {
    final semester = int.tryParse(value ?? '') ?? 0;
    setState(() {
      _showOptions = semester > 2;
      _showHonor = semester > 3;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create Account Now!'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Sign Up',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20),
                _buildTextField(_usernameController, 'Username'),
                _buildTextField(_emailController, 'Email', isEmail: true),
                _buildTextField(_passwordController, 'Password',
                    isPassword: true),
                _buildTextField(_confirmPasswordController, 'Confirm Password',
                    isPassword: true),
                _buildTextField(_ktuidController, 'KTUID'),
                _buildSemesterDropdown(),
                if (_showOptions) ...[
                  SizedBox(height: 20),
                  Text('Select Option:', style: TextStyle(fontSize: 16)),
                  _buildCheckboxOption('Minor', _isMinorSelected, (value) {
                    setState(() {
                      _isMinorSelected = value ?? false;
                    });
                  }),
                  _buildCheckboxOption('Let', _isLetSelected, (value) {
                    setState(() {
                      _isLetSelected = value ?? false;
                    });
                  }),
                  if (_showHonor)
                    _buildCheckboxOption('Honor', _isHonorSelected, (value) {
                      setState(() {
                        _isHonorSelected = value ?? false;
                      });
                    }),
                ],
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => LoginPage()),
                    );
                  },
                  child: Text('Already have an account? Login'),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _isLoading ? null : _submitForm,
                  child: _isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text('Sign Up'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {bool isEmail = false, bool isPassword = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword,
        keyboardType: isEmail ? TextInputType.emailAddress : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter $label';
          }
          if (isEmail && !value.contains('@')) {
            return 'Please enter a valid email';
          }
          if (isPassword && value.length < 6) {
            return 'Password must be at least 6 characters';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildSemesterDropdown() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<String>(
        value: _selectedSemester,
        decoration: InputDecoration(
          labelText: 'Semester',
          border: OutlineInputBorder(),
        ),
        items: List.generate(8, (index) => (index + 1).toString())
            .map((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            _selectedSemester = value;
            _checkSemester(value);
          });
        },
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please select a semester';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildCheckboxOption(
      String title, bool value, ValueChanged<bool?> onChanged) {
    return CheckboxListTile(
      title: Text(title),
      value: value,
      onChanged: onChanged,
    );
  }

  Widget _buildGradeField(String subject) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        decoration: InputDecoration(
          labelText: '$subject Grade',
          border: OutlineInputBorder(),
        ),
        onChanged: (value) {
          _grades[subject] = value; // Store the grade
        },
      ),
    );
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      if (_passwordController.text != _confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Passwords do not match')),
        );
        return;
      }

      setState(() => _isLoading = true);

      // Prepare user data
      final userData = {
        'username': _usernameController.text,
        'email': _emailController.text,
        'password': _passwordController.text,
        'KTUID': _ktuidController.text,
        'semester': int.parse(_selectedSemester ?? '1'),
        'is_minor': _isMinorSelected,
        'is_let': _isLetSelected,
        'is_honors': _isHonorSelected,
      };

      print('Sending user data: $userData'); // Debug log

      try {
        final signUpResponse = await ApiService.signUp(userData);

        print(
            'Sign-up response status: ${signUpResponse.statusCode}'); // Debug log
        print('Sign-up response body: ${signUpResponse.body}'); // Debug log

        if (signUpResponse.statusCode == 201) {
          // Sign-up successful, proceed to fill grades
          final loginResponse = await http.post(
            Uri.parse('http://10.0.2.2:8000/token/'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'email': _emailController.text,
              'password': _passwordController.text,
            }),
          );
          print(
              'Login response status: ${loginResponse.statusCode}'); // Debug log
          print('Login response body: ${loginResponse.body}'); // Debug log

          if (loginResponse.statusCode == 200) {
            final loginData = json.decode(loginResponse.body);
            final token = loginData['access'];
            await storage.write(key: 'auth_token', value: token);
            await storage.write(
                key: 'refresh_token', value: loginData['refresh']);

            // Set the initial semester based on the is_let option
            final initialSemester =
                _isLetSelected ? 'semester_3' : 'semester_1';
            await storage.write(
                key: 'current_semester', value: initialSemester);

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Account created successfully!')),
            );
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) =>
                      GpaCalculator()), // Navigate to GPA calculation page
            );
          } else {
            final error =
                jsonDecode(loginResponse.body)['error'] ?? 'Unknown error';
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: $error')),
            );
          }
        } else {
          final error =
              jsonDecode(signUpResponse.body)['error'] ?? 'Unknown error';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $error')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Network error: $e')),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }
}
