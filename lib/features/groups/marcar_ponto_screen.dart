import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/grupos_usuario.dart';
import '../../core/modo_teste.dart';
import '../radar/radar_screen.dart' show RadarView;

const _blue = Color(0xFF0066FF);
const _azulEscuro = Color(0xFF0050D6);
const _borda = Color(0xFFE3ECFF);
const _halo = Color(0xFFD1E3FB);

class MarcarPontoScreen extends StatefulWidget {
  final Grupo grupo;
  const MarcarPontoScreen({super.key, required this.grupo});

  @override
  State<MarcarPontoScreen> createState() => _MarcarPontoScreenState();
}

class _MarcarPontoScreenState extends State<MarcarPontoScreen>
    with SingleTickerProviderStateMixin {
  // O grupo já tinha um ponto quando a tela abriu? (então é "Alterar")
  late final bool _atualizando;

  // Já marcou nesta visita? (mostra o cartão de sucesso)
  bool _marcado = false;

  // Pulso lento do halo da bandeira
  late final AnimationController _pulso = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat(reverse: true);

  Grupo get _grupo => widget.grupo;

  // Amigos que aparecem no radar (inclui os de teste)
  List<Membro> get _amigos => amigosDeTeste
      ? amigosFicticios
      : _grupo.membros.where((m) => !m.ehVoce).toList();

  @override
  void initState() {
    super.initState();
    _atualizando = _grupo.ponto != null;
  }

  @override
  void dispose() {
    _pulso.dispose();
    super.dispose();
  }

  void _marcar() {
    // As coordenadas virão do GPS, na etapa de localização
    _grupo.ponto = PontoEncontro(criadoPor: 'Você');

    // Aviso azul no chat do grupo
    _grupo.mensagens.add(Mensagem(
      autor: 'Você',
      ehVoce: true,
      tipo: TipoMensagem.sistema,
      texto: _atualizando
          ? 'Você atualizou o ponto de encontro'
          : 'Você compartilhou um ponto de encontro',
    ));

    HapticFeedback.mediumImpact();

    // Avisa as outras telas (o botão do grupo passa a dizer "Alterar")
    GruposUsuario.avisar();

    setState(() => _marcado = true);
  }

 Future<void> _removerPonto() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: const Color.fromARGB(255, 250, 249, 249), // Remove o tom roxo padrão do Material 3
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28), // Bordas bem arredondadas
        ),
        titlePadding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
        contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        title: Text(
          'Remover ponto?',
          style: GoogleFonts.comfortaa(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1E1E1E), // Texto bem escuro
          ),
        ),
        content: Text(
          'O ponto de encontro atual será apagado e deixará de aparecer no radar de todos do grupo.',
          style: GoogleFonts.inter(
            fontSize: 15,
            height: 1.4,
            color: const Color(0xFF4A4A4A), // Cinza escuro para leitura
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancelar',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: const Color.fromARGB(255, 6, 6, 6), // Tom roxo/lilás da imagem
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Remover',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: _azulEscuro, // Tom vermelho
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmar == true && mounted) {
      // Remove o ponto do grupo
      _grupo.ponto = null;

      // Adiciona o aviso no chat
      _grupo.mensagens.add(Mensagem(
        autor: 'Você',
        ehVoce: true,
        tipo: TipoMensagem.sistema,
        texto: 'Você removeu o ponto de encontro',
      ));

      HapticFeedback.mediumImpact();
      
      // Avisa as outras telas para se redesenharem
      GruposUsuario.avisar();

      // Volta para a tela do grupo
      Navigator.pop(context);
    }
  }

  String get _textoSucesso {
    final n = _amigos.length;
    if (n == 0) {
      return 'Salvo no grupo. Seus amigos vão ver o ponto quando entrarem.';
    }
    return 'Compartilhado com $n ${n == 1 ? 'amigo' : 'amigos'}. '
        'Eles já podem ver a distância e a direção até você.';
  }

  @override
  Widget build(BuildContext context) {
    final topo = MediaQuery.of(context).padding.top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Fundo branco: ícones escuros na barra de status
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            // Cabeçalho: voltar, título e subtítulo
            Padding(
              padding: EdgeInsets.fromLTRB(12, topo + 10, 15, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Material(
                    color: _blue,
                    shape: const CircleBorder(),
                    elevation: 3,
                    shadowColor: const Color(0x440066FF),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => Navigator.pop(context),
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
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          _atualizando ? 'Alterar ponto' : 'Marcar ponto',
                          style: GoogleFonts.comfortaa(
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            color: _blue,
                          ),
                        ),
                        Text(
                          _atualizando
                              ? 'Sua localização será o novo ponto de encontro'
                              : 'Sua localização será o ponto de encontro',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            color: _blue,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // O radar ocupa o espaço que sobra e se ajusta ao tamanho da tela
            Expanded(
              child: LayoutBuilder(
                builder: (context, c) {
                  final lado =
                      max(120.0, min(c.maxWidth - 62, c.maxHeight - 20));
                  return Center(
                    child: SizedBox(
                      width: lado,
                      height: lado,
                      child: RadarView(amigos: _amigos),
                    ),
                  );
                },
              ),
            ),

            // Cartão de baixo: pergunta ou confirmação
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(27, 20, 27, 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(28)),
                border: Border.all(color: _borda, width: 1.5),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x120066FF),
                    blurRadius: 16,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              // O cartão muda de altura e de conteúdo com suavidade
              child: AnimatedSize(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOutCubic,
                alignment: Alignment.bottomCenter,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 450),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeIn,
                  transitionBuilder: (filho, anim) => FadeTransition(
                    opacity: anim,
                    child: ScaleTransition(
                      scale: Tween<double>(begin: 0.96, end: 1).animate(anim),
                      child: filho,
                    ),
                  ),
                  child: _marcado ? _sucesso() : _pergunta(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Antes de marcar
  Widget _pergunta() {
    return Column(
      key: const ValueKey('pergunta'),
      mainAxisSize: MainAxisSize.min,
      children: [
        _IconeBandeira(pulso: _pulso, sucesso: false),
        const SizedBox(height: 10),
        Text(
          _atualizando ? 'Alterar ponto de encontro' : 'Marcar ponto de encontro',
          textAlign: TextAlign.center,
          style: GoogleFonts.comfortaa(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: _azulEscuro,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _atualizando
              ? 'O ponto atual será substituído pela sua localização de agora '
                  'e compartilhado com todos do grupo.'
              : 'O ponto de encontro será salvo com base na sua localização '
                  'atual e compartilhado com todos do grupo. Os demais '
                  'participantes poderão ver a distância e a direção até o local.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 13.5,
            color: _azulEscuro,
            height: 1.25,
          ),
        ),
        const SizedBox(height: 16),
        _BotaoAzul(
          texto: _atualizando ? 'Atualizar ponto' : 'Marcar ponto',
          onPressed: _marcar,
        ),
        
        // --- NOVO BOTÃO DE REMOVER AQUI ---
        if (_atualizando) ...[
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: _removerPonto,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              // Desenha o retângulo vermelho em volta do botão
              side: const BorderSide(
                color: _azulEscuro, // Mesma cor vermelha do texto
                width: 1.5, // Espessura da linha
              ),
              // Faz as pontas do retângulo ficarem redondas
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14), 
              ),
            ),
            child: Text(
              'Remover ponto atual',
              style: GoogleFonts.comfortaa(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: _azulEscuro,
              ),
            ),
          ),
        ],
        // ----------------------------------
      ],
    );
  }

  // Depois de marcar
  Widget _sucesso() {
    return Column(
      key: const ValueKey('sucesso'),
      mainAxisSize: MainAxisSize.min,
      children: [
        _IconeBandeira(pulso: _pulso, sucesso: true),
        const SizedBox(height: 10),
        Text(
          _atualizando ? 'Ponto atualizado!' : 'Ponto de encontro marcado!',
          textAlign: TextAlign.center,
          style: GoogleFonts.comfortaa(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: _azulEscuro,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _textoSucesso,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 13.5,
            color: _azulEscuro,
            height: 1.25,
          ),
        ),
        const SizedBox(height: 16),
        _BotaoAzul(
          texto: 'Concluir',
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }
}

// A bandeira dentro de um círculo azul, com um halo que pulsa de leve.
// No sucesso, vira um ✓ que "quica" ao aparecer.
class _IconeBandeira extends StatelessWidget {
  final Animation<double> pulso;
  final bool sucesso;

  const _IconeBandeira({required this.pulso, required this.sucesso});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      height: 72,
      child: Center(
        child: AnimatedBuilder(
          animation: pulso,
          builder: (context, filho) {
            final p = Curves.easeInOut.transform(pulso.value);
            return Transform.scale(scale: 1 + 0.09 * p, child: filho);
          },
          child: Container(
            width: 63,
            height: 63,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: _halo,
              shape: BoxShape.circle,
            ),
            child: TweenAnimationBuilder<double>(
              // No sucesso o círculo cresce com um "quique"; antes, já aparece pronto
              tween: Tween<double>(begin: sucesso ? 0 : 1, end: 1),
              duration: const Duration(milliseconds: 700),
              curve: Curves.elasticOut,
              builder: (context, v, _) => Transform.scale(
                scale: v,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: _blue,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    sucesso ? Icons.check_rounded : Icons.flag_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Botão azul de largura total
class _BotaoAzul extends StatelessWidget {
  final String texto;
  final VoidCallback onPressed;

  const _BotaoAzul({required this.texto, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 51,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: _blue,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(
          texto,
          style: GoogleFonts.comfortaa(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}