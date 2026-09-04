import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../main.dart';

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

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _controller = MapController();

  // Centro inicial do mapa (Tijuca, Rio de Janeiro).
  static const _posicaoInicial = LatLng(-22.9249, -43.2277);

  // TODO: substituir pelos pontos reais vindos da API / sensores
  final List<RiscoPonto> _pontos = const [
    RiscoPonto(
      nome: 'Rio Joana',
      posicao: LatLng(-22.9235, -43.2310),
      nivel: NivelMapa.alto,
    ),
    RiscoPonto(
      nome: 'Praça Saens Peña',
      posicao: LatLng(-22.9257, -43.2298),
      nivel: NivelMapa.moderado,
    ),
    RiscoPonto(
      nome: 'Grande Tijuca',
      posicao: LatLng(-22.9270, -43.2250),
      nivel: NivelMapa.baixo,
    ),
  ];

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

  @override
  Widget build(BuildContext context) {
    final marcadores = _pontos.map((ponto) {
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
    }).toList();

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
            options: const MapOptions(
              initialCenter: _posicaoInicial,
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
                  ],
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