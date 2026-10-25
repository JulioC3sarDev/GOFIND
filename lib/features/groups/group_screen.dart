import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/grupos_usuario.dart';
import 'dart:math';
import 'create_group_screen.dart';

const _blue = Color(0xFF0066FF);
const _borda = Color(0xFFE3ECFF);
const _gray = Color(0xFF8A8A8A);
const _green = Color(0xFF1FAF38);

class GroupScreen extends StatelessWidget {
  final Grupo grupo;
  const GroupScreen({super.key, required this.grupo});

  void _aviso(BuildContext context, String texto) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(texto)));
  }

  void _emBreve(BuildContext context, String nome) =>
      _aviso(context, '$nome: em breve');

  void _localizar(BuildContext context) {
    if (!grupo.temOutrosMembros) {
      _aviso(
        context,
        'Você ainda está sozinho no grupo. Convide amigos para poder localizá-los.',
      );
      return;
    }
    _emBreve(context, 'Localizar Amigos');
  }

  Future<void> _convidar(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: grupo.codigo));
    if (!context.mounted) return;
    _aviso(context, 'Código ${grupo.codigo} copiado. Envie para seus amigos!');
  }

  Future<void> _encerrar(BuildContext context) async {
    final admin = grupo.voceEhAdmin;

    final confirmou = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          admin ? 'Encerrar grupo?' : 'Sair do grupo?',
          style: GoogleFonts.comfortaa(fontWeight: FontWeight.w700),
        ),
        content: Text(
          admin
              ? 'O grupo "${grupo.nome}" será apagado e deixará de existir para todos.'
              : 'Você deixará de compartilhar sua localização com este grupo.',
          style: GoogleFonts.inter(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              admin ? 'Encerrar' : 'Sair',
              style: const TextStyle(color: Color(0xFFD32F2F)),
            ),
          ),
        ],
      ),
    );

    if (confirmou == true && context.mounted) {
      GruposUsuario.remover(grupo);
      Navigator.pop(context);
    }
  }

    @override
  Widget build(BuildContext context) {
    // Redesenha quando o grupo for editado na tela Configurar
    return ValueListenableBuilder<int>(
      valueListenable: GruposUsuario.versao,
      builder: (context, _, __) => _conteudo(context),
    );
  }

  Widget _conteudo(BuildContext context) {
    final topo = MediaQuery.of(context).padding.top;
    final n = grupo.membros.length;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            // ---------------- Cabeçalho azul ----------------
            Container(
              width: double.infinity,
              color: _blue,
              padding: EdgeInsets.fromLTRB(25, topo + 10, 20, 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Material(
                    color: Colors.white,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => Navigator.pop(context),
                      child: const SizedBox(
                        width: 42,
                        height: 42,
                        child: Center(
                          child: Icon(Icons.arrow_back_ios_new,
                              size: 18, color: _blue),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 38),
                  Row(
                    children: [
                      Container(
                        width: 107,
                        height: 102,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white, width: 2),
                          image: DecorationImage(
                            image: grupo.foto,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              grupo.nome,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.comfortaa(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                height: 1.15,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$n ${n == 1 ? 'membro' : 'membros'}',
                              style: GoogleFonts.comfortaa(
                                fontSize: 17,
                                fontWeight: FontWeight.w400,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ---------------- Conteúdo rolável ----------------
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(17, 15, 17, 28),
                children: [
                  // Cartão: local, data, horário + Localizar Amigos
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _borda),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x140066FF),
                          blurRadius: 10,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          flex: 8,
                          child: Column(
                            children: [
                              _InfoLinha(
                                icone: Icons.location_on,
                                titulo: 'Local',
                                valor: grupo.localTexto,
                              ),
                              _InfoLinha(
                                icone: Icons.calendar_today,
                                titulo: 'Data',
                                valor: grupo.dataTexto,
                              ),
                              _InfoLinha(
                                icone: Icons.access_time_filled,
                                titulo: 'Horário',
                                valor: grupo.horaTexto,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 11,
                          child: _LocalizarCard(
                            ativo: grupo.temOutrosMembros,
                            onTap: () => _localizar(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Linha de ações
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        flex: 7,
                        child: _BotaoDestaque(
                          texto: 'Marcar ponto\nde encontro',
                          onTap: () => _emBreve(context, 'Marcar ponto de encontro'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 4,
                        child: _BotaoAcao(
                          icone: Icons.chat,
                          texto: 'Chat',
                          onTap: () => _emBreve(context, 'Chat'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 4,
                        child: _BotaoAcao(
                          icone: Icons.share,
                          texto: 'Convidar amigos',
                          onTap: () => _convidar(context),
                        ),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        flex: 5,
                        child: _BotaoAcao(
                          icone: Icons.settings,
                          texto: 'Configurar',
                          onTap: () {
                            if (!grupo.voceEhAdmin) {
                              _aviso(context, 'Só o administrador pode configurar o grupo.');
                              return;
                            }
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => CreateGroupScreen(grupo: grupo)),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // Título "Membros do grupo"
                  InkWell(
                    onTap: () => _emBreve(context, 'Lista de membros'),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Membros do grupo',
                              style: GoogleFonts.comfortaa(
                                fontSize: 21,
                                fontWeight: FontWeight.w700,
                                color: _blue,
                              ),
                            ),
                          ),
                          const Icon(Icons.chevron_right,
                              color: _blue, size: 30),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Avatares dos membros (rola para o lado quando houver muitos)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final m in grupo.membros) _MembroItem(m),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Encerrar (administrador) ou sair (demais membros)
                  SizedBox(
                    height: 57,
                    child: FilledButton(
                      onPressed: () => _encerrar(context),
                      style: FilledButton.styleFrom(
                        backgroundColor: _blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        grupo.voceEhAdmin ? 'Encerrar grupo' : 'Sair do grupo',
                        style: GoogleFonts.comfortaa(
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Linha "ícone + título + valor" do cartão de informações
class _InfoLinha extends StatelessWidget {
  final IconData icone;
  final String titulo;
  final String valor;

  const _InfoLinha({
    required this.icone,
    required this.titulo,
    required this.valor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
              color: _blue,
              shape: BoxShape.circle,
            ),
            child: Icon(icone, color: Colors.white, size: 17),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  titulo,
                  style: GoogleFonts.comfortaa(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _blue,
                  ),
                ),
                Text(
                  valor,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.comfortaa(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF333333),
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

// Caixa azul do radar com o botão "Localizar Amigos"
// Quando não está ativa (grupo sem outros membros), fica apagada
// Caixa azul do radar com o botão "Localizar Amigos"
// Quando não está ativa (grupo sem outros membros), fica apagada
class _LocalizarCard extends StatefulWidget {
  final bool ativo;
  final VoidCallback onTap;

  const _LocalizarCard({required this.ativo, required this.onTap});

  @override
  State<_LocalizarCard> createState() => _LocalizarCardState();
}

class _LocalizarCardState extends State<_LocalizarCard>
    with SingleTickerProviderStateMixin {
  // Relógio que vai de 0 a 1 e recomeça: uma volta completa do radar
  late final AnimationController _volta = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3600),
  )..repeat();

  @override
  void dispose() {
    _volta.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: widget.ativo ? 1 : 0.5,
      child: Material(
        color: _blue,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: widget.onTap,
          child: SizedBox(
            height: 182,
            child: Column(
              children: [
                const SizedBox(height: 16),

                // O radar animado
                RepaintBoundary(
                  child: SizedBox(
                    width: 116,
                    height: 116,
                    child: CustomPaint(painter: _RadarPainter(_volta)),
                  ),
                ),

                const Spacer(),
                Container(
                  height: 32,
                  margin: const EdgeInsets.symmetric(horizontal: 14),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        'Localizar Amigos',
                        style: GoogleFonts.comfortaa(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: _blue,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Botão azul grande: "Marcar ponto de encontro"
class _BotaoDestaque extends StatelessWidget {
  final String texto;
  final VoidCallback onTap;

  const _BotaoDestaque({required this.texto, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _blue,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: SizedBox(
          height: 68,
          child: Center(
            child: Text(
              texto,
              textAlign: TextAlign.center,
              style: GoogleFonts.comfortaa(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                height: 1.2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Botões brancos pequenos: Chat, Convidar amigos, Configurar
class _BotaoAcao extends StatelessWidget {
  final IconData icone;
  final String texto;
  final VoidCallback onTap;

  const _BotaoAcao({
    required this.icone,
    required this.texto,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 1.5,
      shadowColor: const Color(0x330066FF),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          height: 68,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _borda),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icone, color: _blue, size: 26),
              const SizedBox(height: 3),
              Text(
                texto,
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.comfortaa(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: _blue,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Um membro na fileira de avatares
class _MembroItem extends StatelessWidget {
  final Membro membro;
  const _MembroItem(this.membro);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: SizedBox(
        width: 96,
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: membro.ehVoce
                        ? Border.all(color: _blue, width: 2.5)
                        : null,
                    image: DecorationImage(
                      image: membro.foto,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                if (membro.admin)
                  Positioned(
                    left: -4,
                    top: -4,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: _blue,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(Icons.workspace_premium,
                          size: 13, color: Colors.white),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              membro.ehVoce ? 'Você' : membro.nome,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.comfortaa(
                fontSize: 17,
                fontWeight: FontWeight.w400,
                color: _blue,
              ),
            ),
            const SizedBox(height: 3),
            if (membro.admin)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: _blue,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  'Administrador',
                  style: GoogleFonts.comfortaa(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              )
            else
              Text(
                membro.online ? 'Online' : 'Offline',
                style: GoogleFonts.comfortaa(
                  fontSize: 11.5,
                  color: membro.online ? _green : _gray,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Desenha o radar de sonar. É redesenhado a cada quadro da animação.
class _RadarPainter extends CustomPainter {
  final Animation<double> animacao;

  _RadarPainter(this.animacao) : super(repaint: animacao);

  // Tamanho do rastro da varredura, em radianos (cerca de 75 graus)
  static const _rastro = 1.3;

  @override
  void paint(Canvas canvas, Size size) {
    final centro = size.center(Offset.zero);
    final raio = size.shortestSide / 2;
    final t = animacao.value; // 0 a 1, uma volta
    final angulo = t * 2 * pi; // para onde a linha aponta agora

    final disco = Rect.fromCircle(center: centro, radius: raio);

    // Fundo do disco, um azul um pouco mais escuro que a caixa
    canvas.drawCircle(centro, raio, Paint()..color = const Color(0xFF0050D6));

    // Tudo abaixo fica recortado dentro do disco
    canvas.save();
    canvas.clipPath(Path()..addOval(disco));

    // Cruz e anéis de distância
    final linha = Paint()
      ..color = Colors.white.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    canvas.drawLine(Offset(centro.dx - raio, centro.dy),
        Offset(centro.dx + raio, centro.dy), linha);
    canvas.drawLine(Offset(centro.dx, centro.dy - raio),
        Offset(centro.dx, centro.dy + raio), linha);
    canvas.drawCircle(centro, raio / 3, linha);
    canvas.drawCircle(centro, raio * 2 / 3, linha);

    // Pulso (ping): um anel que nasce no centro e se apaga ao chegar na borda
    canvas.drawCircle(
      centro,
      raio * t,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.35 * (1 - t))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Rastro da varredura: uma "fatia" que vai de transparente a branco
    final rastro = Paint()
      ..shader = SweepGradient(
        startAngle: 0,
        endAngle: _rastro,
        colors: [
          Colors.white.withValues(alpha: 0),
          Colors.white.withValues(alpha: 0.6),
        ],
        transform: GradientRotation(angulo - _rastro),
      ).createShader(disco);
    canvas.drawArc(disco, angulo - _rastro, _rastro, true, rastro);

    // Linha brilhante na frente da varredura
    canvas.drawLine(
      centro,
      Offset(centro.dx + raio * cos(angulo), centro.dy + raio * sin(angulo)),
      Paint()
        ..color = Colors.white
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );

    canvas.restore();

    // Borda do disco e ponto central (você)
    canvas.drawCircle(
      centro,
      raio - 0.75,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    canvas.drawCircle(centro, 4, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(_RadarPainter antigo) => antigo.animacao != animacao;
}