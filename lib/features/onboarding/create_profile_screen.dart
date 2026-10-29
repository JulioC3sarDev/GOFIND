import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/perfil_usuario.dart';
import '../permissions/permissions_screen.dart';
import '../profile/foto_perfil.dart';

const _blue = Color(0xFF0066FF);
const _borda = Color(0xFFD9D9D9);
const _dica = Color(0xFF9E9E9E);
const _iconeCor = Color(0xFF6B6B6B);

class CriarPerfilScreen extends StatefulWidget {
  const CriarPerfilScreen({super.key});

  @override
  State<CriarPerfilScreen> createState() => _CriarPerfilScreenState();
}

class _CriarPerfilScreenState extends State<CriarPerfilScreen> {
  final _nome = TextEditingController();
  String? _caminhoFoto;
  bool _erro = false;

  @override
  void dispose() {
    _nome.dispose();
    super.dispose();
  }

  ImageProvider get _imagem {
    final c = _caminhoFoto;
    if (c == null) return const AssetImage('assets/images/placeholder.png');
    return kIsWeb ? NetworkImage(c) : FileImage(File(c));
  }

  void _continuar() {
    final nome = _nome.text.trim();
    if (nome.length < 2) {
      setState(() => _erro = true);
      return;
    }
    FocusScope.of(context).unfocus();

    PerfilUsuario.nome = nome;
    PerfilUsuario.caminhoFoto = _caminhoFoto;
    PerfilUsuario.garantirId(); // a identidade deste aparelho
    PerfilUsuario.avisar();

    debugPrint('Perfil criado. ID do aparelho: ${PerfilUsuario.idDispositivo}');

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PermissionsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const SizedBox(height: 24),

              // Logo no canto esquerdo
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 2),
                  child: Image.asset('assets/images/logo.png', width: 110),
                ),
              ),
              const SizedBox(height: 28),

              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Como devemos\nte chamar?',
                  style: GoogleFonts.comfortaa(
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                    color: _blue,
                    height: 1.2,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Seus amigos vão ver seu nome e sua foto nos grupos.',
                  style: GoogleFonts.comfortaa(
                    fontSize: 15,
                    fontWeight: FontWeight.w300,
                    color: const Color(0xFF6B6B6B),
                    height: 1.35,
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Foto (opcional): toque para escolher
              GestureDetector(
                onTap: () => escolherFotoDoPerfil(
                  context,
                  (caminho) => setState(() => _caminhoFoto = caminho),
                ),
                child: SizedBox(
                  width: 170,
                  height: 170,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        // A foto nova entra com uma troca suave
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: Container(
                            key: ValueKey(_caminhoFoto),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: _blue, width: 3),
                              image: DecorationImage(
                                image: _imagem,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 4,
                        bottom: 8,
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: _blue,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                          ),
                          child: const Icon(Icons.photo_camera,
                              size: 20, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _caminhoFoto == null
                    ? 'Toque para escolher uma foto (opcional)'
                    : 'Toque na foto para trocar',
                style: GoogleFonts.comfortaa(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w300,
                  color: _dica,
                ),
              ),
              const SizedBox(height: 24),

              // Nome
              TextField(
                controller: _nome,
                maxLength: 24,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _continuar(),
                onChanged: (_) {
                  if (_erro) setState(() => _erro = false);
                },
                style: GoogleFonts.comfortaa(fontSize: 16),
                decoration: InputDecoration(
                  counterText: '',
                  hintText: 'Seu nome',
                  hintStyle: GoogleFonts.comfortaa(
                    fontSize: 16,
                    fontWeight: FontWeight.w300,
                    color: _dica,
                  ),
                  errorText: _erro ? 'Digite seu nome (mínimo 2 letras)' : null,
                  prefixIcon:
                      const Icon(Icons.person_outline, color: _iconeCor),
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(color: _borda),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(color: _blue),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(color: Color(0xFFD32F2F)),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(color: Color(0xFFD32F2F)),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              SizedBox(
                width: double.infinity,
                height: 51,
                child: FilledButton(
                  onPressed: _continuar,
                  style: FilledButton.styleFrom(
                    backgroundColor: _blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Text(
                    'Continuar',
                    style: GoogleFonts.comfortaa(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Aviso: o que NÃO pedimos
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 1),
                    child: Icon(Icons.lock_outline, size: 16, color: _dica),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Seu perfil fica só neste celular. Não pedimos e-mail nem senha.',
                      style: GoogleFonts.comfortaa(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w300,
                        color: _dica,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}