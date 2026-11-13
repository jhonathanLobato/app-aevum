import 'package:flutter/widgets.dart';

import 'system_colors.dart';
import 'system_geometry.dart';

/// Reproduz o clip-path diagonal usado em `.panel`, `SystemButton`,
/// `SystemInput` e `XpBar` no protótipo: corta o canto superior-esquerdo e o
/// canto inferior-direito em diagonal, mantendo os outros dois cantos retos.
/// `cutSize` vem de [SystemCutSizes] (14 painel, 12 botão, 8 input, 6 xp
/// bar/navegação) e é automaticamente limitado ao tamanho do widget, para
/// não quebrar em componentes muito pequenos.
class DiagonalCutCornersClipper extends CustomClipper<Path> {
  const DiagonalCutCornersClipper(this.cutSize);

  final double cutSize;

  @override
  Path getClip(Size size) {
    final cut = cutSize.clamp(0.0, size.shortestSide / 2);
    return Path()
      ..moveTo(cut, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height - cut)
      ..lineTo(size.width - cut, size.height)
      ..lineTo(0, size.height)
      ..lineTo(0, cut)
      ..close();
  }

  @override
  bool shouldReclip(covariant DiagonalCutCornersClipper oldClipper) =>
      oldClipper.cutSize != cutSize;
}

/// Hexágono vertical (ponta em cima/embaixo, lados retos à esquerda/direita)
/// usado no `RankBadge` e, futuramente, em badges de conquista. Os pontos
/// são frações do tamanho do widget (0%/25%/75%/100%), iguais ao clip-path
/// original, então a forma funciona para qualquer tamanho.
class HexagonClipper extends CustomClipper<Path> {
  const HexagonClipper();

  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;
    return Path()
      ..moveTo(w * 0.5, 0)
      ..lineTo(w, h * 0.25)
      ..lineTo(w, h * 0.75)
      ..lineTo(w * 0.5, h)
      ..lineTo(0, h * 0.75)
      ..lineTo(0, h * 0.25)
      ..close();
  }

  @override
  bool shouldReclip(covariant HexagonClipper oldClipper) => false;
}

/// Marcas em "L" nos cantos superior-direito e inferior-esquerdo
/// (`@utility corner-ticks` do styles.css), usadas em `Panel`,
/// `LevelUpOverlay` (Fase 10) e `SystemNav` (Fase 4). Desenho estático via
/// `CustomPainter` — duas linhas por canto, sem recálculo em rebuilds.
class CornerTicks extends StatelessWidget {
  const CornerTicks({super.key});

  @override
  Widget build(BuildContext context) {
    return const CustomPaint(
      painter: _CornerTicksPainter(),
      size: Size.infinite,
    );
  }
}

class _CornerTicksPainter extends CustomPainter {
  const _CornerTicksPainter();

  static const _tickSize = 10.0;
  static const _inset = 4.0;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = SystemPalette.primary.withValues(alpha: 0.8)
      ..strokeWidth = SystemBorders.hairline
      ..style = PaintingStyle.stroke;

    // Canto superior-direito.
    canvas.drawLine(
      Offset(size.width - _inset - _tickSize, _inset),
      Offset(size.width - _inset, _inset),
      paint,
    );
    canvas.drawLine(
      Offset(size.width - _inset, _inset),
      Offset(size.width - _inset, _inset + _tickSize),
      paint,
    );

    // Canto inferior-esquerdo.
    canvas.drawLine(
      Offset(_inset, size.height - _inset - _tickSize),
      Offset(_inset, size.height - _inset),
      paint,
    );
    canvas.drawLine(
      Offset(_inset, size.height - _inset),
      Offset(_inset + _tickSize, size.height - _inset),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _CornerTicksPainter oldDelegate) => false;
}
