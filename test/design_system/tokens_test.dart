import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_system/design_system/system_colors.dart';
import 'package:gym_system/design_system/system_effects.dart';
import 'package:gym_system/design_system/system_geometry.dart';
import 'package:gym_system/design_system/system_motion.dart';
import 'package:gym_system/design_system/system_text_styles.dart';

void main() {
  test('cores principais batem com a conversão oklch -> sRGB do styles.css',
      () {
    expect(SystemPalette.background, const Color(0xFF040915));
    expect(SystemPalette.primary, const Color(0xFF00CDFD));
    expect(SystemPalette.violet, const Color(0xFF9F6FFF));
    expect(SystemPalette.gold, const Color(0xFFF0BB3B));
    expect(SystemPalette.destructive, const Color(0xFFF9324E));
    expect(SystemPalette.success, const Color(0xFF23D891));
  });

  test('gradientes têm as cores e a direção esperadas', () {
    expect(SystemGradients.xp.colors, [
      SystemPalette.gradientXpStop1,
      SystemPalette.primary,
      SystemPalette.gradientXpStop3,
    ]);
    expect(SystemGradients.xp.begin, Alignment.centerLeft);
    expect(SystemGradients.xp.end, Alignment.centerRight);
  });

  test('glow colorido genérico aplica blur e spread informados', () {
    final glow = SystemShadows.coloredGlow(SystemPalette.gold);
    expect(glow.single.color, SystemPalette.gold);
    expect(glow.single.blurRadius, 22);
    expect(glow.single.spreadRadius, -8);
  });

  test('tamanhos de corte diagonal seguem a hierarquia do protótipo', () {
    expect(SystemCutSizes.panel, greaterThan(SystemCutSizes.button));
    expect(SystemCutSizes.button, greaterThan(SystemCutSizes.input));
    expect(SystemCutSizes.input, greaterThan(SystemCutSizes.small));
  });

  test('durações de animação batem com as @keyframes do styles.css', () {
    expect(SystemDurations.panelIn, const Duration(milliseconds: 420));
    expect(
        SystemDurations.levelUpAutoClose, const Duration(milliseconds: 4200));
  });

  test('fontes de texto usam as famílias empacotadas localmente', () {
    expect(SystemTextStyles.label.fontFamily, SystemFonts.display);
    expect(SystemTextStyles.body.fontFamily, SystemFonts.body);
  });
}
