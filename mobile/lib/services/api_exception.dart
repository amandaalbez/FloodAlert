/// Erro vindo da API, já com a mensagem pronta pra mostrar num SnackBar.
class ApiException implements Exception {
  final String mensagem;
  final int? statusCode;

  ApiException(this.mensagem, {this.statusCode});

  @override
  String toString() => mensagem;
}