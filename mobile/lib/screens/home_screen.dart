import 'package:flutter/material.dart';

import '../main.dart';
import '../services/api_exception.dart';
import '../services/api_service.dart';
import '../services/localizacao_service.dart';
import '../utils/formatadores.dart';
import '../widgets/reportar_alagamento_sheet.dart';
import 'map_screen.dart';

enum NivelRisco { baixo, moderado, alto }

class AlertaItem {
  final String titulo;
  final String local;
  final String horario;
  final NivelRisco nivel;

  const AlertaItem({
    required this.titulo,
    required this.local,
    required this.horario,
    required this.nivel,
  });
}

class HomeScreen extends StatefulWidget {
  /// Chamado quando o usuário toca em "Ver mapa de risco". Quem cria a
  /// HomeScreen (o MainNavigation) passa aqui uma função que troca de
  /// aba, mantendo a barra de navegação visível — em vez de empilhar o
  /// mapa como uma tela nova por cima de tudo.
  final VoidCallback? onIrParaMapa;

  const HomeScreen({super.key, this.onIrParaMapa});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _carregando = true;
  String? _erro;

  NivelRisco _riscoAtual = NivelRisco.baixo;
  String _bairroAtual = '';
  int? _chanceChuvaPercent;
  double? _nivelRioMetros;
  double? _nivelRioMaximoMetros;
  List<AlertaItem> _alertas = [];

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  /// Busca a localização real do dispositivo e converte num texto tipo
  /// "Tijuca, Rio de Janeiro". Se o usuário negar a permissão ou algo
  /// falhar, retorna null — quem chamar cai de volta no nome vindo do
  /// backend, sem quebrar a tela.
  Future<String?> _obterLocalizacaoReal() async {
    try {
      final posicao = await LocalizacaoService.obterPosicaoAtual();
      return await LocalizacaoService.obterEnderecoLegivel(
        posicao.latitude,
        posicao.longitude,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _carregarDados() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      final regiao = await ApiService.regiaoDoUsuario();
      final alertasBrutos = await ApiService.listarAlertas();
      final localReal = await _obterLocalizacaoReal();

      setState(() {
        _riscoAtual = nivelRiscoDeTexto(regiao['nivel_risco'] as String);
        // Prioriza a localização real do dispositivo; só cai no nome
        // cadastrado no backend se a permissão for negada ou falhar.
        _bairroAtual = localReal ?? regiao['nome'] as String;
        _chanceChuvaPercent = regiao['chance_chuva_percent'] as int?;
        _nivelRioMetros = (regiao['nivel_rio_metros'] as num?)?.toDouble();
        _nivelRioMaximoMetros =
            (regiao['nivel_rio_maximo_metros'] as num?)?.toDouble();

        _alertas = alertasBrutos.map((item) {
          final mapa = item as Map<String, dynamic>;
          return AlertaItem(
            titulo: mapa['titulo'] as String,
            local: mapa['local'] as String,
            horario: horarioRelativo(DateTime.parse(mapa['criado_em'] as String)),
            nivel: nivelRiscoDeTexto(mapa['nivel'] as String),
          );
        }).toList();
      });
    } on ApiException catch (e) {
      setState(() => _erro = e.mensagem);
    } catch (e) {
      setState(() => _erro = 'Não foi possível conectar ao servidor.');
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Color _corDoRisco(NivelRisco nivel) {
    switch (nivel) {
      case NivelRisco.baixo:
        return const Color(0xFF2E9E6B);
      case NivelRisco.moderado:
        return AppColors.secondary;
      case NivelRisco.alto:
        return AppColors.error;
    }
  }

  String _textoDoRisco(NivelRisco nivel) {
    switch (nivel) {
      case NivelRisco.baixo:
        return 'Baixo';
      case NivelRisco.moderado:
        return 'Moderado';
      case NivelRisco.alto:
        return 'Alto';
    }
  }

  IconData _iconeDoRisco(NivelRisco nivel) {
    switch (nivel) {
      case NivelRisco.baixo:
        return Icons.check_circle_outline_rounded;
      case NivelRisco.moderado:
        return Icons.warning_amber_rounded;
      case NivelRisco.alto:
        return Icons.dangerous_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final corRisco = _corDoRisco(_riscoAtual);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: _carregarDados,
          child: _carregando
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : _erro != null
                  ? _EstadoErro(mensagem: _erro!, onTentarNovamente: _carregarDados)
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                      children: [
                        // ---------- Cartão de risco atual (com localização) ----------
                        _RiscoCard(
                          nivel: _riscoAtual,
                          cor: corRisco,
                          icone: _iconeDoRisco(_riscoAtual),
                          texto: _textoDoRisco(_riscoAtual),
                          local: _bairroAtual,
                          onVerMapa: widget.onIrParaMapa ??
                              () {
                                // Fallback: só usado se a HomeScreen for
                                // aberta fora do MainNavigation (ex: testes).
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const MapScreen(),
                                  ),
                                );
                              },
                        ),

                        const SizedBox(height: 14),

                        // ---------- Indicadores rápidos ----------
                        Row(
                          children: [
                            Expanded(
                              child: _IndicadorCard(
                                icone: Icons.water_drop_rounded,
                                cor: AppColors.primary,
                                titulo: 'Nível do rio',
                                valor: _nivelRioMetros != null
                                    ? '${_nivelRioMetros!.toStringAsFixed(1)} m'
                                    : '--',
                                progresso: (_nivelRioMetros != null &&
                                        _nivelRioMaximoMetros != null &&
                                        _nivelRioMaximoMetros! > 0)
                                    ? _nivelRioMetros! / _nivelRioMaximoMetros!
                                    : 0,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _IndicadorCard(
                                icone: Icons.umbrella_rounded,
                                cor: AppColors.secondary,
                                titulo: 'Chance de chuva',
                                valor: _chanceChuvaPercent != null
                                    ? '$_chanceChuvaPercent%'
                                    : '--',
                                progresso: (_chanceChuvaPercent ?? 0) / 100,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 26),

                        // ---------- Ação rápida ----------
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final enviado = await Navigator.of(context).push<bool>(
                                MaterialPageRoute(
                                  builder: (_) => const ReportarAlagamentoScreen(),
                                ),
                              );
                              if (enviado == true && mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Obrigado! Seu reporte foi enviado.',
                                    ),
                                    backgroundColor: Color(0xFF2E9E6B),
                                  ),
                                );
                              }
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              side: const BorderSide(color: AppColors.border),
                              backgroundColor: AppColors.surface,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            icon: const Icon(Icons.campaign_rounded, size: 19),
                            label: const Text(
                              'Reportar alagamento',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),

                        const SizedBox(height: 26),

                        // ---------- Lista de alertas ----------
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Alertas recentes', style: textTheme.titleLarge),
                            TextButton(
                              onPressed: () {
                                // TODO: abrir lista completa de alertas
                              },
                              child: const Text('Ver todos'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),

                        if (_alertas.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Center(
                              child: Text(
                                'Nenhum alerta no momento.',
                                style: textTheme.bodyMedium,
                              ),
                            ),
                          )
                        else
                          ..._alertas.map((alerta) => _AlertaCard(
                                alerta: alerta,
                                cor: _corDoRisco(alerta.nivel),
                                icone: _iconeDoRisco(alerta.nivel),
                              )),
                      ],
                    ),
        ),
      ),
    );
  }
}

