import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../auth/login_screen.dart';
import '../auth/signup_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  static const _blue = Color(0xFF0066FF);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 3),

            // Logo
            Image.asset('assets/images/logo.png', width: 257),

            const SizedBox(height: 24),

            // Ilustração (largura total da tela)
            Image.asset(
              'assets/images/welcome_illustration.png',
              width: double.infinity,
              fit: BoxFit.fitWidth,
            ),

            const SizedBox(height: 16),

            // Textos
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 37),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Olá, Que bom ter\nvocê por aqui.',
                      style: GoogleFonts.comfortaa(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: _blue,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Encontre seus amigos facilemente\nmesmo sem internet',
                      style: GoogleFonts.comfortaa(
                        fontSize: 20,
                        fontWeight: FontWeight.w300,
                        color: _blue,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Botões
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 29),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 51,
                    child: FilledButton(
                      onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const LoginScreen()),
                          );
                        },
                      style: FilledButton.styleFrom(
                        backgroundColor: _blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Text(
                        'Entrar',
                        style: GoogleFonts.comfortaa(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 11),
                  SizedBox(
                    width: double.infinity,
                    height: 51,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const SignupScreen()),
                        );
                      },
                      icon: const Icon(Icons.person_add_alt_1, color: _blue),
                      label: Text(
                        'Criar Conta',
                        style: GoogleFonts.comfortaa(
                          fontSize: 16,
                          color: _blue,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: _blue),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(flex: 4),
          ],
        ),
      ),
    );
  }
}