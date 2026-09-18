import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../main.dart';
import '../services/api_exception.dart';
import '../services/api_service.dart';
import '../services/localizacao_service.dart';
import '../screens/home_screen.dart' show NivelRisco;

/// Tela cheia para reportar um alagamento: mapa com um pino travado no
/// centro (a pessoa arrasta o MAPA por baixo do pino pra posicionar),
/// nível de severidade e descrição.
///
/// Retorna `true` no Navigator.pop se o reporte foi enviado com sucesso.
class ReportarAlagamentoScreen extends StatefulWidget {
  const ReportarAlagamentoScreen({super.key});

  @override
  State<ReportarAlagamentoScreen> createState() =>
      _ReportarAlagamentoScreenState();
}

class _ReportarAlagamentoScreenState extends State<ReportarAlagamentoScreen> {
  final MapController _controller = MapController();
  final _descricaoController = TextEditingController();

  static const _posicaoPadrao = LatLng(-22.9249, -43.2277); // Tijuca, RJ

  LatLng _posicaoSelecionada = _posicaoPadrao;
  NivelRisco _nivelSelecionado = NivelRisco.moderado;

  bool _carregandoLocalizacaoInicial = true;
  bool _enviando = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _centralizarNaLocalizacaoAtual();
  }

  @override
  void dispose() {
    _descricaoController.dispose();
    super.dispose();
  }

  Future<void> _centralizarNaLocalizacaoAtual() async {
    try {
      final posicao = await LocalizacaoService.obterPosicaoAtual();
      if (!mounted) return;
      final latLng = LatLng(posicao.latitude, posicao.longitude);
      setState(() => _posicaoSelecionada = latLng);
      _controller.move(latLng, 16);
    } catch (_) {
      // Sem permissão/serviço: fica no ponto padrão, a pessoa arrasta manualmente.
    } finally {
      if (mounted) setState(() => _carregandoLocalizacaoInicial = false);
    }
  }

  Color _corDoNivel(NivelRisco nivel) {
    switch (nivel) {
      case NivelRisco.baixo:
        return const Color(0xFF2E9E6B);
      case NivelRisco.moderado:
        return AppColors.secondary;
      case NivelRisco.alto:
        return AppColors.error;
    }
  }

  String _textoDoNivel(NivelRisco nivel) {
    switch (nivel) {
      case NivelRisco.baixo:
        return 'Baixo';
      case NivelRisco.moderado:
        return 'Moderado';
      case NivelRisco.alto:
        return 'Alto';
    }
  }

  Future<void> _enviar() async {
    FocusScope.of(context).unfocus();

    final descricao = _descricaoController.text.trim();
    if (descricao.length < 10) {
      HapticFeedback.lightImpact();
      setState(() => _erro = 'Descreva com um pouco mais de detalhe (mín. 10 caracteres).');
      return;
    }

    setState(() {
      _enviando = true;
      _erro = null;
    });

    try {
      await ApiService.criarReporte(
        descricao: descricao,
        nivel: _nivelSelecionado.name,
        latitude: _posicaoSelecionada.latitude,
        longitude: _posicaoSelecionada.longitude,
      );

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      setState(() => _erro = e.mensagem);
    } catch (e) {
      setState(() => _erro = 'Não foi possível enviar. Verifique sua conexão.');
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final corNivel = _corDoNivel(_nivelSelecionado);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ---------- Cabeçalho ----------
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 20, 4),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    color: AppColors.textPrimary,
                  ),
                  const Text(
                    'Reportar alagamento',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),

            // ---------- Mapa com pino fixo no centro ----------
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  FlutterMap(
                    mapController: _controller,
                    options: MapOptions(
                      initialCenter: _posicaoSelecionada,
                      initialZoom: 16,
                      onPositionChanged: (camera, hasGesture) {
                        _posicaoSelecionada = camera.center;
                      },
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.floodalert.mobile',
                      ),
                      const RichAttributionWidget(
                        attributions: [
                          TextSourceAttribution('OpenStreetMap contributors'),
                        ],
                      ),
                    ],
                  ),

                  // Pino travado no centro da tela — arrasta o mapa por
                  // baixo dele pra escolher o ponto exato.
                  IgnorePointer(
                    child: Padding(
                      // Desloca pra cima na altura da "ponta" do pino,
                      // pra a ponta (não o centro do ícone) marcar o local.
                      padding: const EdgeInsets.only(bottom: 34),
                      child: Icon(
                        Icons.location_on_rounded,
                        size: 46,
                        color: corNivel,
                        shadows: const [
                          Shadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3)),
                        ],
                      ),
                    ),
                  ),

                  if (_carregandoLocalizacaoInicial)
                    Container(
                      color: Colors.black.withValues(alpha: 0.05),
                      child: const Center(
                        child: CircularProgressIndicator(color: AppColors.primary),
                      ),
                    ),

                  // Dica no topo do mapa
                  Positioned(
                    top: 12,
                    left: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.pan_tool_alt_rounded, size: 16, color: AppColors.primary),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Arraste o mapa para posicionar o pino no local exato',
                              style: TextStyle(fontSize: 12.5, color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Botão de recentralizar na localização atual
                  Positioned(
                    right: 16,
                    bottom: 16,
                    child: Material(
                      color: AppColors.surface,
                      shape: const CircleBorder(),
                      elevation: 3,
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: _centralizarNaLocalizacaoAtual,
                        child: const Padding(
                          padding: EdgeInsets.all(12),
                          child: Icon(Icons.my_location_rounded, color: AppColors.primary, size: 22),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ---------- Painel inferior: nível + descrição ----------
            Container(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Nível de severidade',
                    style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary, fontSize: 13.5),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: NivelRisco.values.map((nivel) {
                      final selecionado = nivel == _nivelSelecionado;
                      final cor = _corDoNivel(nivel);
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            right: nivel != NivelRisco.alto ? 8 : 0,
                          ),
                          child: Material(
                            color: selecionado ? cor : AppColors.background,
                            borderRadius: BorderRadius.circular(12),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => setState(() => _nivelSelecionado = nivel),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 11),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: selecionado ? cor : AppColors.border,
                                  ),
                                ),
                                child: Text(
                                  _textoDoNivel(nivel),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: selecionado ? Colors.white : AppColors.textPrimary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 16),

                  const Text(
                    'O que está acontecendo?',
                    style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary, fontSize: 13.5),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _descricaoController,
                    maxLines: 3,
                    maxLength: 300,
                    decoration: const InputDecoration(
                      hintText: 'Ex: Água já cobre a calçada na esquina...',
                    ),
                  ),

                  if (_erro != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 15),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _erro!,
                            style: const TextStyle(color: AppColors.error, fontSize: 12.5),
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _enviando ? null : _enviar,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: corNivel,
                      ),
                      child: _enviando
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                valueColor: AlwaysStoppedAnimation(Colors.white),
                              ),
                            )
                          : const Text('Enviar reporte'),
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
}