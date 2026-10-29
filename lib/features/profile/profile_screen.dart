import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/grupos_usuario.dart';
import '../../core/navegacao_app.dart';
import '../../core/perfil_usuario.dart';
import '../onboarding/welcome_screen.dart';
import '../permissions/info_screens.dart';
import 'edit_profile_screen.dart';
import 'foto_perfil.dart';

const _blue = Color(0xFF0066FF);
const _borda = Color(0xFFE3ECFF);
const _suave = Color(0xFFEAF2FF);
const _vermelho = Color(0xFFE5484D);

class PerfilScreen extends StatelessWidget {
  // Chamado pela seta de voltar (leva para a aba Início)
  final VoidCallback onVoltar;

  const PerfilScreen({super.key, required this.onVoltar});

  // ---------------- Ações ----------------

  void _trocarFoto(BuildContext context) {
    escolherFotoDoPerfil(context, (caminho) {
      PerfilUsuario.caminhoFoto = caminho;
      PerfilUsuario.avisar();
      GruposUsuario.avisar();
    });
  }

  void _abrir(BuildContext context, Widget tela) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => tela));
  }

  // Janela que sobe de baixo, com um estilo único para todas
  Future<void> _folha(
    BuildContext context, {
    required String titulo,
    required Widget Function(BuildContext ctx, StateSetter setSheet) conteudo,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(ctx).height * 0.85,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 12, 22, 20),
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
                      fontSize: 21,
                      fontWeight: FontWeight.w700,
                      color: _blue,
                    ),
                  ),
                  const SizedBox(height: 12),
                  conteudo(ctx, setSheet),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _meusCodigos(BuildContext context) {
    String? copiado; // código que acabou de ser copiado

    _folha(
      context,
      titulo: 'Códigos dos grupos',
      conteudo: (ctx, setSheet) {
        final grupos =
            GruposUsuario.lista.where((g) => g.codigo.isNotEmpty).toList();

        if (grupos.isEmpty) {
          return const _TextoSuave(
            'Você ainda não tem grupos. Quando criar um, o código dele aparece aqui.',
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _TextoSuave('Envie o código para um amigo entrar no grupo.'),
            const SizedBox(height: 8),
            for (final g in grupos)
              _LinhaCodigo(
                grupo: g,
                copiado: copiado == g.codigo,
                onCopiar: () async {
                  await Clipboard.setData(ClipboardData(text: g.codigo));
                  setSheet(() => copiado = g.codigo);
                  // Depois de 2 segundos, o ✓ volta a ser o ícone de copiar
                  Future.delayed(const Duration(seconds: 2), () {
                    copiado = null;
                    if (ctx.mounted) setSheet(() {});
                  });
                },
              ),
          ],
        );
      },
    );
  }

  void _privacidade(BuildContext context) {
    _folha(
      context,
      titulo: 'Privacidade',
      conteudo: (ctx, setSheet) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _LinhaChave(
            icone: Icons.my_location,
            titulo: 'Compartilhar minha localização',
            texto:
                'Desligado, seus amigos não conseguem ver onde você está.',
            valor: PerfilUsuario.compartilharLocalizacao,
            aoMudar: (v) {
              setSheet(() => PerfilUsuario.compartilharLocalizacao = v);
              PerfilUsuario.avisar();
            },
          ),
          const SizedBox(height: 10),
          const _TextoSuave(
            'Só participantes aprovados pelo administrador do grupo recebem as suas informações, e tudo fica salvo apenas no seu celular.',
          ),
          const SizedBox(height: 12),
          _BotaoTexto(
            texto: 'Política de privacidade',
            onTap: () {
              Navigator.pop(ctx);
              _abrir(context, const PrivacyScreen());
            },
          ),
        ],
      ),
    );
  }

  void _ajuda(BuildContext context) {
    _folha(
      context,
      titulo: 'Ajuda',
      conteudo: (ctx, setSheet) => const Column(
        children: [
          _ItemInfo(
            icone: Icons.bluetooth,
            titulo: 'Bluetooth e localização ligados',
            texto:
                'O GoFind usa os dois para achar seus amigos. Com algum deles desligado, o radar não funciona.',
          ),
          _ItemInfo(
            icone: Icons.social_distance,
            titulo: 'O alcance varia',
            texto:
                'Obstáculos, paredes e muita gente por perto podem diminuir o alcance entre os celulares.',
          ),
          _ItemInfo(
            icone: Icons.explore,
            titulo: 'Seta apontando errado?',
            texto:
                'Faça o movimento de "oito" com o celular no ar e afaste-se de metais e ímãs.',
          ),
          _ItemInfo(
            icone: Icons.battery_alert,
            titulo: 'Bateria',
            texto:
                'GPS e Bluetooth ligados o tempo todo gastam mais bateria. Em eventos longos, leve um carregador.',
          ),
        ],
      ),
    );
  }

  void _radarENavegacao(BuildContext context) {
    _folha(
      context,
      titulo: 'Radar e navegação',
      conteudo: (ctx, setSheet) => _LinhaChave(
        icone: Icons.vibration,
        titulo: 'Vibrar ao apontar para o amigo',
        texto: 'Um toque leve quando a seta fica alinhada e quando você chega.',
        valor: PerfilUsuario.vibrarAoAlinhar,
        aoMudar: (v) {
          setSheet(() => PerfilUsuario.vibrarAoAlinhar = v);
          PerfilUsuario.avisar();
        },
      ),
    );
  }

  void _sobre(BuildContext context) {
    _folha(
      context,
      titulo: 'Sobre o GoFind',
      conteudo: (ctx, setSheet) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _TextoSuave(
            'O GoFind ajuda você a encontrar seus amigos em eventos lotados, mesmo sem internet. '
            'Os celulares se conectam diretamente uns aos outros, sem servidores, e seus dados ficam só no seu aparelho.',
          ),
          const SizedBox(height: 6),
          const _TextoSuave('Projeto acadêmico de desenvolvimento mobile.'),
          const SizedBox(height: 12),
          _BotaoTexto(
            texto: 'Política de privacidade',
            onTap: () {
              Navigator.pop(ctx);
              _abrir(context, const PrivacyScreen());
            },
          ),
        ],
      ),
    );
  }

  Future<void> _sair(BuildContext context) async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Sair e apagar seus dados?',
          style: GoogleFonts.comfortaa(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Seu perfil, seus grupos e as conversas serão apagados deste celular. Isso não pode ser desfeito.',
          style: GoogleFonts.inter(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Apagar e sair',
                style: TextStyle(color: Color(0xFFD32F2F))),
          ),
        ],
      ),
    );
    if (confirmou != true || !context.mounted) return;

    PerfilUsuario.limpar();
    GruposUsuario.limparTudo(); // grupos ativos e histórico
    NavegacaoApp.grupoDoRadar.value = null;

    // Volta para a tela de boas-vindas, sem nenhuma tela anterior
    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      (rota) => false,
    );
  }

  // ---------------- Tela ----------------

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        PerfilUsuario.versao,
        GruposUsuario.versao,
      ]),
      builder: (context, _) {
        final topo = MediaQuery.of(context).padding.top;
        final nome = PerfilUsuario.nome.isEmpty ? 'amigo' : PerfilUsuario.nome;

        return Scaffold(
          backgroundColor: Colors.white,
          body: ListView(
            padding: EdgeInsets.zero,
            children: [
              _cabecalho(context, topo, nome),

              // O corpo branco sobe 26 e cobre a base do cabeçalho
              Container(
                transform: Matrix4.translationValues(0, -26, 0),
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
                ),
                child: Column(
                  children: [
                    // Atalhos
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: _borda),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x140066FF),
                            blurRadius: 12,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          _Atalho(
                            icone: Icons.edit_outlined,
                            texto: 'Editar perfil',
                            onTap: () =>
                                _abrir(context, const EditarPerfilScreen()),
                          ),
                          const SizedBox(width: 8),
                          _Atalho(
                            icone: Icons.qr_code_2,
                            texto: 'Meus códigos',
                            onTap: () => _meusCodigos(context),
                          ),
                          const SizedBox(width: 8),
                          _Atalho(
                            icone: Icons.shield_outlined,
                            texto: 'Privacidade',
                            onTap: () => _privacidade(context),
                          ),
                          const SizedBox(width: 8),
                          _Atalho(
                            icone: Icons.help_outline,
                            texto: 'Ajuda',
                            onTap: () => _ajuda(context),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Permissões
                    _CartaoLinha(
                      icone: Icons.person,
                      titulo: 'Permissões do app',
                      texto: 'Veja por que o GoFind precisa de cada permissão.',
                      onTap: () =>
                          _abrir(context, const WhyPermissionsScreen()),
                    ),
                    const SizedBox(height: 14),

                    // Configurações
                    _CartaoConfig(
                      linhas: [
                        _LinhaConfig(
                          icone: Icons.radar,
                          titulo: 'Radar e navegação',
                          texto: 'Vibração e ajustes da seta',
                          onTap: () => _radarENavegacao(context),
                        ),
                        _LinhaConfig(
                          icone: Icons.info_outline,
                          titulo: 'Sobre o GoFind',
                          texto: 'Como funciona e política de privacidade',
                          onTap: () => _sobre(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Sair
                    _CartaoSair(onTap: () => _sair(context)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Faixa azul com avatar, nome, status e frase
  Widget _cabecalho(BuildContext context, double topo, String nome) {
    final visivel = PerfilUsuario.compartilharLocalizacao;

    return ClipRect(
      child: Container(
        width: double.infinity,
        color: _blue,
        child: Stack(
          children: [
            // Círculos decorativos
            const Positioned(left: -80, top: 170, child: _Bolha(250)),
            const Positioned(right: -110, top: -20, child: _Bolha(320)),
            const Positioned(left: 60, top: 10, child: _Bolha(200)),

            // Avatar, nome, status e frase
            Padding(
              padding: EdgeInsets.fromLTRB(85,topo + 54, 0, 52),
              child: Column(
                children: [
                  SizedBox(
                    width: 120,
                    height: 120,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: GestureDetector(
                            onTap: () => _trocarFoto(context),
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: Colors.white, width: 4),
                                image: DecorationImage(
                                  image: PerfilUsuario.foto,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 6,
                          child: GestureDetector(
                            onTap: () => _trocarFoto(context),
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: _blue,
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: Colors.white, width: 3),
                              ),
                              child: const Icon(Icons.photo_camera,
                                  size: 17, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    nome,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.comfortaa(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: () => _privacidade(context),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            width: 9,
                            height: 9,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: visivel
                                  ? const Color(0xFF3CE04B)
                                  : Colors.white54,
                            ),
                          ),
                          const SizedBox(width: 7),
                          Text(
                            visivel ? 'Visível para o grupo' : 'Invisível',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (PerfilUsuario.bio.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      PerfilUsuario.bio,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Voltar e título
            Positioned(
              top: topo + 10,
              left: 15,
              child: Row(
                children: [
                  Material(
                    color: Colors.white,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: onVoltar,
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
                  const SizedBox(width: 6),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------
// Peças da tela
// ---------------------------------------------------------------

// Círculo claro decorativo do cabeçalho
class _Bolha extends StatelessWidget {
  final double tamanho;
  const _Bolha(this.tamanho);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: tamanho,
      height: tamanho,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.06),
      ),
    );
  }
}

// Um dos 4 atalhos
class _Atalho extends StatelessWidget {
  final IconData icone;
  final String texto;
  final VoidCallback onTap;

  const _Atalho({
    required this.icone,
    required this.texto,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: _suave,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 2),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                  child: Icon(icone, color: _blue, size: 22),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 32,
                  child: Center(
                    child: Text(
                      texto,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.comfortaa(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1B3A73),
                        height: 1.15,
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

// Cartão de uma linha só (Permissões do app)
class _CartaoLinha extends StatelessWidget {
  final IconData icone;
  final String titulo;
  final String texto;
  final VoidCallback onTap;

  const _CartaoLinha({
    required this.icone,
    required this.titulo,
    required this.texto,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _borda, width: 1.5),
          ),
          child: Row(
            children: [
              _IconeQuadrado(icone),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: GoogleFonts.comfortaa(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: _blue,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      texto,
                      style: GoogleFonts.comfortaa(
                        fontSize: 13,
                        fontWeight: FontWeight.w300,
                        color: const Color(0xFF6B7A99),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: _blue, size: 28),
            ],
          ),
        ),
      ),
    );
  }
}

// Quadradinho arredondado com um ícone
class _IconeQuadrado extends StatelessWidget {
  final IconData icone;
  const _IconeQuadrado(this.icone);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: _suave,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(icone, color: _blue, size: 26),
    );
  }
}

// Cartão "Configurações" com várias linhas
class _CartaoConfig extends StatelessWidget {
  final List<Widget> linhas;
  const _CartaoConfig({required this.linhas});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _borda, width: 1.5),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const _IconeQuadrado(Icons.settings),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Configurações',
                      style: GoogleFonts.comfortaa(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: _blue,
                      ),
                    ),
                    Text(
                      'Personalize sua experiência no GoFind.',
                      style: GoogleFonts.comfortaa(
                        fontSize: 13,
                        fontWeight: FontWeight.w300,
                        color: const Color(0xFF4A5875),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          for (var i = 0; i < linhas.length; i++) ...[
            linhas[i],
            if (i < linhas.length - 1)
              const Divider(height: 1, color: Color(0xFFE5E5E5)),
          ],
        ],
      ),
    );
  }
}

class _LinhaConfig extends StatelessWidget {
  final IconData icone;
  final String titulo;
  final String texto;
  final VoidCallback onTap;

  const _LinhaConfig({
    required this.icone,
    required this.titulo,
    required this.texto,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Row(
          children: [
            Icon(icone, color: _blue, size: 26),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: GoogleFonts.comfortaa(
                      fontSize: 16,
                      color: const Color(0xFF1B3A73),
                    ),
                  ),
                  Text(
                    texto,
                    style: GoogleFonts.comfortaa(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w300,
                      color: const Color(0xFF6B7A99),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: _blue, size: 26),
          ],
        ),
      ),
    );
  }
}

// Cartão vermelho "Sair e apagar meus dados"
class _CartaoSair extends StatelessWidget {
  final VoidCallback onTap;
  const _CartaoSair({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFFF1F1),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFFFD3D3), width: 1.5),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFDDDD),
                  borderRadius: BorderRadius.circular(16),
                ),
                child:
                    const Icon(Icons.logout, color: _vermelho, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sair e apagar meus dados',
                      style: GoogleFonts.comfortaa(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _vermelho,
                      ),
                    ),
                    Text(
                      'Remove seu perfil e seus grupos deste celular.',
                      style: GoogleFonts.comfortaa(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w300,
                        color: const Color(0xFF9A5A5A),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: _vermelho, size: 26),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------
// Peças das janelas que sobem de baixo
// ---------------------------------------------------------------

class _TextoSuave extends StatelessWidget {
  final String texto;
  const _TextoSuave(this.texto);

  @override
  Widget build(BuildContext context) {
    return Text(
      texto,
      style: GoogleFonts.inter(
        fontSize: 14.5,
        color: const Color(0xFF4A5875),
        height: 1.4,
      ),
    );
  }
}

class _ItemInfo extends StatelessWidget {
  final IconData icone;
  final String titulo;
  final String texto;

  const _ItemInfo({
    required this.icone,
    required this.titulo,
    required this.texto,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              color: _suave,
              shape: BoxShape.circle,
            ),
            child: Icon(icone, color: _blue, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: GoogleFonts.comfortaa(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1B3A73),
                  ),
                ),
                const SizedBox(height: 2),
                _TextoSuave(texto),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Linha com um interruptor
class _LinhaChave extends StatelessWidget {
  final IconData icone;
  final String titulo;
  final String texto;
  final bool valor;
  final ValueChanged<bool> aoMudar;

  const _LinhaChave({
    required this.icone,
    required this.titulo,
    required this.texto,
    required this.valor,
    required this.aoMudar,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: const BoxDecoration(
            color: _suave,
            shape: BoxShape.circle,
          ),
          child: Icon(icone, color: _blue, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titulo,
                style: GoogleFonts.comfortaa(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1B3A73),
                ),
              ),
              const SizedBox(height: 2),
              _TextoSuave(texto),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Switch(
          value: valor,
          onChanged: aoMudar,
          thumbColor: WidgetStateProperty.all(Colors.white),
          trackColor: WidgetStateProperty.resolveWith(
            (estados) => estados.contains(WidgetState.selected)
                ? _blue
                : const Color(0xFFBDBDBD),
          ),
          trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
        ),
      ],
    );
  }
}

class _BotaoTexto extends StatelessWidget {
  final String texto;
  final VoidCallback onTap;

  const _BotaoTexto({required this.texto, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: _blue),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(
          texto,
          style: GoogleFonts.comfortaa(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: _blue,
          ),
        ),
      ),
    );
  }
}

// Linha de um grupo na janela "Códigos dos grupos"
class _LinhaCodigo extends StatelessWidget {
  final Grupo grupo;
  final bool copiado;
  final VoidCallback onCopiar;

  const _LinhaCodigo({
    required this.grupo,
    required this.copiado,
    required this.onCopiar,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image(
              image: grupo.foto,
              width: 46,
              height: 42,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 46,
                height: 42,
                color: _suave,
                child: const Icon(Icons.groups, color: _blue),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              grupo.nome,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.comfortaa(
                fontSize: 16,
                color: const Color(0xFF1B3A73),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _blue,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              grupo.codigo,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
                color: Colors.white,
              ),
            ),
          ),
          IconButton(
            onPressed: onCopiar,
            tooltip: 'Copiar código',
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                copiado ? Icons.check_circle : Icons.copy_outlined,
                key: ValueKey(copiado),
                color: copiado ? const Color(0xFF1FAF38) : _blue,
              ),
            ),
          ),
        ],
      ),
    );
  }
}