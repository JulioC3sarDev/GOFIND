import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/onboarding/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const GoFindApp());
}

class GoFindApp extends StatelessWidget {
  const GoFindApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GoFind',
      debugShowCheckedModeBanner: false,

      // Tema global do aplicativo
      theme: AppTheme.light,

      // Primeira tela do aplicativo
      home: const SplashScreen(),
    );
  }
}