import 'package:flutter/material.dart';

import '../domain/mission.dart';

Future<void> showMissionsCompletedDialog(
  BuildContext context,
  List<Mission> missoes,
) {
  return showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('MISSÃO CONCLUÍDA'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final missao in missoes)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(missao.nome,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text('+${missao.recompensaXp} XP'),
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
