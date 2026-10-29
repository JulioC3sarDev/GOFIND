import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'create_profile_screen.dart';

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
                      'Encontre seus amigos facilmente\nmesmo sem internet',
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

            // Botão único e aviso
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 29),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 51,
                    child: FilledButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CriarPerfilScreen(),
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: _blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Text(
                        'Começar',
                        style: GoogleFonts.comfortaa(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.lock_outline,
                          size: 15, color: Color(0xFF9E9E9E)),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Sem cadastro, sem e-mail e sem senha',
                          style: GoogleFonts.comfortaa(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w300,
                            color: const Color(0xFF9E9E9E),
                          ),
                        ),
                      ),
                    ],
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