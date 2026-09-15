import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

/// Erro ao obter a localização (permissão negada, serviço desligado, etc).
class LocalizacaoException implements Exception {
  final String mensagem;
  LocalizacaoException(this.mensagem);

  @override
  String toString() => mensagem;
}

class LocalizacaoService {
  /// Pede permissão (se necessário) e retorna a posição atual do
  /// dispositivo. Lança LocalizacaoException se o usuário negar ou o
  /// serviço de localização estiver desligado.
  static Future<Position> obterPosicaoAtual() async {
    final servicoAtivo = await Geolocator.isLocationServiceEnabled();
    if (!servicoAtivo) {
      throw LocalizacaoException(
        'Ative a localização do dispositivo para usar sua posição real.',
      );
    }

    var permissao = await Geolocator.checkPermission();
    if (permissao == LocationPermission.denied) {
      permissao = await Geolocator.requestPermission();
    }

    if (permissao == LocationPermission.denied ||
        permissao == LocationPermission.deniedForever) {
      throw LocalizacaoException('Permissão de localização negada.');
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
  }

  /// Converte coordenadas (lat/lon) num endereço legível, tipo
  /// "Tijuca, Rio de Janeiro", usando o Nominatim (OpenStreetMap) —
  /// gratuito e sem chave de API, igual os tiles do mapa.
  static Future<String> obterEnderecoLegivel(double lat, double lon) async {
    final uri = Uri.parse(
      'https://nominatim.openstreetmap.org/reverse'
      '?format=json&lat=$lat&lon=$lon&zoom=14&addressdetails=1',
    );

    final resposta = await http.get(
      uri,
      headers: {
        // Exigido pela política de uso do Nominatim: identifique seu app.
        'User-Agent': 'FloodAlertApp/1.0 (projeto de estudo)',
        'Accept-Language': 'pt-BR',
      },
    );

    if (resposta.statusCode != 200) {
      throw LocalizacaoException('Não foi possível identificar o endereço.');
    }

    final dados =
        jsonDecode(utf8.decode(resposta.bodyBytes)) as Map<String, dynamic>;
    final endereco = dados['address'] as Map<String, dynamic>?;

    if (endereco != null) {
      final bairro = endereco['suburb'] ??
          endereco['neighbourhood'] ??
          endereco['quarter'] ??
          endereco['residential'];
      final cidade = endereco['city'] ??
          endereco['town'] ??
          endereco['municipality'] ??
          endereco['county'];

      if (bairro != null && cidade != null) return '$bairro, $cidade';
      if (cidade != null) return cidade as String;
    }

    return dados['display_name'] as String? ?? 'Localização atual';
  }
}