import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

// Abre o menu "Galeria / Câmera" e entrega o caminho da foto escolhida
Future<void> escolherFotoDoPerfil(
  BuildContext context,
  void Function(String caminho) aoEscolher,
) async {
  final origem = await showModalBottomSheet<ImageSource>(
    context: context,
    useRootNavigator: true,
    builder: (ctx) => SafeArea(
      child: Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('Escolher da galeria'),
            onTap: () => Navigator.pop(ctx, ImageSource.gallery),
          ),
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: const Text('Tirar uma foto'),
            onTap: () => Navigator.pop(ctx, ImageSource.camera),
          ),
        ],
      ),
    ),
  );
  if (origem == null) return;

  final imagem = await ImagePicker().pickImage(
    source: origem,
    maxWidth: 800,
    imageQuality: 85,
  );
  if (imagem != null) aoEscolher(imagem.path);
}