import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/grupos_usuario.dart';
import '../../core/widgets/avatar_perfil.dart';
import 'create_group_screen.dart';
import 'group_screen.dart';
import 'join_group_screen.dart';

const _blue = Color(0xFF0066FF);
const _blueSoft = Color(0xFF2F7BFF);
const _borda = Color(0xFFE3ECFF);
const _vermelho = Color(0xFFD32F2F);

// As três opções de filtro
enum _Filtro { todos, meus, inativos }

// O que mostrar quando a lista está vazia
enum _ModoVazio { semGrupos, semInativos, semResultado }

String _dois(int n) => n.toString().padLeft(2, '0');

String _quando(DateTime d) =>
    '${_dois(d.day)}/${_dois(d.month)}/${d.year} às ${_dois(d.hour)}:${_dois(d.minute)}';

class GroupsListScreen extends StatefulWidget {
  // Chamado pela seta de voltar (leva para a aba Início)
  final VoidCallback onVoltar;

  const GroupsListScreen({super.key, required this.onVoltar});

  @override
  State<GroupsListScreen> createState() => _GroupsListScreenState();
}

class _GroupsListScreenState extends State<GroupsListScreen> {
  final _busca = TextEditingController();
  _Filtro _filtro = _Filtro.todos;

  // O menu do botão + está aberto?
  bool _aberto = false;

  @override
  void dispose() {
    _busca.dispose();
    super.dispose();
  }

  // Evento que já passou (o grupo ainda está ativo, mas o evento acabou)
  bool _inativo(Grupo g) {
    final d = g.data;
    if (d == null) return false;
    final agora = DateTime.now();
    return d.isBefore(DateTime(agora.year, agora.month, agora.day));
  }

  // Aplica o filtro escolhido e a busca
  List<Grupo> _filtrados() {
    final termo = _busca.text.trim().toLowerCase();

    final List<Grupo> base = switch (_filtro) {
      _Filtro.todos => GruposUsuario.lista,
      // Meus grupos: apenas os criados por si (onde você é o admin)
      _Filtro.meus => GruposUsuario.lista.where((g) => g.voceEhAdmin).toList(),
      // Inativos: encerrados (ou que deixou) + eventos que já passaram
      _Filtro.inativos => [
          ...GruposUsuario.encerrados,
          ...GruposUsuario.lista.where(_inativo),
        ],
    };

    if (termo.isEmpty) return List.of(base);
    return base.where((g) => g.nome.toLowerCase().contains(termo)).toList();
  }

  // O grupo em destaque agora é o grupo ativo mais recente
  Grupo? _destaque(List<Grupo> grupos) {
    final ativos = grupos.where((g) => !_inativo(g)).toList();
    if (ativos.isEmpty) return null;
    return ativos.first;
  }

