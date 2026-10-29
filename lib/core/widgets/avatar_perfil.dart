import 'package:flutter/material.dart';
import '../perfil_usuario.dart';

// Foto do perfil em círculo, para os cabeçalhos azuis.
// Sem foto, mostra um ícone de pessoa branco (que aparece bem sobre o azul).
// Se atualiza sozinho quando o perfil muda.
class AvatarPerfil extends StatelessWidget {
  final double tamanho;
  final double borda;

  const AvatarPerfil({super.key, this.tamanho = 55, this.borda = 2});

  Widget _icone(double lado) => Center(
        child: Icon(Icons.person, color: Colors.white, size: lado * 0.6),
      );

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: PerfilUsuario.versao,
      builder: (context, _, __) {
        final interno = tamanho - 2 * borda;
        final temFoto = PerfilUsuario.caminhoFoto != null;

        return Container(
          width: tamanho,
          height: tamanho,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.18),
            border: Border.all(color: Colors.white, width: borda),
          ),
          child: ClipOval(
            child: temFoto
                ? Image(
                    image: PerfilUsuario.foto,
                    width: interno,
                    height: interno,
                    fit: BoxFit.cover,
                    // Se o arquivo da foto sumiu, mostra o ícone
                    errorBuilder: (_, __, ___) => _icone(interno),
                  )
                : _icone(interno),
          ),
        );
      },
    );
  }
}