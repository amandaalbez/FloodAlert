import '../screens/home_screen.dart' show NivelRisco;

/// Converte o texto que vem da API ("baixo"/"moderado"/"alto") no enum
/// NivelRisco que as telas já usam.
NivelRisco nivelRiscoDeTexto(String texto) {
  switch (texto) {
    case 'baixo':
      return NivelRisco.baixo;
    case 'alto':
      return NivelRisco.alto;
    case 'moderado':
    default:
      return NivelRisco.moderado;
  }
}

/// Transforma um DateTime em texto relativo tipo "Há 12 min", "Há 3 h",
/// "Há 2 dias" — no mesmo formato que os mocks já usavam.
String horarioRelativo(DateTime data) {
  final diferenca = DateTime.now().difference(data);

  if (diferenca.inMinutes < 1) return 'Agora mesmo';
  if (diferenca.inMinutes < 60) return 'Há ${diferenca.inMinutes} min';
  if (diferenca.inHours < 24) return 'Há ${diferenca.inHours} h';
  if (diferenca.inDays == 1) return 'Há 1 dia';
  return 'Há ${diferenca.inDays} dias';
}