  void _abrir(Grupo g) {
    // Grupo encerrado não abre a tela do grupo: mostra um resumo
    if (g.encerradoEm != null) {
      _abrirEncerrado(g);
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => GroupScreen(grupo: g)),
    );
  }

  // Resumo de um grupo encerrado, com a opção de removê-lo do histórico
  void _abrirEncerrado(Grupo g) {
    final saiu = !g.voceEhAdmin;
    final quando = _quando(g.encerradoEm!);

    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
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
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image(
                      image: g.foto,
                      width: 66,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 66,
                        height: 60,
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
                          g.nome,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.comfortaa(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: _blue,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          saiu ? 'Você saiu em $quando' : 'Encerrado em $quando',
                          style: GoogleFonts.inter(
                            fontSize: 13.5,
                            color: const Color(0xFF6B7A99),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _LinhaInfo(Icons.location_on, g.localTexto),
              _LinhaInfo(Icons.calendar_today, g.dataTexto),
              _LinhaInfo(Icons.access_time_filled, g.horaTexto),
              const SizedBox(height: 14),
              Text(
                'Este grupo está inativo e não compartilha mais a sua localização. '
                'Você pode removê-lo do histórico.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: const Color(0xFF4A5875),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton(
                        onPressed: () async {
                          final ok = await showDialog<bool>(
                            context: ctx,
                            builder: (dctx) => AlertDialog(
                              backgroundColor: Colors.white,
                              surfaceTintColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28),
                              ),
                              title: Text(
                                'Remover do histórico?',
                                style: GoogleFonts.comfortaa(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              content: Text(
                                'O grupo, as conversas e o ponto de encontro serão apagados deste telemóvel.',
                                style: GoogleFonts.inter(fontSize: 15),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(dctx, false),
                                  child: const Text('Cancelar'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(dctx, true),
                                  child: const Text(
                                    'Remover',
                                    style: TextStyle(color: _vermelho),
                                  ),
                                ),
                              ],
                            ),
                          );
                          if (ok == true) {
                            GruposUsuario.removerDoHistorico(g);
                            if (ctx.mounted) Navigator.pop(ctx);
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: _vermelho),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          'Remover',
                          style: GoogleFonts.comfortaa(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: _vermelho,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: FilledButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: FilledButton.styleFrom(
                          backgroundColor: _blue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          'Fechar',
                          style: GoogleFonts.comfortaa(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---- Menu do botão + ----

  void _alternarMenu() => setState(() => _aberto = !_aberto);

  void _fecharMenu() {
    if (_aberto) setState(() => _aberto = false);
  }

  void _criar() {
    _fecharMenu();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateGroupScreen()),
    );
  }

  void _entrar() {
    _fecharMenu();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const JoinGroupScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: GruposUsuario.versao,
      builder: (context, _, __) {
        final grupos = _filtrados();
        final inativos = _filtro == _Filtro.inativos;
        
        // Se houver texto na busca, esconde o destaque para aparecer apenas a pesquisa
        final temBusca = _busca.text.trim().isNotEmpty;
        final destaque = (inativos || temBusca) ? null : _destaque(grupos);

        final _ModoVazio modoVazio;
        if (!inativos && GruposUsuario.lista.isEmpty) {
          modoVazio = _ModoVazio.semGrupos;
        } else if (inativos && _busca.text.trim().isEmpty) {
          modoVazio = _ModoVazio.semInativos;
        } else {
          modoVazio = _ModoVazio.semResultado;
        }

        return Scaffold(
          backgroundColor: Colors.white,
          floatingActionButton: _botaoFlutuante(),
          body: Stack(
            children: [
              Column(
                children: [
                  _cabecalho(context),
                  const SizedBox(height: 10),
                  _filtros(),
                  Expanded(
                    child: ListView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.fromLTRB(18, 12, 18, 96),
                      children: [
                        if (grupos.isEmpty)
                          _VazioLista(modo: modoVazio)
                        else ...[
                          if (destaque != null) ...[
                            const _TituloSecao('Grupos em destaque'),
                            const SizedBox(height: 10),
                            _GrupoItem(destaque,
                                onTap: () => _abrir(destaque)),
                            const SizedBox(height: 14),
                          ],
                          _TituloSecao(
                              inativos ? 'Grupos inativos' : 'Seus grupos'),
                          const SizedBox(height: 10),
                          // Exclui o destaque da lista de baixo para não duplicar
                          for (final g in grupos.where((g) => g != destaque))
                            _GrupoItem(g, onTap: () => _abrir(g)),
                        ],
                      ],
                    ),
                  ),
                ],
              ),

              // Cortina invisível: tocar fora fecha o menu
              if (_aberto)
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _fecharMenu,
                    child: Container(color: Colors.transparent),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // O botão + com as duas pílulas que aparecem acima dele
  Widget _botaoFlutuante() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        AnimatedSlide(
          offset: _aberto ? Offset.zero : const Offset(0, 0.25),
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          child: AnimatedOpacity(
            opacity: _aberto ? 1 : 0,
            duration: const Duration(milliseconds: 180),
            child: IgnorePointer(
              ignoring: !_aberto,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _PilulaAcao(texto: 'Entrar em grupo', onTap: _entrar),
                  const SizedBox(height: 7),
                  _PilulaAcao(texto: 'Criar grupo', onTap: _criar),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ),
        SizedBox(
          width: 61,
          height: 61,
          child: FloatingActionButton(
            heroTag: null,
            onPressed: _alternarMenu,
            backgroundColor: _blue,
            elevation: 4,
            shape: const CircleBorder(),
            child: AnimatedRotation(
              turns: _aberto ? 0.125 : 0,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              child: const Icon(Icons.add, color: Colors.white, size: 36),
            ),
          ),
        ),
      ],
    );
  }

  // Faixa azul com título, avatar e barra de busca
  Widget _cabecalho(BuildContext context) {
    final topo = MediaQuery.of(context).padding.top;

    return SizedBox(
      height: topo + 200,
      child: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: topo + 178,
            child: Container(
              color: _blue,
              padding: EdgeInsets.fromLTRB(26, topo + 10, 31, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Material(
                    color: Colors.white,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: widget.onVoltar,
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
                  const SizedBox(height: 9),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Grupos',
                              style: GoogleFonts.comfortaa(
                                fontSize: 32,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'Encontre grupos, participe de eventos e compartilhe sua localização',
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                color: Colors.white,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      const AvatarPerfil(),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 17,
            right: 17,
            bottom: 0,
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: _blue,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Colors.white, width: 3),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, color: Colors.white, size: 24),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _busca,
                      onChanged: (_) => setState(() {}),
                      textInputAction: TextInputAction.search,
                      cursorColor: Colors.white,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        color: Colors.white,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Buscar grupos...',
                        hintStyle: GoogleFonts.inter(
                          fontSize: 15,
                          color: Colors.white.withValues(alpha: 0.75),
                        ),
                        isCollapsed: true,
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // As três pílulas de filtro
  Widget _filtros() {
    Widget chip(String texto, _Filtro valor) {
      return Expanded(
        child: _Chip(
          texto: texto,
          selecionado: _filtro == valor,
          onTap: () => setState(() => _filtro = valor),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 19),
      child: Row(
        children: [
          chip('Todos', _Filtro.todos),
          const SizedBox(width: 7),
          chip('Meus grupos', _Filtro.meus),
          const SizedBox(width: 7),
          chip('Inativos', _Filtro.inativos),
        ],
      ),
    );
  }
}

class _PilulaAcao extends StatelessWidget {
  final String texto;
  final VoidCallback onTap;

  const _PilulaAcao({required this.texto, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 3,
      shadowColor: const Color(0x330066FF),
      shape: const StadiumBorder(side: BorderSide(color: _blue, width: 2.5)),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 134,
          height: 58,
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  texto,
                  style: GoogleFonts.comfortaa(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: _blue,
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

class _Chip extends StatelessWidget {
  final String texto;
  final bool selecionado;
  final VoidCallback onTap;

  const _Chip({
    required this.texto,
    required this.selecionado,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selecionado ? _blue : Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: selecionado ? null : Border.all(color: _borda, width: 1.5),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                texto,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: selecionado ? Colors.white : _blue,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TituloSecao extends StatelessWidget {
  final String texto;
  const _TituloSecao(this.texto);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Text(
        texto,
        style: GoogleFonts.comfortaa(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: _blue,
        ),
      ),
    );
  }
}

class _GrupoItem extends StatelessWidget {
  final Grupo grupo;
  final VoidCallback onTap;

  const _GrupoItem(this.grupo, {required this.onTap});

  @override
  Widget build(BuildContext context) {
    final encerrado = grupo.encerradoEm != null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: Colors.white,
        elevation: 2,
        shadowColor: const Color(0x1A0066FF),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            height: 97,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _borda),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image(
                    image: grupo.foto,
                    width: 85,
                    height: 76,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 85,
                      height: 76,
                      color: const Color(0xFFE8F0FF),
                      child: const Icon(Icons.groups, color: _blue),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        grupo.nome,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.comfortaa(
                          fontSize: 20,
                          fontWeight: FontWeight.w400,
                          color: encerrado
                              ? _blueSoft.withValues(alpha: 0.75)
                              : _blueSoft,
                        ),
                      ),
                      if (encerrado) ...[
                        const SizedBox(height: 6),
                        _Etiqueta(grupo.voceEhAdmin ? 'Encerrado' : 'Você saiu'),
                      ],
                    ],
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

class _Etiqueta extends StatelessWidget {
  final String texto;
  const _Etiqueta(this.texto);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF1F6),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        texto,
        style: GoogleFonts.comfortaa(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF6B7A99),
        ),
      ),
    );
  }
}

class _LinhaInfo extends StatelessWidget {
  final IconData icone;
  final String texto;

  const _LinhaInfo(this.icone, this.texto);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icone, color: _blue, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              texto,
              style: GoogleFonts.comfortaa(
                fontSize: 14.5,
                color: const Color(0xFF1B3A73),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VazioLista extends StatelessWidget {
  final _ModoVazio modo;

  const _VazioLista({required this.modo});

  @override
  Widget build(BuildContext context) {
    final (icone, titulo, texto) = switch (modo) {
      _ModoVazio.semGrupos => (
          Icons.groups_outlined,
          'Você ainda não tem grupos',
          'Toque no + para criar um grupo ou entre em um com um código.',
        ),
      _ModoVazio.semInativos => (
          Icons.inventory_2_outlined,
          'Nenhum grupo inativo',
          'Grupos encerrados e eventos que já passaram ficam guardados aqui.',
        ),
      _ModoVazio.semResultado => (
          Icons.search_off,
          'Nenhum grupo encontrado',
          'Tente outra busca ou outro filtro.',
        ),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      child: Column(
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: const BoxDecoration(
              color: Color(0xFFE8F0FF),
              shape: BoxShape.circle,
            ),
            child: Icon(icone, color: _blue, size: 48),
          ),
          const SizedBox(height: 20),
          Text(
            titulo,
            textAlign: TextAlign.center,
            style: GoogleFonts.comfortaa(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: _blue,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            texto,
            textAlign: TextAlign.center,
            style: GoogleFonts.comfortaa(
              fontSize: 15,
              fontWeight: FontWeight.w300,
              color: const Color(0xFF6B6B6B),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}