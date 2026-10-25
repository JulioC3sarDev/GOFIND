import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/grupos_usuario.dart';
import 'group_screen.dart';

const _blue = Color(0xFF0066FF);
const _blueSoft = Color(0xFF2F7BFF);
const _borda = Color(0xFFE3ECFF);
const _navy = Color(0xFF2B3A67);
const _hint = Color(0xFF9E9E9E);

// Serve para DUAS telas:
// - sem "grupo": Criar grupo
// - com "grupo": Configurar grupo (edita o grupo recebido)
class CreateGroupScreen extends StatefulWidget {
  final Grupo? grupo; // EDIÇÃO
  const CreateGroupScreen({super.key, this.grupo});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  late final TextEditingController _nome;
  late final TextEditingController _descricao;
  late final TextEditingController _evento;
  late final TextEditingController _local;
  final _picker = ImagePicker();

  String? _caminhoFoto; // EDIÇÃO: guarda só o caminho da foto
  DateTime? _data;
  TimeOfDay? _hora;
  String _codigo = '';

  bool get _editando => widget.grupo != null; // EDIÇÃO

  @override
  void initState() {
    super.initState();
    // Se estamos editando, começa com os dados do grupo
    final g = widget.grupo;
    _nome = TextEditingController(text: g?.nome ?? '');
    _descricao = TextEditingController(text: g?.descricao ?? '');
    _evento = TextEditingController(text: g?.eventoNome ?? '');
    _local = TextEditingController(text: g?.local ?? '');
    _codigo = g?.codigo ?? _gerarCodigo();
    _caminhoFoto = g?.caminhoFoto;
    _data = g?.data;
    _hora = g == null ? null : _lerHora(g.hora);
  }

  @override
  void dispose() {
    _nome.dispose();
    _descricao.dispose();
    _evento.dispose();
    _local.dispose();
    super.dispose();
  }

  // Transforma "19:00" em TimeOfDay (ou null se estiver vazio)
  static TimeOfDay? _lerHora(String texto) {
    final partes = texto.split(':');
    if (partes.length != 2) return null;
    final h = int.tryParse(partes[0]);
    final m = int.tryParse(partes[1]);
    if (h == null || m == null) return null;
    return TimeOfDay(hour: h, minute: m);
  }

  // 7 caracteres, sem letras e números parecidos (0/O, 1/I)
  static String _gerarCodigo() {
    const caracteres = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final r = Random.secure();
    return List.generate(
      7,
      (_) => caracteres[r.nextInt(caracteres.length)],
    ).join();
  }

  String _dois(int n) => n.toString().padLeft(2, '0');

  String? get _dataTexto => _data == null
      ? null
      : '${_dois(_data!.day)}/${_dois(_data!.month)}/${_data!.year}';

  String? get _horaTexto =>
      _hora == null ? null : '${_dois(_hora!.hour)}:${_dois(_hora!.minute)}';

  Future<void> _escolherData() async {
    final agora = DateTime.now();
    final hoje = DateTime(agora.year, agora.month, agora.day);
    final atual = _data;

    // Ao editar, a data salva pode já ter passado: o calendário precisa aceitá-la
    final primeira = (atual != null && atual.isBefore(hoje)) ? atual : hoje;
    var ultima = DateTime(hoje.year + 2);
    if (atual != null && atual.isAfter(ultima)) ultima = atual;

    final escolhida = await showDatePicker(
      context: context,
      initialDate: atual ?? hoje,
      firstDate: primeira,
      lastDate: ultima,
    );
    if (escolhida != null) setState(() => _data = escolhida);
  }

  Future<void> _escolherHora() async {
    final escolhida = await showTimePicker(
      context: context,
      initialTime: _hora ?? TimeOfDay.now(),
    );
    if (escolhida != null) setState(() => _hora = escolhida);
  }

  Future<void> _escolherFoto(ImageSource origem) async {
    final imagem = await _picker.pickImage(
      source: origem,
      maxWidth: 800,
      imageQuality: 85,
    );
    if (imagem != null) setState(() => _caminhoFoto = imagem.path);
  }

