import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart' show ValueNotifier, kIsWeb;
import 'package:flutter/widgets.dart';

// Os dados do dono do celular.
// Provisório: ficam só na memória; no Hive passam a ser salvos no aparelho.
class PerfilUsuario {
  static const _bioPadrao = 'Sempre por perto com o GoFind!';

  static String nome = '';
  static String bio = _bioPadrao;
  static String? caminhoFoto;

  // Identidade neste aparelho: um código aleatório criado uma única vez.
  // É o que diferencia você de outra pessoa com o mesmo nome nos grupos.
  static String idDispositivo = '';

  // Preferências
  // O código que compartilha a localização deve respeitar esta opção
  static bool compartilharLocalizacao = true;
  static bool vibrarAoAlinhar = true;

  // Já existe um perfil neste aparelho? (decide se pula a boas-vindas)
  static bool get temPerfil => nome.trim().isNotEmpty;

  // Cria o ID do aparelho se ainda não existir (16 bytes aleatórios seguros)
  static void garantirId() {
    if (idDispositivo.isNotEmpty) return;
    final r = Random.secure();
    idDispositivo = List.generate(
      16,
      (_) => r.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
  }

  // A foto do perfil (ou a imagem padrão, se não escolheu nenhuma)
  static ImageProvider get foto {
    final caminho = caminhoFoto;
    if (caminho == null) {
      return const AssetImage('assets/images/placeholder.png');
    }
    if (kIsWeb) return NetworkImage(caminho);
    return FileImage(File(caminho));
  }

  // Sobe a cada mudança no perfil, para as telas se redesenharem
  static final ValueNotifier<int> versao = ValueNotifier<int>(0);
  static void avisar() => versao.value++;

  // Apaga tudo (usado em "Sair e apagar meus dados"), inclusive a identidade
  static void limpar() {
    nome = '';
    bio = _bioPadrao;
    caminhoFoto = null;
    idDispositivo = '';
    compartilharLocalizacao = true;
    vibrarAoAlinhar = true;
    avisar();
  }
}