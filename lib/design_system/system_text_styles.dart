import 'package:flutter/material.dart';

import 'system_colors.dart';

/// Nomes das famílias de fonte, empacotadas localmente (ver pubspec.yaml e
/// `assets/fonts/`). Nunca depender de fontes buscadas em tempo de execução
/// (app offline-first).
class SystemFonts {
  const SystemFonts._();

  /// `--font-display`: títulos, números, labels de sistema e botões.
  static const display = 'Orbitron';

  /// `--font-sans`: texto corrido (descrições, hints).
  static const body = 'Rajdhani';
}

/// Hierarquia tipográfica portada dos componentes do Lovable. Cobre os
/// papéis que se repetem; variações pontuais de tamanho por tela ficam a
/// cargo do componente (Fase 2+), usando `.copyWith(...)` sobre estes
/// estilos base.
class SystemTextStyles {
  const SystemTextStyles._();

  /// "LEVEL UP" no overlay de subida de nível: text-4xl, font-black,
  /// tracking-[0.2em].
  static const displayHero = TextStyle(
    fontFamily: SystemFonts.display,
    fontSize: 36,
    fontWeight: FontWeight.w900,
    letterSpacing: 7.2, // 0.2em de 36px
    color: SystemPalette.foreground,
  );

  /// Nome do jogador / números grandes de destaque: text-2xl, font-black,
  /// tracking-[0.12em].
  static const displayLarge = TextStyle(
    fontFamily: SystemFonts.display,
    fontSize: 24,
    fontWeight: FontWeight.w900,
    letterSpacing: 2.88,
    color: SystemPalette.foreground,
  );

  /// Números de estatística (STATUS): text-3xl, font-black, tracking-tight.
  static const displayStat = TextStyle(
    fontFamily: SystemFonts.display,
    fontSize: 30,
    fontWeight: FontWeight.w900,
    letterSpacing: -0.5,
    color: SystemPalette.foreground,
  );

  /// Títulos de seção/painel ("TREINO A", "LV. 12"): text-xl/lg, font-black,
  /// tracking-[0.1–0.18em].
  static const displayMedium = TextStyle(
    fontFamily: SystemFonts.display,
    fontSize: 20,
    fontWeight: FontWeight.w900,
    letterSpacing: 2.4,
    color: SystemPalette.foreground,
  );

  /// Título de card/quest ("Complete o Treino A"): text-base, font-bold,
  /// tracking-wide.
  static const displaySmall = TextStyle(
    fontFamily: SystemFonts.display,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.5,
    color: SystemPalette.foreground,
  );

  /// `label-sys`: a label mais usada no sistema — pequena, uppercase,
  /// bastante espaçada. 0.625rem, font-semibold, tracking-[0.22em].
  static const label = TextStyle(
    fontFamily: SystemFonts.display,
    fontSize: 10,
    fontWeight: FontWeight.w600,
    letterSpacing: 2.2,
    color: SystemPalette.mutedForeground,
  );

  /// Kicker de botão ("SYSTEM ACTION"): 0.5rem.
  static const labelTiny = TextStyle(
    fontFamily: SystemFonts.display,
    fontSize: 8,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.76,
  );

  /// Texto de botão: text-xs/sm, font-bold, tracking-[0.18em], uppercase.
  static const button = TextStyle(
    fontFamily: SystemFonts.display,
    fontSize: 12,
    fontWeight: FontWeight.w700,
    letterSpacing: 2.16,
    color: SystemPalette.foreground,
  );

  /// Corpo de texto padrão (descrições): Rajdhani, text-sm, medium.
  static const body = TextStyle(
    fontFamily: SystemFonts.body,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: SystemPalette.foreground,
  );

  /// Texto secundário/hint/erro: Rajdhani, text-xs.
  static const bodySmall = TextStyle(
    fontFamily: SystemFonts.body,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: SystemPalette.mutedForeground,
  );

  /// `text-glow`: sombra ciano aplicada sobre texto (primary @ 70%).
  static const glowPrimary = [
    Shadow(color: Color(0xB300CDFD), blurRadius: 12),
  ];

  /// `text-glow-violet`: sombra violeta aplicada sobre texto (violet @ 70%).
  static const glowViolet = [
    Shadow(color: Color(0xB39F6FFF), blurRadius: 14),
  ];
}
