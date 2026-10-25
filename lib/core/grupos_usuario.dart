import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/widgets.dart';

// Uma pessoa dentro de um grupo
class Membro {
  final String nome;
  final bool ehVoce; // true = é o dono do celular
  final bool admin;
  final bool online;
  final String? caminhoFoto;

  const Membro({
    required this.nome,
    this.ehVoce = false,
    this.admin = false,
    this.online = false,
    this.caminhoFoto,
  });

  ImageProvider get foto {
    final caminho = caminhoFoto;
    if (caminho == null) {
      return const AssetImage('assets/images/placeholder.png');
    }
    if (kIsWeb) return NetworkImage(caminho);
    return FileImage(File(caminho));
  }
}

// Modelo de um grupo. Os campos editáveis não são "final":
// a tela Configurar grupo altera esses valores.
class Grupo {
  String nome;
  String codigo;
  String descricao;
  String eventoNome;
  DateTime? data;
  String hora; // "19:00" ou vazio
  String local;
  String? caminhoFoto; // foto escolhida pelo usuário (ou null)
  final String imagem; // imagem padrão, usada quando não há foto
  final List<Membro> membros;

  Grupo({
    required this.nome,
    this.codigo = '',
    this.descricao = '',
    this.eventoNome = '',
    this.data,
    this.hora = '',
    this.local = '',
    this.caminhoFoto,
    this.imagem = 'assets/images/group_placeholder.png',
    this.membros = const [],
  });

  static const _meses = [
    'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
    'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro',
  ];

  // Textos prontos para exibir na tela do grupo
  String get dataTexto {
    final d = data;
    if (d == null) return 'Não informado';
    return '${d.day} de ${_meses[d.month - 1]}';
  }

  String get horaTexto => hora.isEmpty ? 'Não informado' : 'Às $hora';

  String get localTexto => local.isEmpty ? 'Não informado' : local;

  // O dono do celular é administrador deste grupo?
  bool get voceEhAdmin => membros.any((m) => m.ehVoce && m.admin);

  // Existe alguém além de você no grupo?
  bool get temOutrosMembros => membros.any((m) => !m.ehVoce);

  // Devolve a foto escolhida ou, se não houver, a imagem padrão
  ImageProvider get foto {
    final caminho = caminhoFoto;
    if (caminho == null) return AssetImage(imagem);
    if (kIsWeb) return NetworkImage(caminho);
    return FileImage(File(caminho));
  }
}

// Guarda os grupos do usuário enquanto o app está aberto.
// Provisório: quando chegarmos no Hive, isso passa a salvar no celular.
class GruposUsuario {
  // Começa vazia: é o que o usuário vê na primeira vez que abre o app
  static final List<Grupo> lista = [];

  // Sobe a cada mudança. As telas escutam isto para se redesenhar.
  static final ValueNotifier<int> versao = ValueNotifier<int>(0);

  // Avisa as telas que algum grupo mudou (por exemplo, depois de editar)
  static void avisar() => versao.value++;

  static void adicionar(Grupo grupo) {
    lista.insert(0, grupo);
    avisar();
  }

  static void remover(Grupo grupo) {
    lista.remove(grupo);
    avisar();
  }
}