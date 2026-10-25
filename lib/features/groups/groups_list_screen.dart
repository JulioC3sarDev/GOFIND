import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/grupos_usuario.dart';
import 'create_group_screen.dart';
import 'group_screen.dart';

const _blue = Color(0xFF0066FF);
const _blueSoft = Color(0xFF2F7BFF);
const _borda = Color(0xFFE3ECFF);

// As três opções de filtro
enum _Filtro { todos, meus, inativos }

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

  @override
  void dispose() {
    _busca.dispose();
    super.dispose();
  }

  // Inativo = o evento já passou
  bool _inativo(Grupo g) {
    final d = g.data;
    if (d == null) return false;
    final agora = DateTime.now();
    return d.isBefore(DateTime(agora.year, agora.month, agora.day));
  }

  // Aplica a busca e o filtro escolhido
  List<Grupo> _filtrados() {
    final termo = _busca.text.trim().toLowerCase();

    return GruposUsuario.lista.where((g) {
      if (termo.isNotEmpty && !g.nome.toLowerCase().contains(termo)) {
        return false;
      }
      switch (_filtro) {
        case _Filtro.todos:
          return true;
        case _Filtro.meus:
          return g.voceEhAdmin;
        case _Filtro.inativos:
          return _inativo(g);
      }
    }).toList();
  }

  // O grupo com o evento mais próximo (de hoje em diante)
  Grupo? _destaque(List<Grupo> grupos) {
    final futuros = grupos.where((g) => g.data != null && !_inativo(g)).toList()
      ..sort((a, b) => a.data!.compareTo(b.data!));
    return futuros.isEmpty ? null : futuros.first;
  }

  void _abrir(Grupo g) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => GroupScreen(grupo: g)),
    );
  }

  void _criar() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateGroupScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Redesenha sozinha quando a lista de grupos mudar
    return ValueListenableBuilder<int>(
      valueListenable: GruposUsuario.versao,
      builder: (context, _, __) {
        final grupos = _filtrados();
        final destaque =
            _filtro == _Filtro.inativos ? null : _destaque(grupos);

        return Scaffold(
          backgroundColor: Colors.white,
          floatingActionButton: SizedBox(
            width: 61,
            height: 61,
            child: FloatingActionButton(
              heroTag: null,
              onPressed: _criar,
              backgroundColor: _blue,
              elevation: 4,
              shape: const CircleBorder(),
              child: const Icon(Icons.add, color: Colors.white, size: 36),
            ),
          ),
          body: Column(
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
                      _VazioLista(semNenhumGrupo: GruposUsuario.lista.isEmpty)
                    else ...[
                      if (destaque != null) ...[
                        const _TituloSecao('Grupos em destaque'),
                        const SizedBox(height: 10),
                        _GrupoItem(destaque, onTap: () => _abrir(destaque)),
                        const SizedBox(height: 14),
                      ],
                      const _TituloSecao('Seus grupos'),
                      const SizedBox(height: 10),
                      for (final g in grupos)
                        _GrupoItem(g, onTap: () => _abrir(g)),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Faixa azul com título, avatar e a barra de busca por cima da borda
  Widget _cabecalho(BuildContext context) {
    final topo = MediaQuery.of(context).padding.top;

    return SizedBox(
      height: topo + 200,
      child: Stack(
        children: [
          // Fundo azul
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
                      Container(
                        width: 55,
                        height: 55,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          image: const DecorationImage(
                            image: AssetImage('assets/images/placeholder.png'),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Barra de busca: azul com contorno branco, metade sobre o azul
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

// Pílula de filtro: azul quando selecionada, branca com borda quando não
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

// Título de seção: "Grupos em destaque" e "Seus grupos"
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

// Cartão de um grupo: miniatura + nome
class _GrupoItem extends StatelessWidget {
  final Grupo grupo;
  final VoidCallback onTap;

  const _GrupoItem(this.grupo, {required this.onTap});

  @override
  Widget build(BuildContext context) {
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
                  child: Text(
                    grupo.nome,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.comfortaa(
                      fontSize: 20,
                      fontWeight: FontWeight.w400,
                      color: _blueSoft,
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

// Aparece quando não há nada para listar
class _VazioLista extends StatelessWidget {
  final bool semNenhumGrupo; // true = o usuário não tem grupo algum

  const _VazioLista({required this.semNenhumGrupo});

  @override
  Widget build(BuildContext context) {
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
            child: Icon(
              semNenhumGrupo ? Icons.groups_outlined : Icons.search_off,
              color: _blue,
              size: 48,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            semNenhumGrupo
                ? 'Você ainda não tem grupos'
                : 'Nenhum grupo encontrado',
            textAlign: TextAlign.center,
            style: GoogleFonts.comfortaa(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: _blue,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            semNenhumGrupo
                ? 'Toque no + para criar um grupo ou entre em um com um código.'
                : 'Tente outra busca ou outro filtro.',
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