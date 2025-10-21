import 'package:flutter/material.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // This is a wrapper screen for navigation
    // The actual content will be handled by GoRouter
    return const Scaffold(
      body: Center(
        child: Text('Auth Screen'),
      ),
    );
  }
}