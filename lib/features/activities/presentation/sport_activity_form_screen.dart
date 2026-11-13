import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/system_back_button.dart';
import '../../../design_system/system_button.dart';
import '../../../design_system/system_colors.dart';
import '../../../design_system/system_panel.dart';
import '../../../design_system/system_scaffold.dart';
import '../../../design_system/system_spacing.dart';
import '../../../design_system/system_text_field.dart';
import '../../../design_system/system_text_styles.dart';
import '../../rank_exam/presentation/rank_exam_providers.dart';
import '../domain/sport_activity.dart';
import 'activity_providers.dart';
import 'sport_activity_format.dart';

/// Formulário de criar/editar registro. Mostra só os campos que fazem
/// sentido pra modalidade (distância ou rounds, nunca os dois). Tudo manual,
/// sem GPS/cronômetro — e sem nenhum cálculo de XP: salvar só grava o registro.
class SportActivityFormScreen extends ConsumerStatefulWidget {
  const SportActivityFormScreen(
      {required this.tipo, this.activityId, super.key});

  final SportType tipo;

  /// `null` = novo registro; informado = editando este registro.
  final int? activityId;

  bool get editando => activityId != null;

  @override
  ConsumerState<SportActivityFormScreen> createState() =>
      _SportActivityFormScreenState();
}

