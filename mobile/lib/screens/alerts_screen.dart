import 'package:flutter/material.dart';

import '../main.dart';
import 'home_screen.dart' show AlertaItem, NivelRisco;

enum _Filtro { todos, baixo, moderado, alto }

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  _Filtro _filtroAtual = _Filtro.todos;

  // TODO: substituir por dados reais vindos da API
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
      titulo: 'Via interditada por acúmulo de água',
      local: 'Av. Maracanã',
      horario: 'Há 3 h',
      nivel: NivelRisco.alto,
    ),
    AlertaItem(
      titulo: 'Nível normalizado após chuva de ontem',
      local: 'Grande Tijuca',
      horario: 'Há 1 dia',
      nivel: NivelRisco.baixo,
    ),
    AlertaItem(
      titulo: 'Vistoria preventiva concluída sem riscos',
      local: 'Rio Comprido',
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

  bool _passaNoFiltro(AlertaItem alerta) {
    switch (_filtroAtual) {
      case _Filtro.todos:
        return true;
      case _Filtro.baixo:
        return alerta.nivel == NivelRisco.baixo;
      case _Filtro.moderado:
        return alerta.nivel == NivelRisco.moderado;
      case _Filtro.alto:
        return alerta.nivel == NivelRisco.alto;
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final alertasFiltrados = _alertas.where(_passaNoFiltro).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ---------- Cabeçalho ----------
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Alertas', style: textTheme.headlineMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: 26,
                  )),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${alertasFiltrados.length} ativos',
                      style: const TextStyle(
                        color: AppColors.error,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ---------- Filtros ----------
            SizedBox(
              height: 46,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _ChipFiltro(
                    label: 'Todos',
                    selecionado: _filtroAtual == _Filtro.todos,
                    onTap: () => setState(() => _filtroAtual = _Filtro.todos),
                  ),
                  _ChipFiltro(
                    label: 'Baixo',
                    cor: _corDoRisco(NivelRisco.baixo),
                    selecionado: _filtroAtual == _Filtro.baixo,
                    onTap: () => setState(() => _filtroAtual = _Filtro.baixo),
                  ),
                  _ChipFiltro(
                    label: 'Moderado',
                    cor: _corDoRisco(NivelRisco.moderado),
                    selecionado: _filtroAtual == _Filtro.moderado,
                    onTap: () =>
                        setState(() => _filtroAtual = _Filtro.moderado),
                  ),
                  _ChipFiltro(
                    label: 'Alto',
                    cor: _corDoRisco(NivelRisco.alto),
                    selecionado: _filtroAtual == _Filtro.alto,
                    onTap: () => setState(() => _filtroAtual = _Filtro.alto),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // ---------- Lista ----------
            Expanded(
              child: alertasFiltrados.isEmpty
                  ? _EstadoVazio(textTheme: textTheme)
                  : RefreshIndicator(
                      color: AppColors.primary,
                      onRefresh: () async {
                        // TODO: recarregar dados reais da API
                        await Future.delayed(
                            const Duration(milliseconds: 800));
                      },
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                        itemCount: alertasFiltrados.length,
                        itemBuilder: (context, index) {
                          final alerta = alertasFiltrados[index];
                          return _AlertaDetalheCard(
                            alerta: alerta,
                            cor: _corDoRisco(alerta.nivel),
                            icone: _iconeDoRisco(alerta.nivel),
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChipFiltro extends StatelessWidget {
  final String label;
  final Color? cor;
  final bool selecionado;
  final VoidCallback onTap;

  const _ChipFiltro({
    required this.label,
    required this.selecionado,
    required this.onTap,
    this.cor,
  });

  @override
  Widget build(BuildContext context) {
    final corBase = cor ?? AppColors.primary;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: selecionado ? corBase : AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selecionado ? corBase : AppColors.border,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (cor != null) ...[
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: selecionado ? Colors.white : corBase,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: TextStyle(
                    color: selecionado ? Colors.white : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
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

class _AlertaDetalheCard extends StatelessWidget {
  final AlertaItem alerta;
  final Color cor;
  final IconData icone;

  const _AlertaDetalheCard({
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
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // TODO: abrir detalhe completo do alerta
          },
          child: Row(
            children: [
              Container(
                width: 4,
                height: 82,
                decoration: BoxDecoration(
                  color: cor,
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(16),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
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
                            const SizedBox(height: 6),
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
                            const SizedBox(height: 4),
                            Text(
                              alerta.horario,
                              style: textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary
                                    .withValues(alpha: 0.75),
                                fontSize: 11.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EstadoVazio extends StatelessWidget {
  final TextTheme textTheme;

  const _EstadoVazio({required this.textTheme});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_off_outlined,
                color: AppColors.primary,
                size: 34,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Nenhum alerta neste filtro',
              style: textTheme.titleLarge?.copyWith(fontSize: 17),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Tente selecionar outro nível de risco.',
              style: textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}