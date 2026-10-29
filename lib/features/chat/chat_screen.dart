import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/grupos_usuario.dart';
import '../../core/modo_teste.dart';
import '../../core/radar/seguir_screen.dart';
import '../../core/perfil_usuario.dart';

const _blue = Color(0xFF0066FF);
const _bolhaOutros = Color(0xFFD9E6FB);
const _borda = Color(0xFFE3ECFF);
const _cinza = Color(0xFFD0D0D0);
const _vermelho = Color(0xFFD32F2F);
const _navy = Color(0xFF2B3A67);

String _dois(int n) => n.toString().padLeft(2, '0');
String _hhmm(DateTime d) => '${_dois(d.hour)}:${_dois(d.minute)}';

class ChatScreen extends StatefulWidget {
  final Grupo grupo;
  const ChatScreen({super.key, required this.grupo});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _texto = TextEditingController();
  final _rolagem = ScrollController();

  Grupo get _grupo => widget.grupo;

  @override
  void dispose() {
    _texto.dispose();
    _rolagem.dispose();
    super.dispose();
  }

  // Adiciona uma mensagem e rola até o fim da conversa
  void _adicionar(Mensagem m) {
    setState(() => _grupo.mensagens.add(m));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_rolagem.hasClients) {
        _rolagem.animateTo(
          0, // lista invertida: 0 é o fim da conversa
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _enviar() {
    final texto = _texto.text.trim();
    if (texto.isEmpty) return;
    _adicionar(Mensagem(autor: 'Você', ehVoce: true, texto: texto));
    _texto.clear();
  }

  void _estouPerdido() {
    _adicionar(Mensagem(
      autor: 'Você',
      ehVoce: true,
      tipo: TipoMensagem.perdido,
      texto: 'não estou conseguindo achar o grupo',
    ));
  }

  Future<void> _limpar() async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Limpar conversa?',
          style: GoogleFonts.comfortaa(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'As mensagens deste grupo serão apagadas do seu celular.',
          style: GoogleFonts.inter(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Limpar', style: TextStyle(color: _vermelho)),
          ),
        ],
      ),
    );
    if (confirmou == true && mounted) {
      setState(() => _grupo.mensagens.clear());
    }
  }

    // "Ir até mim" no alerta de um amigo: abre a tela de seguir
  void _irAteMim(Mensagem m) {
    void aviso(String texto) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(texto)));
    }

    // O alerta é seu: ninguém precisa seguir você mesmo
    if (m.ehVoce) {
      aviso('Este é o seu alerta. Seus amigos vão poder vir até você.');
      return;
    }

    // Procura o amigo pelo nome (inclui os amigos de teste)
    final candidatos = [
      ..._grupo.membros,
      if (amigosDeTeste) ...amigosFicticios,
    ];
    final amigo = candidatos.where((x) => x.nome == m.autor).firstOrNull;
    if (amigo == null) {
      aviso('Não encontrei ${m.autor} neste grupo.');
      return;
    }

    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(builder: (_) => SeguirScreen(amigo: amigo)),
    );
  }

  // "Hoje", "Ontem" ou a data
  String _rotuloDia(DateTime dia) {
    final agora = DateTime.now();
    final hoje = DateTime.utc(agora.year, agora.month, agora.day);
    final alvo = DateTime.utc(dia.year, dia.month, dia.day);
    final diferenca = hoje.difference(alvo).inDays;
    if (diferenca == 0) return 'Hoje';
    if (diferenca == 1) return 'Ontem';
    return '${_dois(dia.day)}/${_dois(dia.month)}/${dia.year}';
  }

  // Mensagens em ordem, com um separador de dia sempre que o dia muda
  List<Object> _itens() {
    final itens = <Object>[];
    DateTime? ultimoDia;
    for (final m in _grupo.mensagens) {
      final dia = DateTime(m.hora.year, m.hora.month, m.hora.day);
      if (ultimoDia != dia) {
        itens.add(dia);
        ultimoDia = dia;
      }
      itens.add(m);
    }
    return itens;
  }

  @override
  Widget build(BuildContext context) {
    final topo = MediaQuery.of(context).padding.top;
    final itens = _itens();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            _cabecalho(topo),

            // Aviso enquanto você está sozinho no grupo
            if (!_grupo.temOutrosMembros)
              Container(
                width: double.infinity,
                color: const Color(0xFFEAF2FF),
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 18, color: _blue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Você ainda está sozinho no grupo. Estas mensagens só aparecem para você.',
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          color: _navy,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Conversa
            Expanded(
              child: itens.isEmpty
                  ? const _SemMensagens()
                  : ListView.builder(
                      controller: _rolagem,
                      reverse: true,
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                      itemCount: itens.length,
                      itemBuilder: (context, i) {
                        // Lista invertida: o índice 0 é o item mais novo
                        final item = itens[itens.length - 1 - i];
                        if (item is DateTime) {
                          return _PilulaData(_rotuloDia(item));
                        }
                                                final mensagem = item as Mensagem;
                        return _Linha(
                          mensagem: mensagem,
                          onIrAteMim: () => _irAteMim(mensagem),
                        );
                      },
                    ),
            ),

            _entrada(),
          ],
        ),
      ),
    );
  }

  // Faixa azul: voltar, foto do grupo, nome e menu
  Widget _cabecalho(double topo) {
    return Container(
      width: double.infinity,
      color: _blue,
      padding: EdgeInsets.fromLTRB(19, topo + 12, 6, 10),
      child: Row(
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
          const SizedBox(width: 8),
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              image: DecorationImage(image: _grupo.foto, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _grupo.nome,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.comfortaa(
                fontSize: 24,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
          PopupMenuButton<String>(
            tooltip: 'Mais opções',
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (valor) {
              if (valor == 'perdido') _estouPerdido();
              if (valor == 'limpar') _limpar();
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'perdido',
                child: Row(
                  children: [
                    Icon(Icons.warning_rounded, color: _vermelho),
                    SizedBox(width: 10),
                    Text('Estou perdido'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'limpar',
                enabled: _grupo.mensagens.isNotEmpty,
                child: const Row(
                  children: [
                    Icon(Icons.delete_outline),
                    SizedBox(width: 10),
                    Text('Limpar conversa'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Campo de texto + botão enviar
  Widget _entrada() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(11, 8, 11, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: _texto,
                minLines: 1,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                style: GoogleFonts.inter(fontSize: 15, color: _navy),
                decoration: InputDecoration(
                  hintText: 'Digite uma mensagem...',
                  hintStyle: GoogleFonts.inter(
                    fontSize: 15,
                    color: const Color(0xFF9E9E9E),
                  ),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 12),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(21),
                    borderSide: const BorderSide(color: _borda, width: 1.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(21),
                    borderSide: const BorderSide(color: _blue, width: 1.5),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Material(
              color: _blue,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: _enviar,
                child: const SizedBox(
                  width: 42,
                  height: 42,
                  child: Icon(Icons.send_rounded, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Aparece quando a conversa ainda não tem mensagens
class _SemMensagens extends StatelessWidget {
  const _SemMensagens();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: const BoxDecoration(
                color: Color(0xFFE8F0FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.chat_bubble_outline,
                  color: _blue, size: 40),
            ),
            const SizedBox(height: 16),
            Text(
              'Nenhuma mensagem ainda',
              style: GoogleFonts.comfortaa(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: _blue,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Escreva a primeira mensagem do grupo.',
              textAlign: TextAlign.center,
              style: GoogleFonts.comfortaa(
                fontSize: 14,
                fontWeight: FontWeight.w300,
                color: const Color(0xFF6B6B6B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Pílula com o dia ("Hoje", "Ontem"...)
class _PilulaData extends StatelessWidget {
  final String texto;
  const _PilulaData(this.texto);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 5),
        decoration: BoxDecoration(
          color: _bolhaOutros,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          texto,
          style: GoogleFonts.comfortaa(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: _blue,
          ),
        ),
      ),
    );
  }
}

// Uma linha do chat: avatar + mensagem (do lado certo)
class _Linha extends StatelessWidget {
  final Mensagem mensagem;
  final VoidCallback onIrAteMim;

  const _Linha({required this.mensagem, required this.onIrAteMim});

  @override
  Widget build(BuildContext context) {
    // Aviso do sistema: pílula azul sem avatar
    if (mensagem.tipo == TipoMensagem.sistema) {
      return Center(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          decoration: BoxDecoration(
            color: _blue,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            mensagem.texto,
            textAlign: TextAlign.center,
            style: GoogleFonts.comfortaa(fontSize: 14, color: Colors.white),
          ),
        ),
      );
    }

    final ehVoce = mensagem.ehVoce;
    final Widget conteudo = mensagem.tipo == TipoMensagem.perdido
        ? _CartaoPerdido(mensagem: mensagem, onIrAteMim: onIrAteMim)
        : _BolhaTexto(mensagem: mensagem);

    final caixa = ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.sizeOf(context).width * 0.7,
      ),
      child: conteudo,
    );

        final Widget avatar = ehVoce
        ? CircleAvatar(
            radius: 19,
            backgroundImage: PerfilUsuario.foto,
          )
        : CircleAvatar(
            radius: 19,
            backgroundColor: _cinza,
            child: Text(
              mensagem.autor.isEmpty ? '?' : mensagem.autor[0].toUpperCase(),
              style: GoogleFonts.comfortaa(
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment:
            ehVoce ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: ehVoce
            ? [Flexible(child: caixa), const SizedBox(width: 8), avatar]
            : [avatar, const SizedBox(width: 8), Flexible(child: caixa)],
      ),
    );
  }
}

// Balão de texto: azul (seu) ou azul claro (dos amigos)
class _BolhaTexto extends StatelessWidget {
  final Mensagem mensagem;
  const _BolhaTexto({required this.mensagem});

  @override
  Widget build(BuildContext context) {
    final ehVoce = mensagem.ehVoce;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 9, 14, 6),
      decoration: BoxDecoration(
        color: ehVoce ? _blue : _bolhaOutros,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!ehVoce) ...[
            Text(
              mensagem.autor,
              style: GoogleFonts.comfortaa(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: _blue,
              ),
            ),
            const SizedBox(height: 2),
          ],
          Text(
            mensagem.texto,
            style: GoogleFonts.inter(
              fontSize: 15,
              height: 1.3,
              color: ehVoce ? Colors.white : _navy,
            ),
          ),
          const SizedBox(height: 3),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              _hhmm(mensagem.hora),
              style: GoogleFonts.inter(
                fontSize: 10,
                color: ehVoce
                    ? Colors.white.withValues(alpha: 0.75)
                    : const Color(0xFF6B7A99),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Cartão do alerta "Estou perdido" com o botão "Ir até mim"
class _CartaoPerdido extends StatelessWidget {
  final Mensagem mensagem;
  final VoidCallback onIrAteMim;

  const _CartaoPerdido({required this.mensagem, required this.onIrAteMim});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFE6EFFE),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFA9C8F7), width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_rounded, color: _vermelho, size: 34),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Estou perdido',
                  style: GoogleFonts.comfortaa(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: _blue,
                  ),
                ),
                Text(
                  mensagem.texto,
                  style: GoogleFonts.comfortaa(
                    fontSize: 11.5,
                    color: _navy,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 30,
                  child: FilledButton(
                    onPressed: onIrAteMim,
                    style: FilledButton.styleFrom(
                      backgroundColor: _blue,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'Ir até mim',
                      style: GoogleFonts.comfortaa(
                        fontSize: 14,
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
    );
  }
}