class _SportActivityFormScreenState
    extends ConsumerState<SportActivityFormScreen> {
  final _duracaoController = TextEditingController();
  final _distanciaController = TextEditingController();
  final _roundsController = TextEditingController();
  final _observacoesController = TextEditingController();
  late DateTime _data = _hoje();
  bool _preenchido = false;
  bool _tentouSalvar = false;
  bool _salvando = false;

  static DateTime _hoje() {
    final agora = DateTime.now();
    return DateTime(agora.year, agora.month, agora.day);
  }

  @override
  void initState() {
    super.initState();
    if (widget.editando) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _preencher());
    }
  }

  @override
  void dispose() {
    _duracaoController.dispose();
    _distanciaController.dispose();
    _roundsController.dispose();
    _observacoesController.dispose();
    super.dispose();
  }

  void _preencher() {
    if (_preenchido || !mounted) return;
    final atividade =
        ref.read(sportActivityProvider(widget.activityId!)).valueOrNull;
    if (atividade == null) return;
    setState(() {
      _data = atividade.data;
      _duracaoController.text = '${atividade.duracaoMinutos}';
      _distanciaController.text = atividade.distanciaKm == null
          ? ''
          : formatarNumero(atividade.distanciaKm!);
      _roundsController.text = atividade.rounds?.toString() ?? '';
      _observacoesController.text = atividade.observacoes ?? '';
      _preenchido = true;
    });
  }

  int? get _duracao => int.tryParse(_duracaoController.text.trim());

  /// `null` com campo vazio (opcional); `NaN` quando o texto não é número.
  double? get _distancia {
    final texto = _distanciaController.text.trim().replaceAll(',', '.');
    if (texto.isEmpty) return null;
    return double.tryParse(texto) ?? double.nan;
  }

  int? get _rounds {
    final texto = _roundsController.text.trim();
    if (texto.isEmpty) return null;
    return int.tryParse(texto) ?? -1;
  }

  String? get _erroDuracao {
    final d = _duracao;
    return (d == null || d <= 0) ? 'Informe a duração em minutos' : null;
  }

  String? get _erroDistancia {
    if (!widget.tipo.usaDistancia) return null;
    final d = _distancia;
    if (d == null) return null;
    return (d.isNaN || d < 0) ? 'Distância inválida' : null;
  }

  String? get _erroRounds {
    if (!widget.tipo.usaRounds) return null;
    final r = _rounds;
    if (r == null) return null;
    return r < 0 ? 'Rounds inválidos' : null;
  }

  Future<void> _salvar() async {
    if (_salvando) return;
    if (_erroDuracao != null || _erroDistancia != null || _erroRounds != null) {
      setState(() => _tentouSalvar = true);
      return;
    }
    _salvando = true;

    final input = SportActivityInput(
      tipo: widget.tipo,
      data: _data,
      duracaoMinutos: _duracao!,
      distanciaKm: widget.tipo.usaDistancia ? _distancia : null,
      rounds: widget.tipo.usaRounds ? _rounds : null,
      observacoes: _observacoesController.text,
    );

    final repo = ref.read(sportActivityRepositoryProvider);
    if (widget.editando) {
      await repo.update(widget.activityId!, input);
    } else {
      await repo.create(input);
    }
    // Atividades contam para o exame de rank.
    if (mounted) await sincronizarExame(context, ref);
    if (mounted) Navigator.of(context).maybePop();
  }

  Future<void> _escolherData() async {
    final escolhida = await showDatePicker(
      context: context,
      initialDate: _data,
      firstDate: DateTime(2000),
      lastDate: _hoje().add(const Duration(days: 1)),
    );
    if (escolhida != null) {
      setState(() =>
          _data = DateTime(escolhida.year, escolhida.month, escolhida.day));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.editando && !_preenchido) {
      ref.watch(sportActivityProvider(widget.activityId!));
      WidgetsBinding.instance.addPostFrameCallback((_) => _preencher());
    }

    String? erro(String? mensagem) => _tentouSalvar ? mensagem : null;
    SystemFieldStatus status(String? mensagem) => erro(mensagem) == null
        ? SystemFieldStatus.idle
        : SystemFieldStatus.error;

    return SystemScaffold(
      title: widget.editando ? 'EDITAR REGISTRO' : 'NOVO REGISTRO',
      subtitle: widget.tipo.nome.toUpperCase(),
      leading: const SystemBackButton(),
      body: SystemPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _DateField(data: _data, onTap: _escolherData),
            const SizedBox(height: SystemSpacing.md),
            SystemTextField(
              key: const Key('atividade_duracao_field'),
              label: 'Duração',
              suffix: 'MIN',
              controller: _duracaoController,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              status: status(_erroDuracao),
              hint: erro(_erroDuracao),
              onChanged: (_) => setState(() {}),
            ),
            if (widget.tipo.usaDistancia) ...[
              const SizedBox(height: SystemSpacing.md),
              SystemTextField(
                key: const Key('atividade_distancia_field'),
                label: 'Distância (opcional)',
                suffix: 'KM',
                controller: _distanciaController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                textInputAction: TextInputAction.next,
                status: status(_erroDistancia),
                hint: erro(_erroDistancia),
                onChanged: (_) => setState(() {}),
              ),
            ],
            if (widget.tipo.usaRounds) ...[
              const SizedBox(height: SystemSpacing.md),
              SystemTextField(
                key: const Key('atividade_rounds_field'),
                label: 'Rounds (opcional)',
                controller: _roundsController,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                status: status(_erroRounds),
                hint: erro(_erroRounds),
                onChanged: (_) => setState(() {}),
              ),
            ],
            const SizedBox(height: SystemSpacing.md),
            SystemTextField(
              key: const Key('atividade_observacoes_field'),
              label: 'Observação (opcional)',
              controller: _observacoesController,
              maxLines: 3,
            ),
            const SizedBox(height: SystemSpacing.lg),
            SystemButton(
              label: widget.editando ? 'Salvar alterações' : 'Salvar registro',
              variant: SystemButtonVariant.action,
              size: SystemButtonSize.lg,
              onPressed: _salvar,
            ),
          ],
        ),
      ),
    );
  }
}

/// Campo de data no mesmo visual dos demais campos; toca pra abrir o
/// seletor de data.
class _DateField extends StatelessWidget {
  const _DateField({required this.data, required this.onTap});

  final DateTime data;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 6),
          child: Text('DATA', style: SystemTextStyles.label),
        ),
        GestureDetector(
          key: const Key('atividade_data_field'),
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: SystemSpacing.md, vertical: 12),
            decoration: BoxDecoration(
              color: SystemPalette.background.withValues(alpha: 0.6),
              border: Border.all(
                color: SystemPalette.primary
                    .withValues(alpha: SystemOpacities.input),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today,
                    size: 18,
                    color: SystemPalette.primary.withValues(alpha: 0.8)),
                const SizedBox(width: SystemSpacing.sm),
                Expanded(
                  child: Text(
                    formatarDataCompleta(data),
                    style: const TextStyle(
                      fontFamily: SystemFonts.display,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.9,
                      color: SystemPalette.foreground,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
