import 'package:flutter/material.dart';

import 'system_colors.dart';

/// Botão de voltar do header das telas secundárias (fora das 5 abas, sem
/// `AppBar`). Usa `Navigator.maybePop` pra funcionar igual ao botão voltar
/// do Android, independente do roteador.
class SystemBackButton extends StatelessWidget {
  const SystemBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      color: SystemPalette.mutedForeground,
      tooltip: 'Voltar',
      onPressed: () => Navigator.of(context).maybePop(),
    );
  }
}
