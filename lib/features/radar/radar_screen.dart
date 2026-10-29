import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/grupos_usuario.dart';
import '../../core/modo_teste.dart';
import '../../core/navegacao_app.dart';
import '../../core/radar/seguir_screen.dart';

const _blue = Color(0xFF0066FF);
const _azulEscuro = Color(0xFF0050D6);
const _borda = Color(0xFFE3ECFF);
const _verde = Color(0xFF1FAF38);
const _laranja = Color(0xFFFF9800);
const _vermelho = Color(0xFFE53935);
const _cinza = Color(0xFF9E9E9E);

// Distância que o radar cobre (a borda do círculo maior), em metros
const double _alcanceM = 100;

// Quão perto o amigo está: texto e cor da bolinha
class _Prox {
  final String texto;
  final Color cor;
  const _Prox(this.texto, this.cor);
}

_Prox _proximidade(Membro m) {
  final d = m.distanciaM;
  if (d == null) return const _Prox('Procurando sinal...', _cinza);
  if (d <= 30) return const _Prox('Muito Próximo', _verde);
  if (d <= 55) return const _Prox('Próximo', _verde);
  if (d <= 80) return const _Prox('Perto', _laranja);
  return const _Prox('Limite de alcance', _vermelho);
}

// Se não sabemos a direção, espalha os amigos de forma estável pelo nome
double _direcao(Membro m) =>
    m.direcaoGraus ?? (m.nome.hashCode.abs() % 360).toDouble();

String _textoMembros(Grupo g) {
  final n = g.membros.length;
  return '$n ${n == 1 ? 'membro' : 'membros'}';
}

// Abre a tela de seguir um amigo, por cima da barra de baixo
void _seguir(BuildContext context, Membro amigo) {
  Navigator.of(context, rootNavigator: true).push(
    MaterialPageRoute(builder: (_) => SeguirScreen(amigo: amigo)),
  );
}

