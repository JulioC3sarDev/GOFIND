import 'package:flutter/foundation.dart';
import 'grupos_usuario.dart';

// Comunicação entre telas de abas diferentes
class NavegacaoApp {
  // Qualquer tela pode pedir à Home para trocar de aba:
  // 0 = Início, 1 = Grupos, 2 = Radar, 3 = Perfil.
  // A Home atende o pedido e volta o valor para null.
  static final ValueNotifier<int?> pedidoDeAba = ValueNotifier<int?>(null);

  // Grupo que o radar está acompanhando (null = ainda não escolheu)
  static final ValueNotifier<Grupo?> grupoDoRadar = ValueNotifier<Grupo?>(null);

  // Abre o Radar já mostrando os amigos de um grupo
  static void abrirRadar(Grupo grupo) {
    grupoDoRadar.value = grupo;
    pedidoDeAba.value = 2;
  }
}