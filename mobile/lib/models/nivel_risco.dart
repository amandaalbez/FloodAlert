enum NivelRisco {
  baixo,
  moderado,
  alto,
}

NivelRisco nivelRiscoDeTexto(String texto) {
  switch (texto.toLowerCase()) {
    case 'alto':
      return NivelRisco.alto;

    case 'moderado':
    case 'medio':
    case 'médio':
      return NivelRisco.moderado;

    case 'baixo':
      return NivelRisco.baixo;

    default:
      return NivelRisco.baixo;
  }
}