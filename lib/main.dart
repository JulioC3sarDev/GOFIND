import 'package:flutter/material.dart';
import 'features/onboarding/splash_screen.dart';

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
      // Com perfil criado, abre direto na Home; sem perfil, na boas-vindas
      home: const SplashScreen(),
    );
  }
}