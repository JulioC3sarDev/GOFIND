import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../permissions/permissions_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const _blue = Color(0xFF0066FF);
  static const _border = Color(0xFFD9D9D9);
  static const _hint = Color(0xFF9E9E9E);
  static const _iconColor = Color(0xFF6B6B6B);

  bool _senhaOculta = true;

  // Monta um campo de texto no estilo do Figma
  Widget _campo({
    required String hint,
    required IconData icone,
    bool senha = false,
  }) {
    return SizedBox(
      height: 51,
      child: TextField(
        obscureText: senha && _senhaOculta,
        keyboardType:
            senha ? TextInputType.text : TextInputType.emailAddress,
        style: GoogleFonts.comfortaa(fontSize: 16),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.comfortaa(
            fontSize: 16,
            fontWeight: FontWeight.w300,
            color: _hint,
          ),
          prefixIcon: Icon(icone, color: _iconColor),
          suffixIcon: senha
              ? IconButton(
                  icon: Icon(
                    _senhaOculta
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: _iconColor,
                  ),
                  onPressed: () {
                    setState(() {
                      _senhaOculta = !_senhaOculta;
                    });
                  },
                )
              : null,
          contentPadding: EdgeInsets.zero,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(color: _border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(color: _blue),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 29),
          child: Column(
            children: [
              const SizedBox(height: 190),

              // Logo
              Image.asset('assets/images/logo.png', width: 257),

              const SizedBox(height: 82),

              // Campos
              _campo(hint: 'E-mail', icone: Icons.mail_outline),
              const SizedBox(height: 20),
              _campo(hint: 'Senha', icone: Icons.lock_outline, senha: true),

              const SizedBox(height: 34),

              // Botão Entrar
              SizedBox(
                width: double.infinity,
                height: 51,
                child: FilledButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PermissionsScreen()),
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

              const SizedBox(height: 36),

              // Divisor "ou"
              Row(
                children: [
                  const Expanded(child: Divider(color: _border, thickness: 1)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Text(
                      'ou',
                      style: GoogleFonts.comfortaa(
                        fontSize: 16,
                        fontWeight: FontWeight.w300,
                        color: _hint,
                      ),
                    ),
                  ),
                  const Expanded(child: Divider(color: _border, thickness: 1)),
                ],
              ),

              const SizedBox(height: 8),

              // Esqueci minha senha
              TextButton(
                onPressed: () => debugPrint('Esqueci minha senha'),
                child: Text(
                  'Esqueci minha senha',
                  style: GoogleFonts.comfortaa(
                    fontSize: 17,
                    fontWeight: FontWeight.w300,
                    color: _blue,
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}