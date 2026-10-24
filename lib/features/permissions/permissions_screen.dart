import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'info_screens.dart';
import '../home/home_screen.dart';

class PermissionsScreen extends StatelessWidget {
  const PermissionsScreen({super.key});

  static const _blue = Color(0xFF0066FF);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
          
              const SizedBox(height: 9),

              // Ilustração ocupa a largura toda, sem margens
              Image.asset(
                'assets/images/friendsParty.png',
                width: double.infinity,
                fit: BoxFit.fitWidth,
              ),

              const SizedBox(height: 8),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  children: [
                    Text(
                      'Para encontrar seus amigos\nprecisamos de algumas\npermissões',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.comfortaa(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: _blue,
                        height: 1.35,
                      ),
                    ),

                    const SizedBox(height: 22),

                    const _PermissaoItem(
                      titulo: 'Localização',
                      descricao:
                          'Para calcular a direção e a distância até os seus amigos.',
                    ),
                    const SizedBox(height: 14),
                    const _PermissaoItem(
                      titulo: 'Bluetooth e dispositivos próximos',
                      descricao:
                          'Para encontrar e conectar com os celulares do seu grupo, mesmo sem internet.',
                    ),
                    const SizedBox(height: 14),
                    const _PermissaoItem(
                      titulo: 'Notificações',
                      descricao:
                          'Para avisar sobre alertas do grupo, como "Estou perdido", e manter a conexão ativa.',
                    ),

                    const SizedBox(height: 30),

                    SizedBox(
                      width: double.infinity,
                      height: 51,
                      child: FilledButton(
                        onPressed: () {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (_) => const HomeScreen()),
                            (route) => false,
                          );
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: _blue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: Text(
                          'Permitir e Continuar',
                          style: GoogleFonts.comfortaa(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 4),

                                        _LinkAzul(
                      texto: 'Saber mais sobre nossa privacidade',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const PrivacyScreen()),
                      ),
                    ),
                    _LinkAzul(
                      texto: 'Por que isso é necessário?',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const WhyPermissionsScreen()),
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Bloco "título + descrição" que se repete 3 vezes
class _PermissaoItem extends StatelessWidget {
  final String titulo;
  final String descricao;

  const _PermissaoItem({required this.titulo, required this.descricao});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: GoogleFonts.comfortaa(
              fontSize: 22,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF111111),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            descricao,
            style: GoogleFonts.comfortaa(
              fontSize: 16,
              fontWeight: FontWeight.w300,
              color: const Color(0xFF222222),
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

// Link pequeno azul, centralizado
class _LinkAzul extends StatelessWidget {
  final String texto;
  final VoidCallback onTap;

  const _LinkAzul({required this.texto, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        minimumSize: Size.zero,
        padding: const EdgeInsets.symmetric(vertical: 4),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        texto,
        style: GoogleFonts.comfortaa(
          fontSize: 15,
          fontWeight: FontWeight.w300,
          color: const Color(0xFF0066FF),
        ),
      ),
    );
  }
}