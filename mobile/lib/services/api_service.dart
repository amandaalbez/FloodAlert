import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_exception.dart';
import 'auth_session.dart';

/// Endereço base da API.
///
/// - Rodando no Chrome (flutter run -d chrome): "http://localhost:8000" funciona.
/// - Emulador Android: troque para "http://10.0.2.2:8000" (o emulador não
///   enxerga "localhost" como o seu PC, esse IP especial aponta pra ele).
/// - Celular físico ou outro PC na mesma rede: troque pelo IP local do
///   seu PC (ex: "http://192.168.0.10:8000") — descubra com "ipconfig".
class ApiService {
  static const String baseUrl = 'http://localhost:8000';

  static Map<String, String> get _headersJson => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  static Map<String, String> get _headersAutenticado => {
        ..._headersJson,
        if (AuthSession.instance.token != null)
          'Authorization': 'Bearer ${AuthSession.instance.token}',
      };

  /// Lê o corpo da resposta e, se for um erro, lança uma ApiException
  /// com a mensagem que a API mandou (campo "detail" do FastAPI).
  static Map<String, dynamic> _tratarResposta(http.Response resposta) {
    final corpo = resposta.body.isNotEmpty
        ? jsonDecode(utf8.decode(resposta.bodyBytes)) as Map<String, dynamic>
        : <String, dynamic>{};

    if (resposta.statusCode >= 200 && resposta.statusCode < 300) {
      return corpo;
    }

    final detalhe = corpo['detail'];
    String mensagem;
    if (detalhe is String) {
      mensagem = detalhe;
    } else if (detalhe is List && detalhe.isNotEmpty) {
      // Erro de validação (422) do FastAPI vem como lista de objetos.
      mensagem = detalhe
          .map((e) => e is Map ? e['msg']?.toString() : e.toString())
          .join('; ');
    } else {
      mensagem = 'Não foi possível completar a operação (${resposta.statusCode}).';
    }

    throw ApiException(mensagem, statusCode: resposta.statusCode);
  }

  // ---------------------------------------------------------------------
  // Autenticação
  // ---------------------------------------------------------------------
  static Future<void> registrar({
    required String nome,
    required String email,
    required String senha,
    String? bairro,
  }) async {
    final resposta = await http.post(
      Uri.parse('$baseUrl/auth/registrar'),
      headers: _headersJson,
      body: jsonEncode({
        'nome': nome,
        'email': email,
        'senha': senha,
        'bairro': bairro,
      }),
    );

    final dados = _tratarResposta(resposta);
    _salvarSessao(dados);
  }

  static Future<void> login({
    required String email,
    required String senha,
  }) async {
    final resposta = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: _headersJson,
      body: jsonEncode({'email': email, 'senha': senha}),
    );

    final dados = _tratarResposta(resposta);
    _salvarSessao(dados);
  }

  static void _salvarSessao(Map<String, dynamic> dados) {
    final usuario = dados['usuario'] as Map<String, dynamic>;
    AuthSession.instance.definirSessao(
      token: dados['access_token'] as String,
      usuarioId: usuario['id'] as int,
      nome: usuario['nome'] as String,
      email: usuario['email'] as String,
      bairro: usuario['bairro'] as String?,
    );
  }

  // ---------------------------------------------------------------------
  // Home / Mapa / Alertas (prontos pra quando as telas forem consumir)
  // ---------------------------------------------------------------------
  static Future<Map<String, dynamic>> regiaoDoUsuario() async {
    final resposta = await http.get(
      Uri.parse('$baseUrl/home/regiao'),
      headers: _headersAutenticado,
    );
    return _tratarResposta(resposta);
  }

  static Future<List<dynamic>> pontosDoMapa() async {
    final resposta = await http.get(
      Uri.parse('$baseUrl/mapa/pontos'),
      headers: _headersJson,
    );
    final texto = utf8.decode(resposta.bodyBytes);
    if (resposta.statusCode >= 200 && resposta.statusCode < 300) {
      return jsonDecode(texto) as List<dynamic>;
    }
    throw ApiException('Não foi possível carregar o mapa (${resposta.statusCode}).');
  }

  static Future<List<dynamic>> listarAlertas({String? nivel}) async {
    final uri = Uri.parse('$baseUrl/alertas').replace(
      queryParameters: nivel != null ? {'nivel': nivel} : null,
    );
    final resposta = await http.get(uri, headers: _headersJson);
    final texto = utf8.decode(resposta.bodyBytes);
    if (resposta.statusCode >= 200 && resposta.statusCode < 300) {
      return jsonDecode(texto) as List<dynamic>;
    }
    throw ApiException('Não foi possível carregar os alertas (${resposta.statusCode}).');
  }
}