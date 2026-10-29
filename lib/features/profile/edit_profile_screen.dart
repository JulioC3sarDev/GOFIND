import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/grupos_usuario.dart';
import '../../core/perfil_usuario.dart';
import 'foto_perfil.dart';

const _blue = Color(0xFF0066FF);
const _borda = Color(0xFFD9D9D9);
const _dica = Color(0xFF9E9E9E);
const _iconeCor = Color(0xFF6B6B6B);

class EditarPerfilScreen extends StatefulWidget {
  const EditarPerfilScreen({super.key});

  @override
  State<EditarPerfilScreen> createState() => _EditarPerfilScreenState();
}

class _EditarPerfilScreenState extends State<EditarPerfilScreen> {
  late final TextEditingController _nome =
      TextEditingController(text: PerfilUsuario.nome);
  late final TextEditingController _bio =
      TextEditingController(text: PerfilUsuario.bio);

  // A foto só vale de verdade quando você toca em Salvar
  String? _caminhoFoto = PerfilUsuario.caminhoFoto;

  @override
  void dispose() {
    _nome.dispose();
    _bio.dispose();
    super.dispose();
  }

  ImageProvider get _imagem {
    final c = _caminhoFoto;
    if (c == null) return const AssetImage('assets/images/placeholder.png');
    return kIsWeb ? NetworkImage(c) : FileImage(File(c));
  }

  void _salvar() {
    final nome = _nome.text.trim();
    if (nome.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Digite seu nome para continuar')),
      );
      return;
    }

    PerfilUsuario.nome = nome;
    PerfilUsuario.bio = _bio.text.trim();
    PerfilUsuario.caminhoFoto = _caminhoFoto;

    // Avisa as telas que mostram o perfil
    PerfilUsuario.avisar();
    GruposUsuario.avisar();

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Perfil atualizado')));

    Navigator.pop(context);
  }

  Widget _campo({
    required TextEditingController controller,
    required String dica,
    required IconData icone,
    int? maxLength,
    TextCapitalization capitalizacao = TextCapitalization.sentences,
  }) {
    return TextField(
      controller: controller,
      maxLength: maxLength,
      textCapitalization: capitalizacao,
      style: GoogleFonts.comfortaa(fontSize: 16),
      decoration: InputDecoration(
        hintText: dica,
        hintStyle: GoogleFonts.comfortaa(
          fontSize: 16,
          fontWeight: FontWeight.w300,
          color: _dica,
        ),
        prefixIcon: Icon(icone, color: _iconeCor),
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: _borda),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: _blue),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topo = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: Colors.white,
      body: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.fromLTRB(26, topo + 16, 26, 28),
        children: [
          // Cabeçalho: voltar + título
          Row(
            children: [
              Material(
                color: _blue,
                shape: const CircleBorder(),
                elevation: 3,
                shadowColor: const Color(0x440066FF),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => Navigator.pop(context),
                  child: const SizedBox(
                    width: 42,
                    height: 42,
                    child: Center(
                      child: Icon(Icons.arrow_back_ios_new,
                          size: 18, color: Colors.white),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Text(
                'Editar perfil',
                style: GoogleFonts.comfortaa(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: _blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // Foto
          Center(
            child: GestureDetector(
              onTap: () => escolherFotoDoPerfil(
                context,
                (caminho) => setState(() => _caminhoFoto = caminho),
              ),
              child: SizedBox(
                width: 132,
                height: 132,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Container(
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
                    Positioned(
                      right: 0,
                      bottom: 6,
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: _blue,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                        child: const Icon(Icons.photo_camera,
                            size: 18, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: Text(
              'Toque na foto para trocar',
              style: GoogleFonts.comfortaa(
                fontSize: 14,
                fontWeight: FontWeight.w300,
                color: _dica,
              ),
            ),
          ),
          const SizedBox(height: 26),

          _campo(
            controller: _nome,
            dica: 'Nome',
            icone: Icons.person_outline,
            capitalizacao: TextCapitalization.words,
          ),
          const SizedBox(height: 16),
          _campo(
            controller: _bio,
            dica: 'Frase do perfil (opcional)',
            icone: Icons.edit_note,
            maxLength: 60,
          ),
          const SizedBox(height: 18),

          SizedBox(
            height: 51,
            child: FilledButton(
              onPressed: _salvar,
              style: FilledButton.styleFrom(
                backgroundColor: _blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text(
                'Salvar',
                style: GoogleFonts.comfortaa(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}