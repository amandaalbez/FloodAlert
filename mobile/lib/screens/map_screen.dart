import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../main.dart';
import '../services/api_exception.dart';
import '../services/api_service.dart';
import '../utils/formatadores.dart' show horarioRelativo;

enum NivelMapa { baixo, moderado, alto }

class RiscoPonto {
  final String nome;
  final LatLng posicao;
  final NivelMapa nivel;

  const RiscoPonto({
    required this.nome,
    required this.posicao,
    required this.nivel,
  });
}

/// Um alagamento reportado por um morador, para mostrar como pino no mapa.
class ReporteMapa {
  final String descricao;
  final LatLng posicao;
  final NivelMapa nivel;
  final DateTime criadoEm;

  const ReporteMapa({
    required this.descricao,
    required this.posicao,
    required this.nivel,
    required this.criadoEm,
  });
}

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _controller = MapController();

  // Centro inicial do mapa (Tijuca, Rio de Janeiro) — usado até a
  // localização real do usuário (ou os pontos da API) chegarem.
  static const _posicaoInicial = LatLng(-22.9249, -43.2277);

  bool _carregando = true;
  String? _erro;
  List<RiscoPonto> _pontos = [];
  List<ReporteMapa> _reportes = [];

  LatLng? _minhaPosicao;
  bool _buscandoLocalizacao = true;
  String? _avisoLocalizacao;

  @override
  void initState() {
    super.initState();
    _carregarPontos();
    _obterLocalizacaoAtual();
  }

  /// Pede permissão e busca a localização real do dispositivo. Se o
  /// usuário negar ou o serviço estiver desligado, o mapa continua
  /// funcionando normalmente, só sem centralizar na posição dele.
  Future<void> _obterLocalizacaoAtual() async {
    setState(() {
      _buscandoLocalizacao = true;
      _avisoLocalizacao = null;
    });

    try {
      final servicoAtivo = await Geolocator.isLocationServiceEnabled();
      if (!servicoAtivo) {
        setState(() => _avisoLocalizacao =
            'Ative a localização do dispositivo para ver sua posição no mapa.');
        return;
      }

      var permissao = await Geolocator.checkPermission();
      if (permissao == LocationPermission.denied) {
        permissao = await Geolocator.requestPermission();
      }

      if (permissao == LocationPermission.denied ||
          permissao == LocationPermission.deniedForever) {
        setState(() => _avisoLocalizacao =
            'Permissão de localização negada. Habilite para centralizar o mapa na sua posição.');
        return;
      }

      final posicao = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      if (!mounted) return;
      final minhaLatLng = LatLng(posicao.latitude, posicao.longitude);
      setState(() => _minhaPosicao = minhaLatLng);
      _controller.move(minhaLatLng, 15);
    } catch (e) {
      if (mounted) {
        setState(() =>
            _avisoLocalizacao = 'Não foi possível obter sua localização.');
      }
    } finally {
      if (mounted) setState(() => _buscandoLocalizacao = false);
    }
  }

  NivelMapa _parseNivel(String texto) {
    switch (texto) {
      case 'baixo':
        return NivelMapa.baixo;
      case 'alto':
        return NivelMapa.alto;
      case 'moderado':
      default:
        return NivelMapa.moderado;
    }
  }

  Future<void> _carregarPontos() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      final resultados = await Future.wait([
        ApiService.pontosDoMapa(),
        ApiService.listarReportes(),
      ]);
      final dadosPontos = resultados[0];
      final dadosReportes = resultados[1];

      setState(() {
        _pontos = dadosPontos.map((item) {
          final mapa = item as Map<String, dynamic>;
          return RiscoPonto(
            nome: mapa['nome'] as String,
            posicao: LatLng(
              (mapa['latitude'] as num).toDouble(),
              (mapa['longitude'] as num).toDouble(),
            ),
            nivel: _parseNivel(mapa['nivel_risco'] as String),
          );
        }).toList();

        _reportes = dadosReportes.map((item) {
          final mapa = item as Map<String, dynamic>;
          return ReporteMapa(
            descricao: mapa['descricao'] as String,
            posicao: LatLng(
              (mapa['latitude'] as num).toDouble(),
              (mapa['longitude'] as num).toDouble(),
            ),
            nivel: _parseNivel(mapa['nivel'] as String),
            criadoEm: DateTime.parse(mapa['criado_em'] as String),
          );
        }).toList();
      });
    } on ApiException catch (e) {
      setState(() => _erro = e.mensagem);
    } catch (e) {
      setState(() => _erro = 'Não foi possível carregar o mapa.');
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Color _corDoNivel(NivelMapa nivel) {
    switch (nivel) {
      case NivelMapa.baixo:
        return const Color(0xFF2E9E6B);
      case NivelMapa.moderado:
        return AppColors.secondary;
      case NivelMapa.alto:
        return AppColors.error;
    }
  }

  String _textoDoNivel(NivelMapa nivel) {
    switch (nivel) {
      case NivelMapa.baixo:
        return 'Baixo';
      case NivelMapa.moderado:
        return 'Moderado';
      case NivelMapa.alto:
        return 'Alto';
    }
  }

  void _mostrarInfo(RiscoPonto ponto) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _corDoNivel(ponto.nivel).withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.water_drop_rounded,
                color: _corDoNivel(ponto.nivel),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ponto.nome,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Risco ${_textoDoNivel(ponto.nivel)}',
                    style: TextStyle(
                      color: _corDoNivel(ponto.nivel),
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarInfoReporte(ReporteMapa reporte) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _corDoNivel(reporte.nivel).withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.campaign_rounded,
                    color: _corDoNivel(reporte.nivel),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Risco ${_textoDoNivel(reporte.nivel)}',
                            style: TextStyle(
                              color: _corDoNivel(reporte.nivel),
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            '· Reportado por morador',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        horarioRelativo(reporte.criadoEm),
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              reporte.descricao,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14.5,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_carregando) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    if (_erro != null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off_rounded, size: 48, color: AppColors.textSecondary),
                const SizedBox(height: 16),
                Text(
                  _erro!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 15),
                ),
                const SizedBox(height: 20),
                OutlinedButton(
                  onPressed: _carregarPontos,
                  child: const Text('Tentar novamente'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final marcadores = [
      ..._pontos.map((ponto) {
        final cor = _corDoNivel(ponto.nivel);
        return Marker(
          point: ponto.posicao,
          width: 40,
          height: 40,
          child: GestureDetector(
            onTap: () => _mostrarInfo(ponto),
            child: Container(
              decoration: BoxDecoration(
                color: cor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: cor.withValues(alpha: 0.5),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(
                Icons.water_drop_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        );
      }),
      ..._reportes.map((reporte) {
        final cor = _corDoNivel(reporte.nivel);
        return Marker(
          point: reporte.posicao,
          width: 38,
          height: 38,
          child: GestureDetector(
            onTap: () => _mostrarInfoReporte(reporte),
            child: Container(
              decoration: BoxDecoration(
                color: cor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white, width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: cor.withValues(alpha: 0.5),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(
                Icons.campaign_rounded,
                color: Colors.white,
                size: 17,
              ),
            ),
          ),
        );
      }),
      if (_minhaPosicao != null)
        Marker(
          point: _minhaPosicao!,
          width: 26,
          height: 26,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.5),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
        ),
    ];

    final circulos = _pontos.map((ponto) {
      final cor = _corDoNivel(ponto.nivel);
      return CircleMarker(
        point: ponto.posicao,
        radius: 220,
        useRadiusInMeter: true,
        color: cor.withValues(alpha: 0.16),
        borderColor: cor.withValues(alpha: 0.6),
        borderStrokeWidth: 1.5,
      );
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          FlutterMap(
            mapController: _controller,
            options: MapOptions(
              initialCenter: _minhaPosicao ?? _posicaoInicial,
              initialZoom: 14.5,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.floodalert.mobile',
              ),
              CircleLayer(circles: circulos),
              MarkerLayer(markers: marcadores),
              const RichAttributionWidget(
                attributions: [
                  TextSourceAttribution('OpenStreetMap contributors'),
                ],
              ),
            ],
          ),

          // Cabeçalho flutuante
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.map_rounded,
                        color: AppColors.primary, size: 20),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Mapa de risco',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: _carregarPontos,
                      borderRadius: BorderRadius.circular(20),
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(Icons.refresh_rounded,
                            color: AppColors.textSecondary, size: 19),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Aviso de localização (só aparece se algo impedir de obter a posição)
          if (_avisoLocalizacao != null)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 70, 20, 0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.secondary.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.location_off_rounded,
                          size: 18, color: Color(0xFFB57724)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _avisoLocalizacao!,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: Color(0xFFB57724),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Botão de recentralizar na minha localização
          Positioned(
            right: 16,
            bottom: 92,
            child: Material(
              color: AppColors.surface,
              shape: const CircleBorder(),
              elevation: 3,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: _buscandoLocalizacao ? null : _obterLocalizacaoAtual,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: _buscandoLocalizacao
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: AppColors.primary,
                          ),
                        )
                      : const Icon(
                          Icons.my_location_rounded,
                          color: AppColors.primary,
                          size: 22,
                        ),
                ),
              ),
            ),
          ),

          // Legenda flutuante
          Positioned(
            left: 20,
            right: 20,
            bottom: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _ItemLegenda(
                    cor: _corDoNivel(NivelMapa.baixo),
                    label: 'Baixo',
                  ),
                  _ItemLegenda(
                    cor: _corDoNivel(NivelMapa.moderado),
                    label: 'Moderado',
                  ),
                  _ItemLegenda(
                    cor: _corDoNivel(NivelMapa.alto),
                    label: 'Alto',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemLegenda extends StatelessWidget {
  final Color cor;
  final String label;

  const _ItemLegenda({required this.cor, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: cor, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}