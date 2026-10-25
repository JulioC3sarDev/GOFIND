import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/perfil_usuario.dart';
import '../../core/widgets/app_text_field.dart';
import '../permissions/permissions_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  static const _blue = Color(0xFF0066FF);
  static const _hint = Color(0xFF9E9E9E);
  static const _tamanhoAvatar = 227.0;

  final _picker = ImagePicker();
  XFile? _foto; // null = ainda sem foto escolhida

  // Liga o campo "Nome" ao código, para ler o que foi digitado
  final _nomeController = TextEditingController();

  @override
  void dispose() {
    _nomeController.dispose();
    super.dispose();
  }

  Future<void> _escolherFoto(ImageSource origem) async {
    final imagem = await _picker.pickImage(
      source: origem,
      maxWidth: 800,
      imageQuality: 85,
    );
    if (imagem != null) {
      setState(() => _foto = imagem);
    }
  }

  void _mostrarOpcoes() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Escolher da galeria'),
              onTap: () {
                Navigator.pop(ctx);
                _escolherFoto(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Tirar uma foto'),
              onTap: () {
                Navigator.pop(ctx);
                _escolherFoto(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _avatar() {
    if (_foto == null) {
      return Image.asset(
        'assets/images/placeholder.png',
        width: _tamanhoAvatar,
        height: _tamanhoAvatar,
      );
    }

    // No navegador o caminho é uma URL; no celular é um arquivo
    final ImageProvider imagem = kIsWeb
        ? NetworkImage(_foto!.path)
        : FileImage(File(_foto!.path));

    return CircleAvatar(
      radius: _tamanhoAvatar / 2,
      backgroundImage: imagem,
    );
  }

  void _criarConta() {
    final nome = _nomeController.text.trim();

    if (nome.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Digite seu nome para continuar')),
      );
      return;
    }

    // Guarda o nome para a Home mostrar "Olá, nome"
    PerfilUsuario.nome = nome;

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

              const SizedBox(height: 23),

              // Avatar: toque para escolher a foto
              GestureDetector(
                onTap: _mostrarOpcoes,
                child: _avatar(),
              ),

              const SizedBox(height: 18),

              Text(
                _foto == null
                    ? 'Selecione uma foto de perfil'
                    : 'Toque na foto para trocar',
                style: GoogleFonts.comfortaa(
                  fontSize: 15,
                  fontWeight: FontWeight.w300,
                  color: _hint,
                ),
              ),

              const SizedBox(height: 22),

              // Sem "const": este campo usa o controller, que é uma variável
              AppTextField(
                hint: 'Nome',
                icon: Icons.person_outline,
                controller: _nomeController,
              ),
              const SizedBox(height: 13),
              const AppTextField(
                hint: 'E-mail',
                icon: Icons.mail_outline,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 13),
              const AppTextField(
                hint: 'Senha',
                icon: Icons.lock_outline,
                isPassword: true,
              ),
              const SizedBox(height: 13),
              const AppTextField(
                hint: 'Confirme a senha',
                icon: Icons.lock_outline,
                isPassword: true,
              ),

              const SizedBox(height: 21),

              SizedBox(
                width: double.infinity,
                height: 51,
                child: FilledButton(
                  onPressed: _criarConta,
                  style: FilledButton.styleFrom(
                    backgroundColor: _blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Text(
                    'Criar conta',
                    style: GoogleFonts.comfortaa(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
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