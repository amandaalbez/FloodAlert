/// Guarda o token e os dados do usuário logado em memória, durante a
/// sessão do app. Como é um singleton simples, dá pra acessar de
/// qualquer tela com AuthSession.instance.
///
/// TODO: quando quiser manter o login entre reaberturas do app, trocar
/// isso por shared_preferences (salvando o token em disco).
class AuthSession {
  AuthSession._();

  static final AuthSession instance = AuthSession._();

  String? token;
  int? usuarioId;
  String? nome;
  String? email;
  String? bairro;

  bool get estaLogado => token != null;

  void definirSessao({
    required String token,
    required int usuarioId,
    required String nome,
    required String email,
    String? bairro,
  }) {
    this.token = token;
    this.usuarioId = usuarioId;
    this.nome = nome;
    this.email = email;
    this.bairro = bairro;
  }

  void encerrarSessao() {
    token = null;
    usuarioId = null;
    nome = null;
    email = null;
    bairro = null;
  }
}