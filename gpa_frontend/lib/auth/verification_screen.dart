import 'package:flutter/material.dart';

class VerificationScreen extends StatefulWidget {
  final String email;
  final Future<void> Function() onResendPressed; // Updated type

  const VerificationScreen({
    required this.email,
    required this.onResendPressed,
    Key? key,
  }) : super(key: key);

  @override
  _VerificationScreenState createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  bool _isResending = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Verification'),
      ),
      body: Center(
        child: TextButton(
          onPressed: _isResending
              ? null
              : () async {
                  setState(() => _isResending = true);
                  await widget.onResendPressed();
                  if (!mounted) return; // Ensure the widget is still mounted
                  setState(() => _isResending = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Verification email resent!')),
                  );
                },
          child: _isResending
              ? CircularProgressIndicator(color: Colors.white)
              : Text(
                  'Resend Verification Email',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
        ),
      ),
    );
  }
}
