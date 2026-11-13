import 'package:flutter/material.dart';

import 'system_colors.dart';

/// Gradientes portados de `styles.css`. Ângulos CSS (medidos a partir do
/// topo, sentido horário) convertidos para `Alignment` início/fim — a
/// conversão é aproximada por natureza (o CSS ajusta o ângulo real conforme
/// a proporção do elemento; aqui usamos a proporção quadrada como base,
/// suficiente para a fidelidade visual pretendida).
class SystemGradients {
  const SystemGradients._();

  /// `--gradient-panel`: linear-gradient(150deg, surface-2@65% 0%,
  /// gradientPanelStop2@55% 55%, gradientPanelStop3@70% 100%).
  static const panel = LinearGradient(
    begin: Alignment(-0.5, -0.87),
    end: Alignment(0.5, 0.87),
    stops: [0.0, 0.55, 1.0],
    colors: [
      Color(0xA616243C), // surface2 @ 65%
      Color(0x8C0A1121), // gradientPanelStop2 @ 55%
      Color(0xB3070D1A), // gradientPanelStop3 @ 70%
    ],
  );

  /// `--gradient-xp`: linear-gradient(90deg, stop1 0%, primary 55%, stop3 100%).
  static const xp = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    stops: [0.0, 0.55, 1.0],
    colors: [
      SystemPalette.gradientXpStop1,
      SystemPalette.primary,
      SystemPalette.gradientXpStop3,
    ],
  );

  /// `--gradient-action`: linear-gradient(100deg, stop1 0%, stop2 50%, stop3 100%).
  static const action = LinearGradient(
    begin: Alignment(-0.98, -0.17),
    end: Alignment(0.98, 0.17),
    colors: [
      SystemPalette.gradientActionStop1,
      SystemPalette.gradientActionStop2,
      SystemPalette.gradientActionStop3,
    ],
  );
}

/// Sombras e glows portados de `styles.css`. As sombras `inset` do CSS não
/// têm equivalente direto em `BoxDecoration` — a camada interna de realce
/// (`insetHighlight*`) fica documentada aqui como cor/opacidade, mas a
/// técnica de desenho (ex.: uma hairline sobreposta) é responsabilidade do
/// componente que a usar (Fase 2).
class SystemShadows {
  const SystemShadows._();

  /// `--glow-primary`: `0 0 0 1px primary/25%, 0 0 24px -6px primary/55%`.
  static const glowPrimary = [
    BoxShadow(
      color: Color(0x4000CDFD), // primary @ 25%
      spreadRadius: 1,
    ),
    BoxShadow(
      color: Color(0x8C00CDFD), // primary @ 55%
      blurRadius: 24,
      spreadRadius: -6,
    ),
  ];

  /// `--glow-strong`: `0 0 1px glowStrongTint, 0 0 18px primary/65%`.
  static const glowStrong = [
    BoxShadow(
      color: SystemPalette.glowStrongTint,
      blurRadius: 1,
    ),
    BoxShadow(
      color: Color(0xA600CDFD), // primary @ 65%
      blurRadius: 18,
    ),
  ];

  /// Parte externa de `.panel` (sem a camada `inset`): `0 12px 30px -18px black/90%`.
  static const panelOuter = [
    BoxShadow(
      color: Color(0xE6000000), // black @ 90%
      offset: Offset(0, 12),
      blurRadius: 30,
      spreadRadius: -18,
    ),
  ];

  /// Parte externa de `.panel-glow` (sem a camada `inset`):
  /// `0 0 26px -10px primary/70%, 0 14px 34px -20px black/90%`.
  static const panelGlowOuter = [
    BoxShadow(
      color: Color(0xB300CDFD), // primary @ 70%
      blurRadius: 26,
      spreadRadius: -10,
    ),
    BoxShadow(
      color: Color(0xE6000000), // black @ 90%
      offset: Offset(0, 14),
      blurRadius: 34,
      spreadRadius: -20,
    ),
  ];

  /// Glow colorido genérico usado em badges/estados especiais (rank violeta,
  /// conquista dourada, input de sucesso/erro): no protótipo sempre no formato
  /// `0 0 <blur>px -8px <cor>`. Parametrizado em vez de repetir uma
  /// constante por cor.
  static List<BoxShadow> coloredGlow(
    Color color, {
    double blurRadius = 22,
    double spreadRadius = -8,
  }) {
    return [
      BoxShadow(
          color: color, blurRadius: blurRadius, spreadRadius: spreadRadius),
    ];
  }
}
