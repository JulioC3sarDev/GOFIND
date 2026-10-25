import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/grupos_usuario.dart';
import 'create_group_screen.dart';

const _blue = Color(0xFF0066FF);
const _blueSoft = Color(0xFF2F7BFF);
const _borda = Color(0xFFE3ECFF);
const _navy = Color(0xFF2B3A67);
const _hint = Color(0xFF9E9E9E);

class JoinGroupScreen extends StatefulWidget {
  const JoinGroupScreen({super.key});

  @override
  State<JoinGroupScreen> createState() => _JoinGroupScreenState();
}

class _JoinGroupScreenState extends State<JoinGroupScreen> {
  final _codigo = TextEditingController();

  @override
  void dispose() {
    _codigo.dispose();
    super.dispose();
  }

  void _entrar() {
    FocusScope.of(context).unfocus();
    final codigo = _codigo.text.trim();

    if (codigo.length != 7) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('O código tem 7 caracteres')),
      );
      return;
    }

    // A entrada real depende da conexão entre celulares (etapa futura)
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Código recebido',
          style: GoogleFonts.comfortaa(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'O código $codigo tem o formato certo. Entrar no grupo vai '
          'depender da conexão por proximidade entre os celulares, que '
          'ainda estamos construindo.',
          style: GoogleFonts.inter(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Ok'),
          ),
        ],
      ),
    );
  }

  Future<void> _criarGrupo() async {
    final antes = GruposUsuario.lista.length;

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateGroupScreen()),
    );

    if (!mounted) return;

    // Se um grupo foi criado, fecha esta tela e volta para a Home
    if (GruposUsuario.lista.length > antes) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final topo = MediaQuery.of(context).padding.top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            // Cabeçalho azul
            Container(
              width: double.infinity,
              color: _blue,
              padding: EdgeInsets.fromLTRB(26, topo + 10, 31, 26),
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
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Entrar em Grupo',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.comfortaa(
                                fontSize: 32,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Digite o código de acesso do grupo para se juntar aos seus amigos',
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
                            image:
                                AssetImage('assets/images/placeholder.png'),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Conteúdo
            Expanded(
              child: ListView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(26, 26, 26, 28),
                children: [
                  // Cartão: Junte-se a um grupo
                  _Cartao(
                    padding: const EdgeInsets.fromLTRB(16, 22, 16, 18),
                    child: Column(
                      children: [
                        const Icon(Icons.groups, color: _blue, size: 96),
                        const SizedBox(height: 4),
                        Text(
                          'Junte-se a um grupo',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.comfortaa(
                            fontSize: 21,
                            fontWeight: FontWeight.w700,
                            color: _navy,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Use o código de acesso que foi compartilhado com você para entrar no grupo',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            color: _blueSoft,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Cartão: campo do código
                  _Cartao(
                    padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
                    child: Row(
                      children: [
                        const Icon(Icons.groups, color: _blue, size: 34),
                        const SizedBox(width: 14),
                        Expanded(
                          child: TextField(
                            controller: _codigo,
                            textCapitalization: TextCapitalization.characters,
                            autocorrect: false,
                            enableSuggestions: false,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _entrar(),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp('[a-zA-Z0-9]')),
                              LengthLimitingTextInputFormatter(7),
                              _MaiusculasFormatter(),
                            ],
                            style: GoogleFonts.inter(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 2,
                              color: _navy,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Digite o código aqui',
                              hintStyle: GoogleFonts.inter(
                                fontSize: 16,
                                letterSpacing: 0,
                                fontWeight: FontWeight.w400,
                                color: _hint,
                              ),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 18),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide:
                                    const BorderSide(color: Color(0xFFEAF0FB)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide:
                                    const BorderSide(color: _blue, width: 1.5),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  _BotaoAzul(texto: 'Entrar no grupo', onPressed: _entrar),
                  const SizedBox(height: 8),

                  // Link: "Não tem um código? Crie um grupo"
                  InkWell(
                    onTap: _criarGrupo,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Text.rich(
                        TextSpan(
                          text: 'Não tem um código? ',
                          style: GoogleFonts.inter(
                            fontSize: 13.5,
                            color: _blue,
                          ),
                          children: [
                            TextSpan(
                              text: 'Crie um grupo',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Cartão: Crie um grupo
                  _Cartao(
                    padding: const EdgeInsets.fromLTRB(16, 22, 16, 22),
                    child: Column(
                      children: [
                        const Icon(Icons.person_add_alt_1,
                            color: _blue, size: 100),
                        const SizedBox(height: 10),
                        Text(
                          'Crie um grupo e comece a interagir com seus amigos',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            color: _blue,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  _BotaoAzul(texto: 'Criar grupo', onPressed: _criarGrupo),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Converte o que é digitado para maiúsculas
class _MaiusculasFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue antigo,
    TextEditingValue novo,
  ) {
    return novo.copyWith(text: novo.text.toUpperCase());
  }
}

// Cartão branco com borda azul clara e sombra suave
class _Cartao extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;

  const _Cartao({
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
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

// Botão azul de largura total
class _BotaoAzul extends StatelessWidget {
  final String texto;
  final VoidCallback onPressed;

  const _BotaoAzul({required this.texto, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
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