import 'package:flutter/material.dart';

Future<void> showLevelUpDialog(
  BuildContext context, {
  required int nivelAnterior,
  required int novoNivel,
}) {
  return showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('LEVEL UP!'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('LV. $nivelAnterior',
              style: Theme.of(context).textTheme.titleMedium),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: Icon(Icons.arrow_downward),
          ),
          Text(
            'LV. $novoNivel',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold),
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
