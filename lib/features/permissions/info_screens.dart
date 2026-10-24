import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ---------------------------------------------------------------
// Tela 1: Saber mais sobre nossa privacidade
// ---------------------------------------------------------------
class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _InfoLayout(
      titulo: 'Sua privacidade',
      intro:
          'O GoFind foi pensado para funcionar sem internet e sem servidores. Veja como cuidamos das suas informações.',
      itens: [
        _InfoItem(
          icone: Icons.phone_android,
          titulo: 'Seus dados ficam no seu celular',
          texto:
              'Seu nome, sua foto, o histórico do chat e seus grupos são guardados somente no seu aparelho.',
        ),
        _InfoItem(
          icone: Icons.cloud_off_outlined,
          titulo: 'Sem servidores externos',
          texto:
              'Mensagens e localização vão direto de um celular para outro, sem passar por servidores.',
        ),
        _InfoItem(
          icone: Icons.group_outlined,
          titulo: 'Só quem foi aprovado',
          texto:
              'Apenas participantes aprovados pelo administrador do grupo recebem as suas informações.',
        ),
        _InfoItem(
          icone: Icons.lock_outline,
          titulo: 'Informações protegidas',
          texto:
              'O que é enviado entre os celulares do grupo é criptografado.',
        ),
        _InfoItem(
          icone: Icons.logout,
          titulo: 'Você no controle',
          texto:
              'Ao sair do grupo, você deixa de compartilhar a sua localização.',
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------
// Tela 2: Por que isso é necessário?
// ---------------------------------------------------------------
class WhyPermissionsScreen extends StatelessWidget {
  const WhyPermissionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _InfoLayout(
      titulo: 'Por que pedimos essas permissões?',
      intro:
          'Cada permissão tem um motivo. Sem elas, o GoFind não consegue funcionar.',
      itens: [
        _InfoItem(
          icone: Icons.my_location,
          titulo: 'Localização',
          texto:
              'O GPS informa onde você está. Com isso, calculamos a direção e a distância até os seus amigos e até o ponto de encontro. O Android também exige essa permissão para procurar celulares por perto. Sua posição só é enviada a quem está no seu grupo.',
        ),
        _InfoItem(
          icone: Icons.bluetooth,
          titulo: 'Bluetooth e dispositivos próximos',
          texto:
              'É assim que os celulares do grupo se encontram e conversam diretamente entre si, sem precisar de internet.',
        ),
        _InfoItem(
          icone: Icons.notifications_none,
          titulo: 'Notificações',
          texto:
              'Avisam sobre alertas do grupo, como "Estou perdido", e mostram que o GoFind está ativo em segundo plano.',
        ),
      ],
      rodape:
          'Você pode mudar essas permissões a qualquer momento nas configurações do celular.',
    );
  }
}

// ---------------------------------------------------------------
// Layout compartilhado pelas duas telas
// ---------------------------------------------------------------
class _InfoLayout extends StatelessWidget {
  final String titulo;
  final String intro;
  final List<_InfoItem> itens;
  final String? rodape;

  const _InfoLayout({
    required this.titulo,
    required this.intro,
    required this.itens,
    this.rodape,
  });

  static const _blue = Color(0xFF0066FF);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: _blue),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(28, 8, 28, 32),
          children: [
            Text(
              titulo,
              style: GoogleFonts.comfortaa(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: _blue,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              intro,
              style: GoogleFonts.comfortaa(
                fontSize: 16,
                fontWeight: FontWeight.w300,
                color: const Color(0xFF222222),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 28),
            for (final item in itens) ...[
              item,
              const SizedBox(height: 22),
            ],
            if (rodape != null)
              Text(
                rodape!,
                style: GoogleFonts.comfortaa(
                  fontSize: 14,
                  fontWeight: FontWeight.w300,
                  color: const Color(0xFF6B6B6B),
                  height: 1.4,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Um item da lista: ícone azul num círculo + título + texto
class _InfoItem extends StatelessWidget {
  final IconData icone;
  final String titulo;
  final String texto;

  const _InfoItem({
    required this.icone,
    required this.titulo,
    required this.texto,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: const BoxDecoration(
            color: Color(0xFFE8F0FF),
            shape: BoxShape.circle,
          ),
          child: Icon(icone, color: const Color(0xFF0066FF), size: 22),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titulo,
                style: GoogleFonts.comfortaa(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF111111),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                texto,
                style: GoogleFonts.comfortaa(
                  fontSize: 15,
                  fontWeight: FontWeight.w300,
                  color: const Color(0xFF222222),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}