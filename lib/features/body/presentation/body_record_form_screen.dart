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
import '../../profile/presentation/option_tile.dart';
import '../../profile/presentation/profile_providers.dart';
import '../domain/body.dart';
import 'body_providers.dart';
import '../../achievements/presentation/achievement_notifier.dart';
import 'body_summary.dart';

/// Novo registro corporal ou edição de um existente. Os valores são digitados
/// nas unidades do usuário (kg/lb, cm/pol) e gravados em kg/cm. Sair sem
/// tocar em "Salvar" descarta tudo.
class BodyRecordFormScreen extends ConsumerStatefulWidget {
  const BodyRecordFormScreen({super.key, this.recordId});

  /// `null` = novo registro.
  final int? recordId;

  @override
  ConsumerState<BodyRecordFormScreen> createState() =>
      _BodyRecordFormScreenState();
}

class _BodyRecordFormScreenState extends ConsumerState<BodyRecordFormScreen> {
  final _controllers = {
    for (final m in BodyMeasure.values) m: TextEditingController(),
  };
  late DateTime _data = _hoje();
  bool _preenchido = false;
  String? _erro;

  static DateTime _hoje() {
    final a = DateTime.now();
    return DateTime(a.year, a.month, a.day);
  }

  @override
  void initState() {
    super.initState();
    if (widget.recordId == null) _preenchido = true;
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _preencher(BodyRecord r) {
    final units = ref.read(unitsProvider);
    _data = r.data;
    for (final m in BodyMeasure.values) {
      final v = m.de(r);
      _controllers[m]!.text =
          v == null ? '' : _limpo(m.paraExibir(v, units).toStringAsFixed(1));
    }
    _preenchido = true;
  }

  String _limpo(String t) =>
      t.endsWith('.0') ? t.substring(0, t.length - 2) : t;

  Future<void> _escolherData() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _data,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (d != null) setState(() => _data = DateTime(d.year, d.month, d.day));
  }

  Future<void> _salvar() async {
    final units = ref.read(unitsProvider);
    final valores = <BodyMeasure, double?>{};
    for (final m in BodyMeasure.values) {
      final t = _controllers[m]!.text.trim().replaceAll(',', '.');
      if (t.isEmpty) {
        valores[m] = null;
        continue;
      }
      final v = double.tryParse(t);
      if (v == null || v <= 0 || (m.ehGordura && v >= 100)) {
        setState(() => _erro = '${m.label}: valor inválido.');
        return;
      }
      valores[m] = m.paraBanco(v, units);
    }
    final input = BodyRecordInput(
      data: _data,
      pesoKg: valores[BodyMeasure.peso],
      gorduraPct: valores[BodyMeasure.gordura],
      bracoCm: valores[BodyMeasure.braco],
      peitoCm: valores[BodyMeasure.peito],
      cinturaCm: valores[BodyMeasure.cintura],
      quadrilCm: valores[BodyMeasure.quadril],
      coxaCm: valores[BodyMeasure.coxa],
      panturrilhaCm: valores[BodyMeasure.panturrilha],
    );
    final ok = await ref
        .read(bodyRepositoryProvider)
        .salvar(input, id: widget.recordId);
    if (!ok) {
      setState(() => _erro = 'Informe ao menos um valor.');
      return;
    }
    if (mounted) await conferirConquistas(context, ref);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final units = ref.watch(unitsProvider);
    if (!_preenchido) {
      final r = ref.watch(bodyRecordProvider(widget.recordId!));
      final registro = r.valueOrNull;
      if (registro != null) _preencher(registro);
    }

    return SystemScaffold(
      title: widget.recordId == null ? 'NOVO REGISTRO' : 'EDITAR REGISTRO',
      subtitle: 'CORPO',
      leading: const SystemBackButton(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SystemPanel(
            title: 'DATA',
            child: Align(
              alignment: Alignment.centerLeft,
              child: OptionTile(
                key: const Key('body_date'),
                selected: true,
                semanticLabel: 'Data do registro',
                onTap: _escolherData,
                child: OptionLabel(formatarDataBr(_data), selected: true),
              ),
            ),
          ),
          const SizedBox(height: SystemSpacing.lg),
          SystemPanel(
            title: 'MEDIDAS (TODAS OPCIONAIS)',
            child: Column(
              children: [
                for (final m in BodyMeasure.values) ...[
                  SystemTextField(
                    key: Key('body_field_${m.name}'),
                    label: m.label,
                    controller: _controllers[m],
                    suffix: m.sufixo(units),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: SystemSpacing.md),
                ],
                if (_erro != null)
                  Text(_erro!,
                      key: const Key('body_erro'),
                      style: SystemTextStyles.body
                          .copyWith(color: SystemPalette.destructive)),
              ],
            ),
          ),
          const SizedBox(height: SystemSpacing.lg),
          SystemButton(
            key: const Key('body_salvar'),
            label: 'Salvar',
            variant: SystemButtonVariant.action,
            size: SystemButtonSize.lg,
            onPressed: _salvar,
          ),
        ],
      ),
    );
  }
}
