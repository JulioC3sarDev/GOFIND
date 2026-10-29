import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:ui' show lerpDouble;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/bussola.dart';
import '../../core/grupos_usuario.dart';
import '../../core/modo_teste.dart';
import '../../core/perfil_usuario.dart';

const _blue = Color(0xFF0066FF);
const _verde = Color(0xFF00BF13);

// Chegou a 5 m; só considera que se afastou depois de 8 m
// (o GPS oscila alguns metros, e isso evita a tela piscar)
const double _raioChegada = 5;
const double _raioSaida = 8;

// Textos de "onde está o amigo", em 8 setores de 45 graus
const _setores = [
  'à sua frente',
  'à sua frente, à direita',
  'à sua direita',
  'atrás, à direita',
  'atrás de você',
  'atrás, à esquerda',
  'à sua esquerda',
  'à sua frente, à esquerda',
];

String _formatar(double metros) {
  if (metros < 1000) return '${metros.round()} m';
  return '${(metros / 1000).toStringAsFixed(1).replaceAll('.', ',')} km';
}

double _lim(double v) => v < 0 ? 0 : (v > 1 ? 1 : v);

// Distância entre dois ângulos, em graus (0 a 180)
double _distAngular(double a, double b) => (((a - b + 540) % 360) - 180).abs();

// Os números que mudam a cada quadro da animação.
// O desenho escuta este objeto: só ele é redesenhado, e não a tela inteira.
class _Quadro extends ChangeNotifier {
  double angulo = 0; // para onde a seta aponta, em graus (contínuo)
  double brilho = 0; // 0 a 1: quanto o círculo brilha ao apontar certo
  double tempo = 0; // segundos desde que a tela abriu
  double entrada = 0; // 0 a 1: animação de abertura

  void avisar() => notifyListeners();
}

class SeguirScreen extends StatefulWidget {
  final Membro amigo;
  const SeguirScreen({super.key, required this.amigo});

  @override
  State<SeguirScreen> createState() => _SeguirScreenState();
}

class _SeguirScreenState extends State<SeguirScreen>
    with TickerProviderStateMixin {
  final _bussola = Bussola();
  final _quadro = _Quadro();
  late final Ticker _ticker;
  Timer? _esperaBussola;
  Timer? _simulacao;

  // 0 = seta azul, 1 = tela verde de chegada.
  // Anda de 0 a 1 em mais de 1 segundo, com curva suave, e volta se você se afastar.
  late final AnimationController _chegadaCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );
  late final Animation<double> _chegada = CurvedAnimation(
    parent: _chegadaCtrl,
    curve: Curves.easeInOutCubic,
  );

  double? _direcaoCelular; // para onde o celular aponta; null = sem leitura
  double? _distancia; // distância atual até o amigo, em metros
  bool _semBussola = false;
  bool _chegou = false;

  Duration _ultimo = Duration.zero;
  bool _alinhado = false;
  int _setor = 0;

  Membro get _amigo => widget.amigo;
  bool get _temDirecao => _amigo.direcaoGraus != null;

  @override
  void initState() {
    super.initState();
    _distancia = _amigo.distanciaM;

    // O relógio que move a animação, uma vez por quadro
    _ticker = createTicker(_aoQuadro)..start();

    _bussola.iniciar(
      (graus) => _direcaoCelular = graus,
      aoFalhar: _marcarSemBussola,
    );

    // Se nenhuma leitura chegar em 2 segundos, não há bússola neste aparelho
    _esperaBussola = Timer(const Duration(seconds: 2), () {
      if (_direcaoCelular == null) _marcarSemBussola();
    });

    _verificarChegada();

    // Só para teste: simula você andando até o amigo
    if (simularAproximacao && _distancia != null) {
      _simulacao = Timer.periodic(const Duration(milliseconds: 600), (t) {
        final d = _distancia;
        if (d == null || !mounted) return;
        setState(() {
          _distancia = max(0.0, d - 4);
          _verificarChegada();
        });
        if (_distancia! <= 0) t.cancel();
      });
    }
  }

