import 'package:flutter/material.dart';

import '../domain/achievement.dart';

Future<void> showAchievementsUnlockedDialog(
  BuildContext context,
  List<Achievement> conquistas,
) {
  return showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('CONQUISTA DESBLOQUEADA'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final conquista in conquistas)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(conquista.nome,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(conquista.descricao),
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
