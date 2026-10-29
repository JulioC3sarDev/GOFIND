import 'grupos_usuario.dart';

// Troque para true para testar o app com amigos fictícios:
// - o radar mostra 4 amigos
// - "Localizar Amigos" abre o radar mesmo com você sozinho no grupo
// Lembre de voltar para false depois.
const bool amigosDeTeste = true;
// Troque para true para simular que você está andando até o amigo:
// na tela de seguir, a distância vai diminuindo sozinha até a chegada.
// Lembre de voltar para false depois.
const bool simularAproximacao =true;

const List<Membro> amigosFicticios = [
  Membro(nome: 'João', online: true, distanciaM: 54, direcaoGraus: 254),
  Membro(nome: 'Maria', online: true, distanciaM: 28, direcaoGraus: 316),
  Membro(nome: 'Pedro', online: true, distanciaM: 63, direcaoGraus: 53),
  Membro(nome: 'Laura', distanciaM: 85, direcaoGraus: 130),
];