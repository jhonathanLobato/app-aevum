import 'package:flutter/material.dart';

import '../../progression/domain/personal_record.dart';

Future<void> showPrDetectedDialog(
  BuildContext context, {
  required String exerciseNome,
  required List<PersonalRecordBreak> prs,
}) {
  return showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('PR DETECTADO'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(exerciseNome, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          for (final pr in prs)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Novo recorde de ${_labelTipo(pr.tipo)}: '
                    '${_formatarValor(pr.tipo, pr.valorNovo)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (pr.valorAnterior != null)
                    Text(
                      'Recorde anterior: ${_formatarValor(pr.tipo, pr.valorAnterior!)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}

String _labelTipo(PersonalRecordType tipo) {
  switch (tipo) {
    case PersonalRecordType.carga:
      return 'carga';
    case PersonalRecordType.repeticoes:
      return 'repetições';
    case PersonalRecordType.volume:
      return 'volume';
  }
}

String _formatarValor(PersonalRecordType tipo, double valor) {
  switch (tipo) {
    case PersonalRecordType.carga:
      return '${valor.toStringAsFixed(1)}kg';
    case PersonalRecordType.repeticoes:
      return valor.toStringAsFixed(0);
    case PersonalRecordType.volume:
      return '${valor.toStringAsFixed(0)}kg';
  }
}
