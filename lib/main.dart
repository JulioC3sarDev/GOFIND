import 'package:flutter/material.dart';
import 'features/onboarding/welcome_screen.dart';

void main() {
  runApp(const GoFindApp());
}

class GoFindApp extends StatelessWidget {
  const GoFindApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GoFind',
      debugShowCheckedModeBanner: false,
      home: const WelcomeScreen(),
    );
  }
}