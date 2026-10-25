import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/grupos_usuario.dart';
import '../../core/perfil_usuario.dart';
import '../groups/create_group_screen.dart';
import '../groups/join_group_screen.dart';
import '../groups/group_screen.dart';

// Cores usadas em toda esta tela
const _blue = Color(0xFF0066FF);
const _blueSoft = Color(0xFF2F7BFF);
const _borda = Color(0xFFE3ECFF);
const _gray = Color(0xFF9E9E9E);

// ---------------------------------------------------------------
// Tela principal: guarda qual aba está ativa e mostra a barra de baixo
// ---------------------------------------------------------------
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _aba = 0; // 0 = Início, 1 = Grupos, 2 = Radar, 3 = Perfil

  @override
  Widget build(BuildContext context) {
    final paginas = <Widget>[
      const _InicioTab(),
      const _EmBreve('Grupos'),
      const _EmBreve('Radar'),
      const _EmBreve('Perfil'),
    ];

    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Ícones da barra de status claros sobre o azul da aba Início
      value: _aba == 0
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: paginas[_aba],
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: Color(0xFFE5E5E5))),
          ),
          child: BottomNavigationBar(
            currentIndex: _aba,
            onTap: (i) => setState(() => _aba = i),
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            elevation: 0,
            selectedItemColor: _blue,
            unselectedItemColor: _gray,
            selectedLabelStyle: GoogleFonts.comfortaa(fontSize: 12),
            unselectedLabelStyle: GoogleFonts.comfortaa(fontSize: 12),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_rounded),
                label: 'Início',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.group),
                label: 'Grupos',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.location_on),
                label: 'Radar',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.settings_outlined),
                label: 'Perfil',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Espaço reservado para as abas que ainda vamos construir
