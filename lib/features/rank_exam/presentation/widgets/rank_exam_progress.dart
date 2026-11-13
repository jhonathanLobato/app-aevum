import 'package:flutter/material.dart';

import '../../../../design_system/system_button.dart';
import '../../../../design_system/system_colors.dart';
import '../../../../design_system/system_progress_bar.dart';
import '../../../../design_system/system_spacing.dart';
import '../../../../design_system/system_text_styles.dart';
import '../../../activities/domain/sport_activity.dart';
import '../../domain/rank_exam.dart';

/// Progresso do exame em andamento: cada requisito em número absoluto e os
/// dias restantes.
class RankExamProgress extends StatelessWidget {
  const RankExamProgress({super.key, required this.exame});

  final RankExamState exame;

  @override
  Widget build(BuildContext context) {
    final pctTreinos = (exame.fracaoTreinos * 100).round();
    final pctMissao = (exame.fracaoMissaoDiaria * 100).round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          exame.diasRestantes == 1
              ? '1 DIA RESTANTE'
              : '${exame.diasRestantes} DIAS RESTANTES',
          style: SystemTextStyles.label.copyWith(color: SystemPalette.gold),
        ),
        const SizedBox(height: SystemSpacing.md),
        _Requisito(
          titulo:
              'TREINOS PROGRAMADOS ($pctTreinos% DE ${exame.treinosProgramadosNoPeriodo} = ${exame.treinosNecessarios})',
          atual: exame.treinosFeitos,
          total: exame.treinosNecessarios,
        ),
        const SizedBox(height: SystemSpacing.sm),
        _Requisito(
          titulo: 'MISSÕES DIÁRIAS ($pctMissao% DE ${exame.diasValidos} DIAS)',
          atual: exame.missoesCumpridas,
          total: exame.missoesNecessarias,
        ),
        const SizedBox(height: SystemSpacing.sm),
        _Requisito(
          titulo:
              'ATIVIDADES EXTRAS (${exame.registrosPorModalidade}× CADA, 30+ MIN)',
          atual: exame.modalidadesCumpridas,
          total: exame.modalidadesNecessarias,
        ),
        const SizedBox(height: SystemSpacing.md),
        for (final m in exame.modalidades)
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Row(
              children: [
                Icon(
                  m.cumprida
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  size: 14,
                  color: m.cumprida
                      ? SystemPalette.success
                      : SystemPalette.mutedForeground,
                ),
                const SizedBox(width: 6),
                Expanded(
                    child: Text(m.tipo.nome, style: SystemTextStyles.body)),
                Text('${m.registros}/${m.necessarios}',
                    style: SystemTextStyles.label),
              ],
            ),
          ),
      ],
    );
  }
}

class _Requisito extends StatelessWidget {
  const _Requisito(
      {required this.titulo, required this.atual, required this.total});

  final String titulo;
  final int atual;
  final int total;

  @override
  Widget build(BuildContext context) {
    final ok = atual >= total;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
                child: Text(titulo,
                    style: SystemTextStyles.label.copyWith(fontSize: 8.5))),
            Text('$atual / $total',
                style: SystemTextStyles.label.copyWith(
                    fontSize: 9,
                    color: ok ? SystemPalette.success : SystemPalette.primary)),
          ],
        ),
        const SizedBox(height: 4),
        SystemProgressBar(value: atual, max: total),
      ],
    );
  }
}

/// Folha para escolher as [quantidade] atividades extras ao iniciar o exame.
/// Devolve as escolhidas ou `null` se for cancelada.
Future<List<SportType>?> escolherAtividadesExtras(
  BuildContext context, {
  required int quantidade,
  required int registrosPorModalidade,
}) {
  return showModalBottomSheet<List<SportType>>(
    context: context,
    backgroundColor: SystemPalette.background,
    isScrollControlled: true,
    builder: (_) => _EscolherModalidades(
        quantidade: quantidade, registros: registrosPorModalidade),
  );
}

class _EscolherModalidades extends StatefulWidget {
  const _EscolherModalidades(
      {required this.quantidade, required this.registros});

  final int quantidade;
  final int registros;

  @override
  State<_EscolherModalidades> createState() => _EscolherModalidadesState();
}

class _EscolherModalidadesState extends State<_EscolherModalidades> {
  final Set<SportType> _escolhidas = {};

  @override
  Widget build(BuildContext context) {
    final completo = _escolhidas.length == widget.quantidade;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(SystemSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'ESCOLHA ${widget.quantidade} ATIVIDADES EXTRAS (${_escolhidas.length}/${widget.quantidade})',
              style: SystemTextStyles.displaySmall,
            ),
            const SizedBox(height: 4),
            Text(
              '${widget.registros} registro${widget.registros == 1 ? '' : 's'} de 30+ min de cada uma durante o exame.',
              style: SystemTextStyles.body
                  .copyWith(color: SystemPalette.mutedForeground),
            ),
            const SizedBox(height: SystemSpacing.md),
            for (final tipo in SportType.values)
              CheckboxListTile(
                key: Key('exame_${tipo.name}'),
                value: _escolhidas.contains(tipo),
                title: Text(tipo.nome, style: SystemTextStyles.body),
                activeColor: SystemPalette.primary,
                dense: true,
                onChanged: (marcada) => setState(() {
                  if (marcada ?? false) {
                    if (_escolhidas.length < widget.quantidade) {
                      _escolhidas.add(tipo);
                    }
                  } else {
                    _escolhidas.remove(tipo);
                  }
                }),
              ),
            const SizedBox(height: SystemSpacing.md),
            SystemButton(
              key: const Key('exame_confirmar_atividades'),
              label: 'Iniciar exame',
              variant: SystemButtonVariant.action,
              onPressed: completo
                  ? () => Navigator.of(context).pop(_escolhidas.toList())
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