// ---------------------------------------------------------------
// Janela para escolher um grupo.
// - Sem "botao": tocar no grupo escolhe na hora.
// - Com "botao": você marca um grupo e confirma no botão.
// ---------------------------------------------------------------
Future<Grupo?> _abrirSeletor(
  BuildContext context, {
  required String titulo,
  required String subtitulo,
  Grupo? inicial,
  String? botao,
}) {
  return showModalBottomSheet<Grupo>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) {
      Grupo? marcado = inicial;

      return StatefulBuilder(
        builder: (ctx, setSheet) {
          return SafeArea(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(ctx).height * 0.8,
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 42,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFDADADA),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      titulo,
                      style: GoogleFonts.comfortaa(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        color: _blue,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitulo,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: const Color(0xFF6B6B6B),
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Flexible(
                      child: ListView(
                        shrinkWrap: true,
                        children: [
                          for (final g in GruposUsuario.lista)
                            _OpcaoGrupo(
                              grupo: g,
                              mostrarMarca: botao != null,
                              marcado: marcado == g,
                              onTap: () {
                                if (botao == null) {
                                  Navigator.pop(ctx, g);
                                } else {
                                  setSheet(() => marcado = g);
                                }
                              },
                            ),
                        ],
                      ),
                    ),
                    if (botao != null) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: FilledButton(
                          onPressed: marcado == null
                              ? null
                              : () => Navigator.pop(ctx, marcado),
                          style: FilledButton.styleFrom(
                            backgroundColor: _blue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            botao,
                            style: GoogleFonts.comfortaa(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

class RadarScreen extends StatelessWidget {
  // Chamado pela seta de voltar (leva para a aba Início)
  final VoidCallback onVoltar;

  const RadarScreen({super.key, required this.onVoltar});

  // Amigos do grupo, do mais perto para o mais longe
  List<Membro> _amigosDo(Grupo grupo) {
    final lista = amigosDeTeste
        ? [...amigosFicticios]
        : grupo.membros.where((m) => !m.ehVoce).toList();

    lista.sort((a, b) {
      final da = a.distanciaM;
      final db = b.distanciaM;
      if (da == null && db == null) return 0;
      if (da == null) return 1;
      if (db == null) return -1;
      return da.compareTo(db);
    });
    return lista;
  }

  void _aviso(BuildContext context, String texto) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(texto)));
  }

  // Botão Perdido: pergunta para qual grupo e só então envia
  Future<void> _perdido(BuildContext context, Grupo? atual) async {
    if (GruposUsuario.lista.isEmpty) {
      _aviso(context, 'Entre em um grupo para pedir ajuda ao pessoal.');
      return;
    }

    final escolhido = await _abrirSeletor(
      context,
      titulo: 'Avisar qual grupo?',
      subtitulo:
          'O alerta "Estou perdido" vai só para o grupo que você marcar.',
      inicial: atual,
      botao: 'Avisar grupo',
    );
    if (escolhido == null || !context.mounted) return;

    escolhido.mensagens.add(Mensagem(
      autor: 'Você',
      ehVoce: true,
      tipo: TipoMensagem.perdido,
      texto: 'não estou conseguindo achar o grupo',
    ));
    _aviso(context, 'Alerta enviado ao grupo "${escolhido.nome}".');
  }

  // Trocar o grupo que o radar está mostrando
  Future<void> _trocarGrupo(BuildContext context, Grupo atual) async {
    final novo = await _abrirSeletor(
      context,
      titulo: 'Trocar de grupo',
      subtitulo: 'Escolha de qual grupo você quer ver os amigos.',
      inicial: atual,
    );
    if (novo != null) NavegacaoApp.grupoDoRadar.value = novo;
  }

  @override
  Widget build(BuildContext context) {
    // Redesenha quando os grupos mudarem ou o grupo do radar for trocado
    return ListenableBuilder(
      listenable: Listenable.merge([
        GruposUsuario.versao,
        NavegacaoApp.grupoDoRadar,
      ]),
      builder: (context, _) {
        final topo = MediaQuery.of(context).padding.top;
        final grupos = GruposUsuario.lista;

        // Se o grupo escolhido foi encerrado, volta a perguntar
        final escolhido = NavegacaoApp.grupoDoRadar.value;
        final grupo =
            (escolhido != null && grupos.contains(escolhido)) ? escolhido : null;

        final amigos = grupo == null ? <Membro>[] : _amigosDo(grupo);

        return Scaffold(
          backgroundColor: Colors.white,
          body: ListView(
            padding: EdgeInsets.fromLTRB(14, topo + 16, 14, 28),
            children: [
              _cabecalho(),
              const SizedBox(height: 18),

              if (grupos.isEmpty)
                const _SemGrupos()
              else if (grupo == null) ...[
                // Ainda não escolheu o grupo
                _EscolherGrupo(
                  grupos: grupos,
                  onEscolher: (g) => NavegacaoApp.grupoDoRadar.value = g,
                ),
                const SizedBox(height: 16),
                _BotaoPerdido(onTap: () => _perdido(context, null)),
              ] else ...[
                // Grupo escolhido: etiqueta, radar, Perdido e lista
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 11),
                    child: _EtiquetaGrupo(
                      grupo: grupo,
                      onTap: () => _trocarGrupo(context, grupo),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 17),
                  child: RadarView(amigos: amigos),
                ),
                const SizedBox(height: 16),
                _BotaoPerdido(onTap: () => _perdido(context, grupo)),
                const SizedBox(height: 12),
                _CartaoAmigos(amigos: amigos),
              ],
            ],
          ),
        );
      },
    );
  }

  // Cabeçalho: voltar + título
  Widget _cabecalho() {
    return Padding(
      padding: const EdgeInsets.only(left: 11),
      child: Row(
        children: [
          Material(
            color: _blue,
            shape: const CircleBorder(),
            elevation: 3,
            shadowColor: const Color(0x440066FF),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onVoltar, // <-- Aqui já usa o callback passado (que fará o pop correto)
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Radar de amigos',
                  style: GoogleFonts.comfortaa(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: _blue,
                  ),
                ),
                Text(
                  'Veja quem está por perto',
                  style: GoogleFonts.comfortaa(
                    fontSize: 16,
                    fontWeight: FontWeight.w300,
                    color: const Color(0xFF7A7A7A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------
// Estados da tela
// ---------------------------------------------------------------

// Você não tem nenhum grupo
class _SemGrupos extends StatelessWidget {
  const _SemGrupos();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _borda, width: 1.5),
      ),
      child: Column(
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: const BoxDecoration(
              color: Color(0xFFE8F0FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.radar, color: _blue, size: 42),
          ),
          const SizedBox(height: 16),
          Text(
            'Você ainda não tem grupos',
            textAlign: TextAlign.center,
            style: GoogleFonts.comfortaa(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: _blue,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Crie ou entre em um grupo para localizar seus amigos no radar.',
            textAlign: TextAlign.center,
            style: GoogleFonts.comfortaa(
              fontSize: 14,
              fontWeight: FontWeight.w300,
              color: const Color(0xFF6B6B6B),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 46,
            child: FilledButton(
              onPressed: () => NavegacaoApp.pedidoDeAba.value = 1,
              style: FilledButton.styleFrom(
                backgroundColor: _blue,
                padding: const EdgeInsets.symmetric(horizontal: 28),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                'Ver meus grupos',
                style: GoogleFonts.comfortaa(
                  fontSize: 15,
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

// Pergunta de qual grupo você quer ver os amigos
class _EscolherGrupo extends StatelessWidget {
  final List<Grupo> grupos;
  final ValueChanged<Grupo> onEscolher;

  const _EscolherGrupo({required this.grupos, required this.onEscolher});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _borda, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Qual grupo você quer localizar?',
            style: GoogleFonts.comfortaa(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: _blue,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Escolha um grupo para ver onde estão seus amigos.',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFF6B6B6B),
            ),
          ),
          const SizedBox(height: 10),
          for (final g in grupos)
            _OpcaoGrupo(
              grupo: g,
              mostrarMarca: false,
              marcado: false,
              onTap: () => onEscolher(g),
            ),
        ],
      ),
    );
  }
}

// Uma linha de grupo (usada na pergunta e nas janelas de escolha)
class _OpcaoGrupo extends StatelessWidget {
  final Grupo grupo;
  final bool mostrarMarca; // true = mostra a bolinha de seleção
  final bool marcado;
  final VoidCallback onTap;

  const _OpcaoGrupo({
    required this.grupo,
    required this.mostrarMarca,
    required this.marcado,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image(
                image: grupo.foto,
                width: 50,
                height: 46,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 50,
                  height: 46,
                  color: const Color(0xFFE8F0FF),
                  child: const Icon(Icons.groups, color: _blue),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    grupo.nome,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.comfortaa(
                      fontSize: 17,
                      color: _blue,
                    ),
                  ),
                  Text(
                    _textoMembros(grupo),
                    style: GoogleFonts.comfortaa(
                      fontSize: 12,
                      color: const Color(0xFF6B6B6B),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              mostrarMarca
                  ? (marcado
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked)
                  : Icons.chevron_right,
              color: _blue,
            ),
          ],
        ),
      ),
    );
  }
}

// Etiqueta com o grupo atual do radar (toque para trocar)
class _EtiquetaGrupo extends StatelessWidget {
  final Grupo grupo;
  final VoidCallback onTap;

  const _EtiquetaGrupo({required this.grupo, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 300),
      child: Material(
        color: const Color(0xFFEAF2FF),
        shape: const StadiumBorder(side: BorderSide(color: _borda, width: 1.5)),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(6, 6, 12, 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    image: DecorationImage(image: grupo.foto, fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    grupo.nome,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.comfortaa(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _blue,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.expand_more, color: _blue, size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Botão Perdido
class _BotaoPerdido extends StatelessWidget {
  final VoidCallback onTap;
  const _BotaoPerdido({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Material(
        color: _blue,
        elevation: 5,
        shadowColor: const Color(0x440066FF),
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.warning_rounded,
                    color: Color.fromARGB(255, 254, 254, 254), size: 30),
                const SizedBox(width: 5),
                Text(
                  'Perdido',
                  style: GoogleFonts.comfortaa(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Cartão: Amigos conectados
class _CartaoAmigos extends StatelessWidget {
  final List<Membro> amigos;
  const _CartaoAmigos({required this.amigos});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _borda, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Amigos conectados',
            style: GoogleFonts.comfortaa(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: _blue,
            ),
          ),
          const SizedBox(height: 10),
          if (amigos.isEmpty)
            const _ListaVazia()
          else
            for (var i = 0; i < amigos.length; i++) ...[
              _LinhaAmigo(amigos[i]),
              if (i < amigos.length - 1)
                const Padding(
                  padding: EdgeInsets.only(left: 54),
                  child: Divider(height: 1, color: Color(0xFFE5E5E5)),
                ),
            ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------
// O radar: anéis, sonar girando e os amigos por cima
// ---------------------------------------------------------------
class _Blip {
  final Offset centro; // onde o amigo está, em pixels dentro do radar
  final double angulo; // direção na convenção do canvas, em radianos
  final Color cor;
  const _Blip(this.centro, this.angulo, this.cor);
}

class RadarView extends StatefulWidget {
  final List<Membro> amigos;
  const RadarView({required this.amigos});

  @override
  State<RadarView> createState() => RadarViewState();
}

class RadarViewState extends State<RadarView>
    with SingleTickerProviderStateMixin {
  // Relógio que vai de 0 a 1 e recomeça: uma volta do sonar a cada 4 segundos
  late final AnimationController _volta = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  )..repeat();

  @override
  void dispose() {
    _volta.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: LayoutBuilder(
        builder: (context, c) {
          final lado = c.maxWidth;
          final raio = lado / 2;
          final centro = Offset(raio, raio);

          // Posição de cada amigo que já tem distância conhecida
          final posicionados = <(Membro, Offset, Color)>[];
          final blips = <_Blip>[];
          for (final m in widget.amigos) {
            final d = m.distanciaM;
            if (d == null) continue;

            // Longe da borda e do centro, para o avatar não sair nem cobrir você
            final frac = (d / _alcanceM).clamp(0.28, 0.88);
            final rad = _direcao(m) * pi / 180; // 0 = norte, horário
            final r = frac * raio;
            final pos = Offset(
              centro.dx + r * sin(rad),
              centro.dy - r * cos(rad),
            );
            final cor = _proximidade(m).cor;

            posicionados.add((m, pos, cor));
            blips.add(_Blip(pos, rad - pi / 2, cor));
          }

          return Stack(
            clipBehavior: Clip.none,
            children: [
              RepaintBoundary(
                child: CustomPaint(
                  size: Size.square(lado),
                  painter: _RadarPainter(_volta, blips),
                ),
              ),

              // Amigos
                            // Amigos (toque para seguir)
              for (final (m, pos, cor) in posicionados)
                Positioned(
                  left: pos.dx - 26,
                  top: pos.dy - 26,
                  width: 52,
                  height: 52,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _seguir(context, m),
                    child: Center(
                      child: _AvatarStatus(membro: m, status: cor),
                    ),
                  ),
                ),

              // Você, no centro
              Positioned(
                left: centro.dx - 20,
                top: centro.dy - 20,
                child: const _AvatarStatus(
                  membro: Membro(nome: 'Você', ehVoce: true),
                  status: _blue,
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                top: centro.dy + 23,
                child: Center(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
                    decoration: BoxDecoration(
                      color: _blue,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Text(
                      'Você',
                      style: GoogleFonts.comfortaa(
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// Desenha o fundo do radar e o sonar. Redesenhado a cada quadro da animação.
class _RadarPainter extends CustomPainter {
  final Animation<double> animacao;
  final List<_Blip> blips;

  _RadarPainter(this.animacao, this.blips) : super(repaint: animacao);

  // Os 5 anéis (do maior ao menor), como no Figma, e a cor de cada faixa
  static const _aneis = [1.0, 0.78, 0.55, 0.36, 0.22];
  static const _cores = [
    Color(0xFFD1E3FB),
    Color(0xFFB1D0FF),
    Color(0xFF77ADFF),
    Color(0xFF4C90FF),
    Color(0xFF3F85FF),
  ];

  // Tamanho do rastro da varredura, em radianos (cerca de 70 graus)
  static const _rastro = 1.25;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final raio = size.shortestSide / 2;
    final t = animacao.value; // 0 a 1: uma volta
    // A linha começa apontando para cima (norte) e gira no sentido horário
    final angulo = t * 2 * pi - pi / 2;

    // Faixas de cor
    for (var i = 0; i < _aneis.length; i++) {
      canvas.drawCircle(c, raio * _aneis[i], Paint()..color = _cores[i]);
    }

    // Contornos dos anéis e a cruz
    final contorno = Paint()
      ..color = const Color(0xFF8DB9FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    for (final f in _aneis) {
      canvas.drawCircle(c, raio * f, contorno);
    }
    canvas.drawLine(
        Offset(c.dx - raio, c.dy), Offset(c.dx + raio, c.dy), contorno);
    canvas.drawLine(
        Offset(c.dx, c.dy - raio), Offset(c.dx, c.dy + raio), contorno);

    // Pulso (ping): um anel nasce no centro e se apaga ao chegar na borda
    // (acontece duas vezes por volta)
    final p = (t * 2) % 1.0;
    canvas.drawCircle(
      c,
      raio * p,
      Paint()
        ..color = _azulEscuro.withValues(alpha: 0.30 * (1 - p))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Rastro da varredura: vai de transparente até azul escuro
    final disco = Rect.fromCircle(center: c, radius: raio);
    canvas.drawArc(
      disco,
      angulo - _rastro,
      _rastro,
      true,
      Paint()
        ..shader = SweepGradient(
          startAngle: 0,
          endAngle: _rastro,
          colors: [
            _azulEscuro.withValues(alpha: 0),
            _azulEscuro.withValues(alpha: 0.5),
          ],
          transform: GradientRotation(angulo - _rastro),
        ).createShader(disco),
    );

    // Linha da varredura
    canvas.drawLine(
      c,
      Offset(c.dx + raio * cos(angulo), c.dy + raio * sin(angulo)),
      Paint()
        ..color = _azulEscuro
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );

    // Amigos que acendem quando a linha passa por eles e vão se apagando
    for (final b in blips) {
      // 0 logo depois que a linha passou; quase 2π antes de passar de novo
      final depois = (angulo - b.angulo) % (2 * pi);
      final brilho = 1 - depois / (2 * pi); // 1 = acabou de acender, 0 = apagado

      canvas.drawCircle(
        b.centro,
        22,
        Paint()..color = b.cor.withValues(alpha: 0.25 * brilho),
      );
      canvas.drawCircle(
        b.centro,
        24 + (1 - brilho) * 14,
        Paint()
          ..color = b.cor.withValues(alpha: 0.55 * brilho)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
    }
  }

  @override
  bool shouldRepaint(_RadarPainter antigo) =>
      antigo.animacao != animacao || antigo.blips != blips;
}

// ---------------------------------------------------------------
// Peças pequenas
// ---------------------------------------------------------------

// Foto do membro, ou um círculo cinza com a inicial quando não há foto
class _Foto extends StatelessWidget {
  final Membro membro;
  final double tamanho;
  final bool borda;

  const _Foto({required this.membro, required this.tamanho, this.borda = true});

  @override
  Widget build(BuildContext context) {
    final temFoto = membro.ehVoce || membro.caminhoFoto != null;

    return Container(
      width: tamanho,
      height: tamanho,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFB8B8B8),
        border: borda ? Border.all(color: Colors.white, width: 2.5) : null,
        boxShadow: borda
            ? const [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 4,
                  offset: Offset(0, 1),
                ),
              ]
            : null,
        image: temFoto
            ? DecorationImage(image: membro.foto, fit: BoxFit.cover)
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

// Foto com a bolinha de status no canto (usada dentro do radar)
class _AvatarStatus extends StatelessWidget {
  final Membro membro;
  final Color status;

  const _AvatarStatus({required this.membro, required this.status});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 40,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(child: _Foto(membro: membro, tamanho: 40)),
          Positioned(
            right: -3,
            bottom: -3,
            child: Container(
              width: 15,
              height: 15,
              decoration: BoxDecoration(
                color: status,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Uma linha da lista "Amigos conectados"
// Uma linha da lista "Amigos conectados" (toque para seguir)
class _LinhaAmigo extends StatelessWidget {
  final Membro membro;
  const _LinhaAmigo(this.membro);

  @override
  Widget build(BuildContext context) {
    final prox = _proximidade(membro);

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => _seguir(context, membro),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            _Foto(membro: membro, tamanho: 39, borda: false),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    membro.nome,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.comfortaa(
                      fontSize: 18,
                      color: _blue,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: prox.cor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        prox.texto,
                        style: GoogleFonts.comfortaa(
                          fontSize: 12,
                          color: const Color(0xFF6B6B6B),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Botão de ir até o amigo
            Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(
                color: Color(0xFFE8F0FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.near_me, color: _blue, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}

// Aparece no lugar da lista quando o grupo não tem outros membros
class _ListaVazia extends StatelessWidget {
  const _ListaVazia();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 14, 4, 22),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: Color(0xFFE8F0FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.radar, color: _blue, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'Nenhum amigo conectado neste grupo ainda. Convide pessoas pelo código para vê-las aqui.',
              style: GoogleFonts.comfortaa(
                fontSize: 13.5,
                fontWeight: FontWeight.w300,
                color: const Color(0xFF6B6B6B),
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}