class _EmBreve extends StatelessWidget {
  final String nome;
  const _EmBreve(this.nome);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Text(
          '$nome\n(em construção)',
          textAlign: TextAlign.center,
          style: GoogleFonts.comfortaa(fontSize: 18, color: _gray),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------
// Aba Início (a tela do Figma)
// ---------------------------------------------------------------
class _InicioTab extends StatefulWidget {
  const _InicioTab();

  @override
  State<_InicioTab> createState() => _InicioTabState();
}

class _InicioTabState extends State<_InicioTab> {
  @override
  Widget build(BuildContext context) {
    // Nome digitado no cadastro (se entrou pelo login, ainda não temos o nome)
    final nome = PerfilUsuario.nome.isEmpty ? 'amigo' : PerfilUsuario.nome;

    // Grupos do usuário: vazia na primeira vez que o app é aberto
    final grupos = GruposUsuario.lista;

    return Stack(
      children: [
        // Fundo azul do topo (fica atrás de tudo)
        Container(height: 202, color: _blue),

        // Parte fixa + lista rolável
        Column(
          children: [
            // Cabeçalho: saudação + avatar (fixo)
            Padding(
              padding: const EdgeInsets.fromLTRB(26, 78, 31, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Olá, $nome',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.comfortaa(
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Vamos encontrar seus amigos?',
                          style: GoogleFonts.comfortaa(
                            fontSize: 15,
                            fontWeight: FontWeight.w300,
                            color: Colors.white,
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
            ),

            const SizedBox(height: 39),

            // Painel branco: ocupa todo o espaço que sobra até a barra de baixo
            Expanded(
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 15),
                padding: const EdgeInsets.fromLTRB(14, 9, 14, 0),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  children: [
                    // Os dois cartões de ação (fixos)
                    Row(
                      children: [
                        Expanded(
                          child: _CardAcao(
                            destaque: true,
                            icone: Container(
                              width: 32,
                              height: 32,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.add,
                                  color: _blue, size: 26),
                            ),
                            titulo: 'Criar Grupo',
                            texto:
                                'Monte seu grupo e comece a compartilhar sua localização.',
                            onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const CreateGroupScreen()),
                                );
                                // Ao voltar, redesenha a Home para mostrar o grupo novo
                                if (mounted) setState(() {});
                              },
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: _CardAcao(
                            destaque: false,
                            icone: const Icon(Icons.groups,
                                color: _blue, size: 36),
                            titulo: 'Entrar em Grupo',
                            texto:
                                'Já tem um código? Entre no grupo e seja encontrado',
                            onTap: () async {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (_) => const JoinGroupScreen()),
                                      );
                                      // Ao voltar, redesenha a Home (caso um grupo tenha sido criado no caminho)
                                      if (mounted) setState(() {});
                                    },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    // Sem grupos: estado vazio. Com grupos: título fixo + lista rolável
                    if (grupos.isEmpty)
                      const Expanded(
                        child: SingleChildScrollView(child: _EstadoVazio()),
                      )
                    else ...[
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 2),
                          child: Text(
                            'Grupos recentes',
                            style: GoogleFonts.comfortaa(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: _blue,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 11),

                      // Só esta parte rola
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(2, 4, 2, 16),
                          children: [
                            for (final g in grupos)
                                _GrupoTile(
                                  g,
                                  onVoltar: () {
                                    // Redesenha a Home ao voltar (o grupo pode ter sido encerrado)
                                    if (mounted) setState(() {});
                                  },
                                ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// Cartão grande: "Criar Grupo" (azul) e "Entrar em Grupo" (branco)
class _CardAcao extends StatelessWidget {
  final bool destaque;
  final Widget icone;
  final String titulo;
  final String texto;
  final VoidCallback onTap;

  const _CardAcao({
    required this.destaque,
    required this.icone,
    required this.titulo,
    required this.texto,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final corTexto = destaque ? Colors.white : _blue;

    return Material(
      color: destaque ? _blue : Colors.white,
      elevation: destaque ? 0 : 2,
      shadowColor: const Color(0x1A0066FF),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          height: 186,
          padding: const EdgeInsets.fromLTRB(20, 28, 12, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: destaque ? null : Border.all(color: _borda),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 36, child: icone),
              const SizedBox(height: 10),
              Text(
                titulo,
                style: GoogleFonts.comfortaa(
                  fontSize: 17,
                  fontWeight: FontWeight.w400,
                  color: corTexto,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                texto,
                style: GoogleFonts.comfortaa(
                  fontSize: 13,
                  fontWeight: FontWeight.w300,
                  color: corTexto,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Linha da lista "Grupos recentes": miniatura + nome
class _GrupoTile extends StatelessWidget {
  final Grupo grupo;
  final VoidCallback onVoltar;
  const _GrupoTile(this.grupo, {required this.onVoltar});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.white,
        elevation: 2,
        shadowColor: const Color(0x1A0066FF),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => GroupScreen(grupo: grupo)),
              );
              onVoltar();
            },
          child: Container(
            height: 85,
            padding: const EdgeInsets.fromLTRB(10, 7, 10, 8),
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
                            width: 72,
                            height: 70,
                            fit: BoxFit.cover,
                            // Se a imagem não existir, mostra um ícone
                            errorBuilder: (_, __, ___) => Container(
                              width: 72,
                              height: 70,
                              color: const Color(0xFFE8F0FF),
                              child: const Icon(Icons.groups, color: _blue),
                            ),
                          ),
                        ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    grupo.nome,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.comfortaa(
                      fontSize: 19,
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

// Aparece no lugar da lista quando o usuário não tem grupos
class _EstadoVazio extends StatelessWidget {
  const _EstadoVazio();

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
            child: const Icon(Icons.groups_outlined, color: _blue, size: 48),
          ),
          const SizedBox(height: 20),
          Text(
            'Você ainda não tem grupos',
            textAlign: TextAlign.center,
            style: GoogleFonts.comfortaa(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: _blue,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Crie um grupo ou entre com um código para encontrar seus amigos.',
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