@override
void dispose() {
  _ticker.stop();
  _ticker.dispose();

  _chegadaCtrl.dispose();
  _bussola.parar();
  _esperaBussola?.cancel();
  _simulacao?.cancel();
  _quadro.dispose();

  super.dispose();
}

  void _marcarSemBussola() {
    if (mounted && !_semBussola) setState(() => _semBussola = true);
  }

  // Decide se chegou (ou se afastou de novo) e dispara a transição suave
  void _verificarChegada() {
    final d = _distancia;
    final agora = d != null && (_chegou ? d <= _raioSaida : d <= _raioChegada);
    if (agora == _chegou) return;

    _chegou = agora;
    if (agora) {
        if (PerfilUsuario.vibrarAoAlinhar) HapticFeedback.mediumImpact();
      _chegadaCtrl.forward();
    } else {
      _chegadaCtrl.reverse();
    }
  }

  // Chamado a cada quadro (60 vezes por segundo ou mais)
  void _aoQuadro(Duration t) {
    final double dt =
        ((t - _ultimo).inMicroseconds / 1e6).clamp(0.0, 0.05).toDouble();
    _ultimo = t;

    final q = _quadro;
    q.tempo = t.inMicroseconds / 1e6;
    q.entrada = min(1.0, q.entrada + dt / 0.9);

    final direcao = _amigo.direcaoGraus;
    if (direcao != null) {
      // Para onde a seta deve apontar em relação ao topo do celular
      final alvo = direcao - (_direcaoCelular ?? 0);

      // Caminho mais curto até o alvo, suavizado: nunca dá a volta inteira
      final delta = ((alvo - q.angulo + 540) % 360) - 180;
      q.angulo += delta * (1 - exp(-dt * 10));

      // Está apontando para o amigo? (com folga para não piscar)
      final rel = ((q.angulo % 360) + 540) % 360 - 180;
      final limite = _alinhado ? 16.0 : 10.0;
      final alinhadoAgora = rel.abs() < limite;
      if (alinhadoAgora != _alinhado) {
        _alinhado = alinhadoAgora;
        if (alinhadoAgora && !_chegou && PerfilUsuario.vibrarAoAlinhar) {
          HapticFeedback.lightImpact();
        }
      }

      _atualizarSetor(rel);
    }

    // O brilho vai suavemente até 1 (alinhado) ou 0
    final alvoBrilho = (_alinhado && !_chegou) ? 1.0 : 0.0;
    q.brilho += (alvoBrilho - q.brilho) * (1 - exp(-dt * 8));
    q.avisar();
  }

  // Troca o texto "à sua frente / direita..." só quando muda de verdade
 void _atualizarSetor(double rel) {
  final novo = (rel / 45).round() % 8;

  if (novo == _setor) return;

  if (_distAngular(rel, novo * 45.0) <
      _distAngular(rel, _setor * 45.0) - 6) {
    if (!mounted) return;

    setState(() {
      _setor = novo;
    });
  }
}

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.of(context).padding;
    final d = _distancia;

    final titulo = _temDirecao
        ? 'Siga a indicação até ${_amigo.nome}'
        : 'Procurando ${_amigo.nome}...';

    final legenda = d == null
        ? 'procurando sinal...'
        : _temDirecao
            ? _setores[_setor]
            : 'procurando a direção...';

    final estiloGrande = GoogleFonts.comfortaa(
      fontSize: 48,
      fontWeight: FontWeight.w700,
      color: Colors.white,
      height: 1.05,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _blue,
        body: Stack(
          children: [
            // Fundo, anéis, ondas e seta/check (só esta parte é redesenhada
            // a cada quadro)
            Positioned.fill(
              child: RepaintBoundary(
                child: CustomPaint(
                  painter: _SetaPainter(_quadro, _chegada, _temDirecao),
                ),
              ),
            ),

            // Topo: voltar e pílula
            Padding(
              padding: EdgeInsets.fromLTRB(15, pad.top + 12, 15, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // O ícone do botão muda de azul para verde junto com o fundo
                  AnimatedBuilder(
                    animation: _chegada,
                    builder: (context, _) => Material(
                      color: Colors.white,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => Navigator.pop(context),
                        child: SizedBox(
                          width: 42,
                          height: 42,
                          child: Center(
                            child: Icon(
                              Icons.arrow_back_ios_new,
                              size: 18,
                              color: Color.lerp(_blue, _verde, _chegada.value),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  _Entrada(
                    deslocamento: -14,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _Pilula(
                        amigo: _amigo,
                        texto: titulo,
                        chegada: _chegada,
                      ),
                    ),
                  ),
                  if (_semBussola && !_chegou) ...[
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        'Bússola indisponível neste aparelho. A seta mostra a direção em relação ao norte.',
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          color: Colors.white.withValues(alpha: 0.85),
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Embaixo: distância e onde está. Some deslizando quando chega.
            Positioned(
              left: 27,
              right: 27,
              bottom: pad.bottom + 44,
              child: AnimatedBuilder(
                animation: _chegada,
                builder: (context, filho) {
                  final c = _chegada.value;
                  return IgnorePointer(
                    child: Opacity(
                      opacity: _lim(1 - c * 1.4),
                      child: Transform.translate(
                        offset: Offset(0, 24 * c),
                        child: filho,
                      ),
                    ),
                  );
                },
                child: _Entrada(
                  deslocamento: 14,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (d == null)
                        Text('--', style: estiloGrande)
                      else
                        // O número "rola" até o novo valor
                        TweenAnimationBuilder<double>(
                          tween: Tween<double>(end: d),
                          duration: const Duration(milliseconds: 700),
                          curve: Curves.easeOutCubic,
                          builder: (context, v, _) =>
                              Text(_formatar(v), style: estiloGrande),
                        ),
                      // A legenda troca com uma transição suave
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: Text(
                          legenda,
                          key: ValueKey(legenda),
                          style: GoogleFonts.comfortaa(
                            fontSize: 15,
                            fontWeight: FontWeight.w300,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Faz o conteúdo aparecer deslizando e surgindo, uma vez, ao abrir a tela
class _Entrada extends StatelessWidget {
  final double deslocamento;
  final Widget child;

  const _Entrada({required this.deslocamento, required this.child});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      child: child,
      builder: (context, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(
          offset: Offset(0, deslocamento * (1 - v)),
          child: child,
        ),
      ),
    );
  }
}

// Pílula do topo: foto do amigo + "Siga a indicação até ..." (vira "Chegou")
class _Pilula extends StatelessWidget {
  final Membro amigo;
  final String texto;
  final Animation<double> chegada;

  const _Pilula({
    required this.amigo,
    required this.texto,
    required this.chegada,
  });

  @override
  Widget build(BuildContext context) {
    final temFoto = amigo.caminhoFoto != null;

    final estilo = GoogleFonts.comfortaa(fontSize: 20, color: Colors.white);

    return LayoutBuilder(
      builder: (context, caixa) {
        return AnimatedBuilder(
          animation: chegada,
          builder: (context, _) {
            final c = chegada.value;
            // A pílula encolhe até o tamanho da palavra "Chegou"
            final largura = lerpDouble(caixa.maxWidth, 181, c)!;

            return Align(
              alignment: Alignment.centerLeft,
              child: Container(
                width: largura,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Color.lerp(
                        const Color(0x33003C99),
                        const Color(0x33005A12),
                        c,
                      )!,
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 0),
                      child: Container(
                        width: 56,
                        height: 56,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          image: temFoto
                              ? DecorationImage(
                                  image: FileImage(File(amigo.caminhoFoto!)),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: temFoto
                            ? null
                            : Text(
                                amigo.nome.isEmpty
                                    ? '?'
                                    : amigo.nome[0].toUpperCase(),
                                style: GoogleFonts.comfortaa(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: Color.lerp(_blue, _verde, c),
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Os dois textos se trocam com um fade cruzado
                    Expanded(
                      child: Stack(
                        alignment: Alignment.centerLeft,
                        children: [
                          Opacity(
                            opacity: _lim(1 - c * 2),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(texto, style: estilo),
                            ),
                          ),
                          Opacity(
                            opacity: _lim(c * 2 - 1),
                            child: Text('Chegou', style: estilo),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 18),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// Desenha o fundo, os círculos, as ondas e a seta (que vira o "check").
// Escuta o _Quadro e a animação de chegada, então é redesenhado a cada quadro.
class _SetaPainter extends CustomPainter {
  final _Quadro q;
  final Animation<double> chegada;
  final bool temDirecao;

  _SetaPainter(this.q, this.chegada, this.temDirecao)
      : super(repaint: Listenable.merge([q, chegada]));

  // Um único "pincel" reaproveitado, para não criar objetos a cada quadro
  final Paint _tinta = Paint()..isAntiAlias = true;

  // Os círculos, do maior ao menor: raio, alfa do branco (azul), alfa do preto (verde)
  static const _aneis = [
    (170.0, 0.0, 0.04),
    (129.0, 0.0, 0.07),
    (110.5, 0.05, 0.14),
    (92.5, 0.09, 0.22),
    (70.5, 0.17, 0.32),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final centro = size.center(Offset.zero);
    final c = chegada.value; // 0 = seta azul, 1 = check verde
    final e = Curves.easeOutCubic.transform(_lim(q.entrada)); // abertura
    final esc = 0.6 + 0.4 * e; // os círculos crescem ao abrir
    final t = q.tempo;
    final b = q.brilho;
    final respira = 1 + 0.015 * sin(t * 2 * pi / 3.6); // respiração leve

    // Fundo: azul que vira verde
    _tinta
      ..style = PaintingStyle.fill
      ..color = Color.lerp(_blue, _verde, c)!;
    canvas.drawRect(Offset.zero & size, _tinta);

    // Ondas que saem do centro e vão sumindo
    _tinta
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    for (var i = 0; i < 3; i++) {
      final fase = (t / 3.6 + i / 3) % 1.0;
      final f = Curves.easeOut.transform(fase);
      final raio = (74 + 116 * f) * esc;
      final alfa = (0.22 + 0.22 * b) *
          pow(1 - fase, 1.6).toDouble() *
          e *
          (1 - 0.5 * c);
      _tinta.color = Colors.white.withValues(alpha: _lim(alfa));
      canvas.drawCircle(centro, raio, _tinta);
    }

    // Círculos: no azul são "véus" brancos, no verde viram "véus" escuros
    _tinta.style = PaintingStyle.fill;
    for (final (raio, aAzul, aVerde) in _aneis) {
      var escala = 1.0;
      var alfaAzul = aAzul;
      if (raio == 110.5 || raio == 92.5) {
        escala = respira;
      } else if (raio == 70.5) {
        escala = 1 + 0.06 * b;
        alfaAzul += 0.13 * b;
      }
      _tinta.color = Color.lerp(
        Colors.white.withValues(alpha: _lim(alfaAzul * e)),
        Colors.black.withValues(alpha: _lim(aVerde * e)),
        c,
      )!;
      canvas.drawCircle(centro, raio * escala * esc, _tinta);
    }

    // Quando a seta aponta certo, um anel claro envolve o círculo
    if (b > 0.01) {
      _tinta
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..color = Colors.white.withValues(alpha: _lim(0.55 * b * (1 - c)));
      canvas.drawCircle(centro, 79.5 * (1 + 0.06 * b) * esc, _tinta);
    }

    // Onda de comemoração: aparece só durante a transição de chegada
    if (c > 0.001 && c < 0.999) {
      _tinta
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..color = Colors.white.withValues(alpha: _lim(0.4 * sin(pi * c)));
      canvas.drawCircle(centro, (70 + 140 * c) * esc, _tinta);
    }

    if (temDirecao || c > 0.001) {
      canvas.save();
      canvas.translate(centro.dx, centro.dy);

      // A seta gira para o amigo; ao chegar, vai se endireitando para o check
      if (temDirecao) {
        final ang = ((q.angulo % 360) + 540) % 360 - 180;
        canvas.rotate(ang * (1 - c) * pi / 180);
      }

      // Um leve "pulo" no meio da transformação
      canvas.scale((0.7 + 0.3 * e) * (1 + 0.12 * sin(pi * c)));

      _tinta
        ..style = PaintingStyle.stroke
        ..strokeWidth = 11
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = Colors.white.withValues(alpha: _lim(temDirecao ? e : e * c));

      // A ponta da seta vira o "V" do check (pontos que se movem aos poucos)
      final p0 = Offset.lerp(const Offset(-39, -4), const Offset(-35, -1), c)!;
      final p1 =
          Offset.lerp(const Offset(0, -43), const Offset(-7.5, 26.5), c)!;
      final p2 =
          Offset.lerp(const Offset(39, -4), const Offset(43.5, -25), c)!;
      canvas.drawPath(
        Path()
          ..moveTo(p0.dx, p0.dy)
          ..lineTo(p1.dx, p1.dy)
          ..lineTo(p2.dx, p2.dy),
        _tinta,
      );

      // A haste da seta encolhe até o vértice do check e some
      if (temDirecao) {
        final alfaHaste = _lim(1 - c * 1.6);
        if (alfaHaste > 0) {
          const vertice = Offset(-7.5, 26.5);
          _tinta.color = Colors.white.withValues(alpha: _lim(e) * alfaHaste);
          canvas.drawLine(
            Offset.lerp(const Offset(0, 43), vertice, c)!,
            Offset.lerp(const Offset(0, -43), vertice, c)!,
            _tinta,
          );
        }
      }

      canvas.restore();
    }

    // Sem direção ainda: um ponto que pulsa, "procurando"
    if (!temDirecao) {
      final r = 9 * (1 + 0.18 * sin(t * 2 * pi / 1.6));
      _tinta
        ..style = PaintingStyle.fill
        ..color = Colors.white.withValues(alpha: _lim(e * (1 - c)));
      canvas.drawCircle(centro, r, _tinta);
    }
  }

  @override
  bool shouldRepaint(_SetaPainter antigo) => antigo.temDirecao != temDirecao;
}