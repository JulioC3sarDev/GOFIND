import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/widgets.dart';
import 'perfil_usuario.dart';

// Uma pessoa dentro de um grupo
// Uma pessoa dentro de um grupo
class Membro {
  final String nome;
  final bool ehVoce; // true = é o dono do celular
  final bool admin;
  final bool online;
  final String? caminhoFoto;

  // Onde o amigo está em relação a você. Virá da conexão entre os celulares;
  // enquanto for null, o radar não desenha o amigo (só o lista).
  final double? distanciaM; // distância em metros
  final double? direcaoGraus; // 0 = norte, 90 = leste, 180 = sul, 270 = oeste

  const Membro({
    required this.nome,
    this.ehVoce = false,
    this.admin = false,
    this.online = false,
    this.caminhoFoto,
    this.distanciaM,
    this.direcaoGraus,
  });

  ImageProvider get foto {
    if (ehVoce) return PerfilUsuario.foto;
    final caminho = caminhoFoto;
    if (caminho == null) {
      return const AssetImage('assets/images/placeholder.png');
    }
    if (kIsWeb) return NetworkImage(caminho);
    return FileImage(File(caminho));
  }
}

// Os tipos de mensagem que o chat mostra
enum TipoMensagem {
  texto, // conversa normal
  sistema, // aviso no meio do chat (ex.: ponto de encontro compartilhado)
  perdido, // alerta "Estou perdido"
}

// Uma mensagem do chat de um grupo
class Mensagem {
  final String autor;
  final bool ehVoce;
  final TipoMensagem tipo;
  final String texto;
  final DateTime hora;

  Mensagem({
    required this.autor,
    this.ehVoce = false,
    this.tipo = TipoMensagem.texto,
    this.texto = '',
    DateTime? hora,
  }) : hora = hora ?? DateTime.now();
}

// O ponto de encontro de um grupo
class PontoEncontro {
  // Virão do GPS (ainda não são capturados)
  final double? latitude;
  final double? longitude;
  final String criadoPor;
  final DateTime criadoEm;

  PontoEncontro({
    this.latitude,
    this.longitude,
    required this.criadoPor,
    DateTime? criadoEm,
  }) : criadoEm = criadoEm ?? DateTime.now();
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

  // Conversa do grupo (provisório: some quando o app fecha)
  final List<Mensagem> mensagens = [];
  
  // Ponto de encontro atual do grupo (null = ainda não marcado)
  PontoEncontro? ponto;
  
  // Quando o grupo foi encerrado (ou você saiu dele). null = grupo ativo.
  DateTime? encerradoEm;

  Grupo({
    required this.nome,
    this.codigo = '',
    this.descricao = '',
    this.eventoNome = '',
    this.data,
    this.hora = '',
    this.local = '',
    this.caminhoFoto,
    this.imagem = 'assets/images/Ícone Azul de Grupo Amigável.png',
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

  if (caminho != null) {
    if (kIsWeb) return NetworkImage(caminho);
    return FileImage(File(caminho));
  }

  return AssetImage(imagem);
}
}

// Guarda os grupos do usuário enquanto o app está aberto.
// Provisório: quando chegarmos no Hive, isso passa a salvar no celular.
class GruposUsuario {
  // Grupos ativos. Começa vazia: é o que o usuário vê na primeira vez
  static final List<Grupo> lista = [];

  // Grupos encerrados (ou dos quais você saiu): ficam guardados em "Inativos"
  static final List<Grupo> encerrados = [];

  // Sobe a cada mudança. As telas escutam isto para se redesenhar.
  static final ValueNotifier<int> versao = ValueNotifier<int>(0);

  // Avisa as telas que algum grupo mudou (por exemplo, depois de editar)
  static void avisar() => versao.value++;

  static void adicionar(Grupo grupo) {
    lista.insert(0, grupo);
    avisar();
  }

  // Encerra: sai da lista de ativos e vai para o histórico (Inativos).
  // Como saiu de "lista", some da Home, do Radar e dos alertas automaticamente.
  static void encerrar(Grupo grupo) {
    lista.remove(grupo);
    grupo.encerradoEm = DateTime.now();
    encerrados.insert(0, grupo);
    avisar();
  }

  // Apaga de vez um grupo do histórico
  static void removerDoHistorico(Grupo grupo) {
    encerrados.remove(grupo);
    avisar();
  }

  // Apaga tudo (usado em "Sair e apagar meus dados")
  static void limparTudo() {
    lista.clear();
    encerrados.clear();
    avisar();
  }
}