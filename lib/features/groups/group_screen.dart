import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/grupos_usuario.dart';
import '../../core/modo_teste.dart';
import '../../core/navegacao_app.dart';
import '../chat/chat_screen.dart';
import 'create_group_screen.dart';
import 'marcar_ponto_screen.dart';
import '../radar/radar_screen.dart';

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
    // Sozinho no grupo, não há ninguém para localizar
    if (!grupo.temOutrosMembros && !amigosDeTeste) {
      _aviso(
        context,
        'Você ainda está sozinho no grupo. Convide amigos para poder localizá-los.',
      );
      return;
    }
    
    // Define o grupo atual no gerenciador e empilha a tela do radar corretamente na rota do grupo
    NavegacaoApp.grupoDoRadar.value = grupo;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RadarScreen(
          onVoltar: () => Navigator.pop(context),
        ),
      ),
    );
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
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: Text(
          admin ? 'Encerrar grupo?' : 'Sair do grupo?',
          style: GoogleFonts.comfortaa(
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0066FF),
          ),
        ),
        content: Text(
          admin
              ? 'O grupo "${grupo.nome}" será encerrado para todos e ficará guardado em Inativos.'
              : 'Você deixa de compartilhar sua localização com "${grupo.nome}". O grupo ficará guardado em Inativos.',
          style: GoogleFonts.inter(
            fontSize: 15,
            color: const Color(0xFF4A5875),
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancelar',
              style: GoogleFonts.comfortaa(
                fontWeight: FontWeight.w700,
                color: const Color.fromARGB(255, 9, 9, 9),
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              admin ? 'Encerrar' : 'Sair',
              style: GoogleFonts.comfortaa(
                fontWeight: FontWeight.w700,
                color: admin ? const Color(0xFF0066FF) : const Color(0xFF0066FF),
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmou == true && context.mounted) {
      // Vai para o histórico (Inativos) em vez de ser apagado
      GruposUsuario.encerrar(grupo);
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
            // ---------------- Cabeçalho ----------------
ClipRRect(
  borderRadius: const BorderRadius.only(
    bottomLeft: Radius.circular(32),
    bottomRight: Radius.circular(32),
  ),
  child: SizedBox(
    width: double.infinity,
    child: Stack(
      children: [
        // Foto ocupando todo o cabeçalho
        Positioned.fill(
          child: Image(
            image: grupo.foto,
            fit: BoxFit.cover,
          ),
        ),

        // Desfoque
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: 10,
              sigmaY: 10,
            ),
            child: Container(
              color: Colors.transparent,
            ),
          ),
        ),

        // Camada azul para manter a identidade visual
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  _blue.withOpacity(.25),
                  _blue.withOpacity(.88),
                ],
              ),
            ),
          ),
        ),

        // Conteúdo
        Padding(
          padding: EdgeInsets.fromLTRB(
            25,
            topo + 10,
            22,
            26,
          ),
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
                      child: Icon(
                        Icons.arrow_back_ios_new,
                        size: 18,
                        color: _blue,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 34),

              Row(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: Colors.white,
                        width: 3,
                      ),
                      image: DecorationImage(
                        image: grupo.foto,
                        fit: BoxFit.cover,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 12,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 18),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          grupo.nome,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.comfortaa(
                            fontSize: 30,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            height: 1.15,
                          ),
                        ),

                        const SizedBox(height: 6),

                        Text(
                          '$n ${n == 1 ? 'membro' : 'membros'}',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.white70,
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
      ],
    ),
  ),
),

            // ---------------- Conteúdo rolável ----------------
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(17, 15, 17, 28),
                children: [
                  _DescricaoCard(
                    descricao: grupo.descricao,
                  ),
                  const SizedBox(height: 18),
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
                            ativo: grupo.temOutrosMembros || amigosDeTeste,
                            onTap: () => _localizar(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                 const SizedBox(height: 18),



const SizedBox(height: 3),

                  // Linha de ações
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        flex: 7,
                          child: _BotaoDestaque(
                          texto: grupo.ponto == null
                              ? 'Ponto\nde encontro'
                              : 'Alterar ponto\nde encontro',
                          // Abre dentro da aba, então a barra de baixo continua
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => MarcarPontoScreen(grupo: grupo),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 4,
                        child: _BotaoAcao(
                          icone: Icons.chat,
                          texto: 'Chat',
                          // O chat abre por cima da barra de baixo
                          onTap: () =>
                              Navigator.of(context, rootNavigator: true).push(
                            MaterialPageRoute(
                              builder: (_) => ChatScreen(grupo: grupo),
                            ),
                          ),
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
                              _aviso(context,
                                  'Só o administrador pode configurar o grupo.');
                              return;
                            }
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CreateGroupScreen(grupo: grupo),
                              ),
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

// Caixa azul do radar com o botão "Localizar Amigos".
// Sem amigos no grupo o botão fica com um cadeado, mas o radar continua vivo.
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
  return Material(
    color: _blue,
    borderRadius: BorderRadius.circular(12),
    child: InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: widget.onTap,
      child: SizedBox(
        height: 182,
        child: Stack(
          children: [
            // Radar ocupando TODO o card
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: RepaintBoundary(
                  child: CustomPaint(
                    painter: _RadarPainter(_volta),
                  ),
                ),
              ),
            ),

            // Botão por cima do radar
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(
                  left: 14,
                  right: 14,
                  bottom: 12,
                ),
                child: Container(
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: widget.ativo
                        ? Colors.white.withOpacity(0.96)
                        : const Color(0xFFEAF2FF).withOpacity(0.96),
                    borderRadius: BorderRadius.circular(7),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x22000000),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 10),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!widget.ativo) ...[
                            const Icon(
                              Icons.lock_outline,
                              size: 16,
                              color: _blue,
                            ),
                            const SizedBox(width: 6),
                          ],
                          Text(
                            'Localizar Amigos',
                            style: GoogleFonts.comfortaa(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: _blue,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
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

  const _BotaoDestaque({
    required this.texto,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _blue,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          height: 68,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.groups_rounded,
                color: Colors.white,
                size: 34,
              ),
              const SizedBox(height: 2),
              Text(
                texto,
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.comfortaa(
                  fontSize: 12.8,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
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
    final raio = min(size.width, size.height) * 0.69;
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

class _DescricaoCard extends StatefulWidget {
  final String descricao;

  const _DescricaoCard({
    required this.descricao,
  });

  @override
  State<_DescricaoCard> createState() => _DescricaoCardState();
}

class _DescricaoCardState extends State<_DescricaoCard> {
  bool _expandido = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
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
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            setState(() {
              _expandido = !_expandido;
            });
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.description_outlined,
                      color: _blue,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Descrição',
                        style: GoogleFonts.comfortaa(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: _blue,
                        ),
                      ),
                    ),
                    AnimatedRotation(
                      turns: _expandido ? .5 : 0,
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.easeOutCubic,
                      child: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 28,
                        color: _blue,
                      ),
                    ),
                  ],
                ),

                ClipRect(
                    child: AnimatedAlign(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                      alignment: Alignment.bottomLeft,
                      heightFactor: _expandido ? 1 : 0,
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 220),
                        opacity: _expandido ? 1 : 0,
                        curve: Curves.easeOut,
                        child: Padding(
                            padding: const EdgeInsets.only(
                              top: 14,
                              left: 4,
                              right: 4,
                            ),
                            child: Text(
                            widget.descricao.trim().isEmpty
                                ? 'Nenhuma descrição foi adicionada.'
                                : widget.descricao,
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              height: 1.55,
                              color: const Color(0xFF333333),
                            ),
                          ),
                        ),
                      ),
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