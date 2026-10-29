import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gofind/core/grupos_usuario.dart';

class FotoMembro extends StatelessWidget {
  final Membro membro;
  final double tamanho;
  final double borda; // 0 = sem borda

  const FotoMembro({
    super.key,
    required this.membro,
    required this.tamanho,
    this.borda = 0,
  });

  // Helper para obter a imagem de forma segura, seja da galeria local ou web
  ImageProvider _obterImagem(String caminho) {
    if (kIsWeb || caminho.startsWith('http')) return NetworkImage(caminho);
    return FileImage(File(caminho));
  }

  @override
  Widget build(BuildContext context) {
    final caminhoFoto = membro.caminhoFoto;
    final temFoto = caminhoFoto != null && caminhoFoto.isNotEmpty;

    return Container(
      width: tamanho,
      height: tamanho,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFB8C4D9),
        border: borda > 0 ? Border.all(color: Colors.white, width: borda) : null,
        image: temFoto
            ? DecorationImage(
                image: _obterImagem(caminhoFoto),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: temFoto
          ? null
          : Text(
              membro.nome.isEmpty ? '?' : membro.nome[0].toUpperCase(),
              style: GoogleFonts.comfortaa(
                fontSize: tamanho * 0.42,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
    );
  }
}