/// Mostrado quando a API falha ao carregar os dados da Home.
class _EstadoErro extends StatelessWidget {
  final String mensagem;
  final VoidCallback onTentarNovamente;

  const _EstadoErro({required this.mensagem, required this.onTentarNovamente});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 80),
        const Icon(Icons.cloud_off_rounded, size: 48, color: AppColors.textSecondary),
        const SizedBox(height: 16),
        Text(
          mensagem,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 15),
        ),
        const SizedBox(height: 20),
        Center(
          child: OutlinedButton(
            onPressed: onTentarNovamente,
            child: const Text('Tentar novamente'),
          ),
        ),
      ],
    );
  }
}

/// Cartão principal com o nível de risco atual e a localização monitorada.
class _RiscoCard extends StatelessWidget {
  final NivelRisco nivel;
  final Color cor;
  final IconData icone;
  final String texto;
  final String local;
  final VoidCallback onVerMapa;

  const _RiscoCard({
    required this.nivel,
    required this.cor,
    required this.icone,
    required this.texto,
    required this.local,
    required this.onVerMapa,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.3),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Linha superior: status "ao vivo" + localização monitorada
          Row(
            children: [
              Container(
                width: 7,
                height: 7,
                margin: const EdgeInsets.only(right: 7),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
              const Icon(
                Icons.location_on_rounded,
                size: 15,
                color: Colors.white,
              ),
              const SizedBox(width: 3),
              Expanded(
                child: Text(
                  local,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Risco de alagamento na sua área',
            style: textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: cor.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icone, color: cor, size: 24),
              ),
              const SizedBox(width: 14),
              Text(
                texto,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onVerMapa,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primaryDark,
                padding: const EdgeInsets.symmetric(vertical: 13),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.map_rounded, size: 18),
              label: const Text(
                'Ver mapa de risco',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Cartão pequeno com um indicador numérico e uma barra de progresso.
class _IndicadorCard extends StatelessWidget {
  final IconData icone;
  final Color cor;
  final String titulo;
  final String valor;
  final double progresso;

  const _IndicadorCard({
    required this.icone,
    required this.cor,
    required this.titulo,
    required this.valor,
    required this.progresso,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: cor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icone, color: cor, size: 17),
          ),
          const SizedBox(height: 10),
          Text(
            valor,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(titulo, style: textTheme.bodySmall),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progresso.clamp(0, 1),
              minHeight: 6,
              backgroundColor: cor.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation(cor),
            ),
          ),
        ],
      ),
    );
  }
}

/// Chip vertical de ação rápida usado no carrossel horizontal.
class _AcaoRapida extends StatelessWidget {
  final IconData icone;
  final String label;
  final VoidCallback onTap;

  const _AcaoRapida({
    required this.icone,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: 88,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icone, color: AppColors.primary, size: 19),
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AlertaCard extends StatelessWidget {
  final AlertaItem alerta;
  final Color cor;
  final IconData icone;

  const _AlertaCard({
    required this.alerta,
    required this.cor,
    required this.icone,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Barra lateral colorida indicando a severidade
          Container(
            width: 4,
            height: 74,
            decoration: BoxDecoration(
              color: cor,
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(16),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: cor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icone, color: cor, size: 19),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          alerta.titulo,
                          style: textTheme.labelLarge,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            const Icon(
                              Icons.place_outlined,
                              size: 13,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                alerta.local,
                                style: textTheme.bodySmall,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          alerta.horario,
                          style: textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary.withValues(alpha: 0.75),
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
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