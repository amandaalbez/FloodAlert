import 'package:flutter/material.dart';

import '../main.dart';

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
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _abaAtual = 0;

  // TODO: substituir por dados reais vindos da API / sensores
  final NivelRisco _riscoAtual = NivelRisco.moderado;
  final String _bairroAtual = 'Tijuca, Rio de Janeiro';
  final int _chanceChuvaPercent = 78;
  final double _nivelRioMetros = 2.4;
  final double _nivelRioMaximoMetros = 4.0;

  final List<AlertaItem> _alertas = const [
    AlertaItem(
      titulo: 'Nível do rio subindo rapidamente',
      local: 'Rio Joana - Tijuca',
      horario: 'Há 12 min',
      nivel: NivelRisco.alto,
    ),
    AlertaItem(
      titulo: 'Chuva forte prevista para as próximas horas',
      local: 'Zona Norte, Rio de Janeiro',
      horario: 'Há 45 min',
      nivel: NivelRisco.moderado,
    ),
    AlertaItem(
      titulo: 'Bueiro entupido reportado por moradores',
      local: 'Praça Saens Peña',
      horario: 'Há 2 h',
      nivel: NivelRisco.moderado,
    ),
    AlertaItem(
      titulo: 'Nível normalizado após chuva de ontem',
      local: 'Grande Tijuca',
      horario: 'Há 1 dia',
      nivel: NivelRisco.baixo,
    ),
  ];

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
          onRefresh: () async {
            // TODO: recarregar dados reais da API
            await Future.delayed(const Duration(milliseconds: 800));
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            children: [
              // ---------- Cartão de risco atual (com localização) ----------
              _RiscoCard(
                nivel: _riscoAtual,
                cor: corRisco,
                icone: _iconeDoRisco(_riscoAtual),
                texto: _textoDoRisco(_riscoAtual),
                local: _bairroAtual,
                onVerMapa: () {
                  // TODO: abrir mapa em tela cheia
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
                      valor:
                          '${_nivelRioMetros.toStringAsFixed(1)} m',
                      progresso:
                          _nivelRioMetros / _nivelRioMaximoMetros,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _IndicadorCard(
                      icone: Icons.umbrella_rounded,
                      cor: AppColors.secondary,
                      titulo: 'Chance de chuva',
                      valor: '$_chanceChuvaPercent%',
                      progresso: _chanceChuvaPercent / 100,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 26),

              // ---------- Ações rápidas ----------
              Text('Ações rápidas', style: textTheme.titleLarge),
              const SizedBox(height: 12),
              SizedBox(
                height: 92,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _AcaoRapida(
                      icone: Icons.campaign_rounded,
                      label: 'Reportar\nalagamento',
                      onTap: () {},
                    ),
                    _AcaoRapida(
                      icone: Icons.alt_route_rounded,
                      label: 'Rotas\nseguras',
                      onTap: () {},
                    ),
                    _AcaoRapida(
                      icone: Icons.phone_in_talk_rounded,
                      label: 'Contatos de\nemergência',
                      onTap: () {},
                    ),
                    _AcaoRapida(
                      icone: Icons.history_rounded,
                      label: 'Histórico\nda região',
                      onTap: () {},
                    ),
                  ],
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

              ..._alertas.map((alerta) => _AlertaCard(
                    alerta: alerta,
                    cor: _corDoRisco(alerta.nivel),
                    icone: _iconeDoRisco(alerta.nivel),
                  )),
            ],
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _abaAtual,
        onDestinationSelected: (index) => setState(() => _abaAtual = index),
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primary.withValues(alpha: 0.12),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded, color: AppColors.primary),
            label: 'Início',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map_rounded, color: AppColors.primary),
            label: 'Mapa',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_outlined),
            selectedIcon:
                Icon(Icons.notifications_rounded, color: AppColors.primary),
            label: 'Alertas',
          ),
        ],
      ),
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
      child: Stack(
        children: [
          // Ícone decorativo gigante e sutil ao fundo
          Positioned(
            right: -18,
            top: -18,
            child: Icon(
              Icons.water_drop_rounded,
              size: 130,
              color: Colors.white.withValues(alpha: 0.06),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Linha superior: status "ao vivo" + localização monitorada
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    margin: const EdgeInsets.only(right: 6),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Text(
                    'MONITORAMENTO ATIVO',
                    style: textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(
                    Icons.location_on_rounded,
                    size: 16,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      local,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
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