  void _mostrarOpcoesFoto() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Escolher da galeria'),
              onTap: () {
                Navigator.pop(ctx);
                _escolherFoto(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Tirar uma foto'),
              onTap: () {
                Navigator.pop(ctx);
                _escolherFoto(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _copiarCodigo() async {
    await Clipboard.setData(ClipboardData(text: _codigo));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Código copiado')),
    );
  }

  // EDIÇÃO: sorteia um código novo (só vale depois de salvar)
  void _gerarOutroCodigo() {
    setState(() => _codigo = _gerarCodigo());
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('Novo código gerado. Toque em Salvar para aplicar.')),
      );
  }

  // Botão principal: valida o nome e decide entre criar e salvar
  void _confirmar() {
    if (_nome.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dê um nome ao grupo para continuar')),
      );
      return;
    }
    if (_editando) {
      _salvar();
    } else {
      _criar();
    }
  }

  void _criar() {
    // Quem cria é o administrador e, no começo, o único membro
    final novo = Grupo(
      nome: _nome.text.trim(),
      codigo: _codigo,
      descricao: _descricao.text.trim(),
      eventoNome: _evento.text.trim(),
      data: _data,
      hora: _horaTexto ?? '',
      local: _local.text.trim(),
      caminhoFoto: _caminhoFoto,
      membros: const [
        Membro(nome: 'Você', ehVoce: true, admin: true, online: true),
      ],
    );

    GruposUsuario.adicionar(novo);

    // Vai direto para a tela do grupo. Remove as telas do caminho
    // (criar grupo e, se veio dela, entrar em grupo): voltar leva à Home.
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => GroupScreen(grupo: novo)),
      (route) => route.isFirst,
    );
  }

  // EDIÇÃO: grava as mudanças no grupo existente e volta
  void _salvar() {
    final g = widget.grupo!;
    g.nome = _nome.text.trim();
    g.descricao = _descricao.text.trim();
    g.eventoNome = _evento.text.trim();
    g.data = _data;
    g.hora = _horaTexto ?? '';
    g.local = _local.text.trim();
    g.caminhoFoto = _caminhoFoto;
    g.codigo = _codigo;

    // Avisa a tela do grupo e a Home para se redesenharem
    GruposUsuario.avisar();

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Alterações salvas')));

    Navigator.pop(context);
  }

  // Estilo comum dos campos de texto
  InputDecoration _decoracao(String hint, {double vertical = 12}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.inter(fontSize: 15, color: _hint),
      isDense: true,
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: vertical),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _borda, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _blue, width: 1.5),
      ),
    );
  }

  Widget _campoTexto(
    String hint,
    TextEditingController controller, {
    int linhas = 1,
    double vertical = 12,
    int? maxLength,
  }) {
    return TextField(
      controller: controller,
      minLines: linhas,
      maxLines: linhas,
      maxLength: maxLength,
      textCapitalization: TextCapitalization.sentences,
      style: GoogleFonts.inter(fontSize: 15, color: _navy),
      decoration: _decoracao(hint, vertical: vertical).copyWith(
        counterText: '',
      ),
    );
  }

  // Miniatura da foto do grupo, com o selo da câmera
  Widget _miniatura() {
    final ImageProvider imagem;
    final caminho = _caminhoFoto;
    if (caminho != null) {
      imagem = kIsWeb ? NetworkImage(caminho) : FileImage(File(caminho));
    } else {
      imagem = const AssetImage('assets/images/group_placeholder.png');
    }

    return GestureDetector(
      onTap: _mostrarOpcoesFoto,
      child: SizedBox(
        width: 87,
        height: 76,
        child: Stack(
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image(
                  image: imagem,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: const Color(0xFFE8F0FF),
                    child: const Icon(Icons.image_outlined, color: _blue),
                  ),
                ),
              ),
            ),
            Positioned(
              right: 4,
              bottom: 4,
              child: Container(
                width: 28,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.photo_camera, size: 17, color: _navy),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topo = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Fundo azul do topo
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: topo + 200,
            child: const ColoredBox(color: _blue),
          ),

          // Cabeçalho: botão voltar, título e subtítulo
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Padding(
              padding: EdgeInsets.fromLTRB(26, topo + 10, 26, 0),
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
                  const SizedBox(height: 21),
                  Text(
                    _editando ? 'Configurar grupo' : 'Criar grupo', // EDIÇÃO
                    style: GoogleFonts.comfortaa(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Padding(
                    padding: const EdgeInsets.only(right: 40),
                    child: Text(
                      _editando // EDIÇÃO
                          ? 'Ajuste as informações do seu grupo'
                          : 'Monte seu grupo e comece a compartilhar sua localização em tempo real',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        color: Colors.white,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Painel branco com os cartões (rola)
          Positioned(
            top: topo + 168,
            left: 15,
            right: 15,
            bottom: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: ListView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(8, 12, 8, 28),
                children: [
                  // 1. Nome do grupo
                  _Cartao(
                    child: Row(
                      children: [
                        const Icon(Icons.groups, color: _navy, size: 30),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _campoTexto('Nome do grupo', _nome,
                              vertical: 16),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 15),

                  // 2. Foto do grupo
                  _Cartao(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.image, color: _navy, size: 28),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text.rich(
                                TextSpan(
                                  text: 'Foto do grupo',
                                  style: GoogleFonts.inter(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w500,
                                    color: _navy,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: ' (opcional)',
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Adicione uma foto para deixar o seu grupo mais personalizado',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: _navy,
                                  height: 1.25,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        _miniatura(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 15),

                  // 3. Descrição
                  _Cartao(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _TituloSecao(
                          icone: Icons.shield,
                          texto: 'Descrição do grupo',
                        ),
                        const SizedBox(height: 14),
                        _campoTexto('Descrição...', _descricao,
                            linhas: 3, vertical: 14, maxLength: 200),
                      ],
                    ),
                  ),
                  const SizedBox(height: 15),

                  // 4. Código de acesso
                  _Cartao(
                    child: Row(
                      children: [
                        const Icon(Icons.lock_outline, color: _navy, size: 30),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _editando // EDIÇÃO
                                    ? 'Gerar outro código'
                                    : 'Código de acesso',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: _navy,
                                ),
                              ),
                              Text(
                                'Será gerado automaticamente',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: _navy,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),

                        // EDIÇÃO: botão de sortear outro código vem antes do código
                        if (_editando)
                          IconButton(
                            onPressed: _gerarOutroCodigo,
                            tooltip: 'Gerar outro código',
                            icon: const Icon(Icons.sync, color: _blue),
                          ),

                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: _blue,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            _codigo,
                            style: GoogleFonts.inter(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                              color: Colors.white,
                            ),
                          ),
                        ),

                        // Criar: botão de copiar vem depois do código
                        if (!_editando)
                          IconButton(
                            onPressed: _copiarCodigo,
                            tooltip: 'Copiar código',
                            icon: const Icon(Icons.copy_outlined,
                                color: _blue),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 15),

                  // 5. Informações do evento
                  _Cartao(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _TituloSecao(
                          icone: Icons.access_time_filled,
                          texto: 'Informações do evento',
                        ),
                        const SizedBox(height: 14),
                        _campoTexto('Nome do Evento', _evento),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _CampoToque(
                                hint: 'Data',
                                valor: _dataTexto,
                                icone: Icons.calendar_today_outlined,
                                onTap: _escolherData,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _CampoToque(
                                hint: 'Hora',
                                valor: _horaTexto,
                                icone: Icons.schedule,
                                onTap: _escolherHora,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _campoTexto('Local', _local),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Botão principal: Criar grupo ou Salvar
                  SizedBox(
                    height: 51,
                    child: FilledButton(
                      onPressed: _confirmar,
                      style: FilledButton.styleFrom(
                        backgroundColor: _blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Text(
                        _editando ? 'Salvar' : 'Criar grupo', // EDIÇÃO
                        style: GoogleFonts.comfortaa(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Você pode alterar essas configurações depois',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: _blueSoft.withValues(alpha: 0.8),
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
}

// Cartão branco com borda azul clara e sombra suave
class _Cartao extends StatelessWidget {
  final Widget child;
  const _Cartao({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borda),
        boxShadow: const [
          BoxShadow(
            color: Color(0x140066FF),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }
}

// Ícone + título no topo de um cartão
class _TituloSecao extends StatelessWidget {
  final IconData icone;
  final String texto;
  const _TituloSecao({required this.icone, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icone, color: _navy, size: 28),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            texto,
            style: GoogleFonts.inter(
              fontSize: 17,
              fontWeight: FontWeight.w500,
              color: _navy,
            ),
          ),
        ),
      ],
    );
  }
}

// Campo que parece um campo de texto, mas abre calendário ou relógio ao tocar
class _CampoToque extends StatelessWidget {
  final String hint;
  final String? valor;
  final IconData icone;
  final VoidCallback onTap;

  const _CampoToque({
    required this.hint,
    required this.valor,
    required this.icone,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _borda, width: 1.5),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                valor ?? hint,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: valor == null ? _hint : _navy,
                ),
              ),
            ),
            Icon(icone, size: 18, color: _hint),
          ],
        ),
      ),
    );
  }
}