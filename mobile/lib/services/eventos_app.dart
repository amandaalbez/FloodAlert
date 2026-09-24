import 'package:flutter/foundation.dart';

/// Barramento de eventos bem simples do app: um contador que aumenta
/// toda vez que algo relevante acontece em algum lugar do app. Quem
/// quiser reagir a isso (ex: o Mapa recarregando quando um reporte novo
/// é criado na Home) escuta esse ValueNotifier.
///
/// Não é um sistema de estado global completo — só o suficiente pra
/// avisar "algo mudou" entre abas que vivem separadas no IndexedStack.
class EventosApp {
  EventosApp._();

  static final EventosApp instance = EventosApp._();

  final ValueNotifier<int> novoReporte = ValueNotifier<int>(0);

  void notificarNovoReporte() {
    novoReporte.value++;
  }
}