import 'package:flutter/material.dart';

/// Paleta portada de `styles.css` (Lovable), bloco `:root`, todo definido
/// originalmente em `oklch()`.
///
/// Os valores abaixo são o resultado já calculado da conversão OKLCH → sRGB
/// (ver script de desenvolvimento usado para gerar estes valores — a
/// conversão não roda em tempo de execução, só os `Color` finais). Cada
/// constante documenta o token oklch de origem para rastreabilidade.
class SystemPalette {
  const SystemPalette._();

  /// oklch(0.14 0.03 265) — `--background`. Também usado como
  /// `--primary-foreground` e `--accent-foreground` no Lovable.
  static const background = Color(0xFF040915);

  /// oklch(0.96 0.01 240) — `--foreground` / `--card-foreground` /
  /// `--popover-foreground`.
  static const foreground = Color(0xFFECF3F8);

  /// oklch(0.2 0.04 262) — `--surface` / `--card` (cor base; o Lovable usa
  /// isso sempre com alpha ~55%, ver [SystemOpacities.surface]).
  static const surface = Color(0xFF0C1628);

  /// oklch(0.26 0.05 262) — `--surface-2` (base; alpha ~45%, ver
  /// [SystemOpacities.surface2]). Também o primeiro stop do gradient-panel.
  static const surface2 = Color(0xFF16243C);

  /// oklch(0.17 0.035 263) — `--popover`.
  static const popover = Color(0xFF070F1F);

  /// oklch(0.78 0.16 220) — `--primary`. Ciano/azul neon, cor de identidade
  /// principal do sistema. Também a base de `--border`, `--input` e
  /// `--ring` (sempre primary com alpha, ver [SystemOpacities]).
  static const primary = Color(0xFF00CDFD);

  /// oklch(0.28 0.05 262) — `--secondary`.
  static const secondary = Color(0xFF1B2942);

  /// oklch(0.93 0.02 240) — `--secondary-foreground`.
  static const secondaryForeground = Color(0xFFDCEAF4);

  /// oklch(0.24 0.04 262) — `--muted`.
  static const muted = Color(0xFF151F32);

  /// oklch(0.68 0.04 245) — `--muted-foreground`.
  static const mutedForeground = Color(0xFF849BB0);

  /// oklch(0.72 0.17 255) — `--accent`.
  static const accent = Color(0xFF53A6FF);

  /// oklch(0.66 0.21 295) — `--violet`. Usado em rank badge e destaques
  /// especiais.
  static const violet = Color(0xFF9F6FFF);

  /// oklch(0.82 0.15 85) — `--gold`. Recompensas e conquistas desbloqueadas.
  static const gold = Color(0xFFF0BB3B);

  /// oklch(0.78 0.17 160) — `--success`.
  static const success = Color(0xFF23D891);

  /// oklch(0.64 0.23 20) — `--destructive`.
  static const destructive = Color(0xFFF9324E);

  /// oklch(0.97 0.01 240) — `--destructive-foreground`.
  static const destructiveForeground = Color(0xFFEFF6FB);

  // ---- Cores usadas em gradientes e glows (fora do bloco de cores
  // semânticas do :root, mas ainda definidas em oklch no styles.css) ----

  /// oklch(0.18 0.035 264) — stop 2 do `--gradient-panel`.
  static const gradientPanelStop2 = Color(0xFF0A1121);

  /// oklch(0.16 0.03 266) — stop 3 do `--gradient-panel`.
  static const gradientPanelStop3 = Color(0xFF070D1A);

  /// oklch(0.6 0.18 255) — stop 1 do `--gradient-xp`.
  static const gradientXpStop1 = Color(0xFF207FE8);

  /// oklch(0.92 0.12 200) — stop 3 do `--gradient-xp`.
  static const gradientXpStop3 = Color(0xFF73FDFF);

  /// oklch(0.42 0.14 250) — stop 1 do `--gradient-action`.
  static const gradientActionStop1 = Color(0xFF004E95);

  /// oklch(0.62 0.18 228) — stop 2 do `--gradient-action`.
  static const gradientActionStop2 = Color(0xFF0097DA);

  /// oklch(0.45 0.15 245) — stop 3 do `--gradient-action`.
  static const gradientActionStop3 = Color(0xFF0058A1);

  /// oklch(0.85 0.15 220) — cor quase branca do `--glow-strong`.
  static const glowStrongTint = Color(0xFF24E3FF);

  /// oklch(0.45 0.16 250) — glow radial azul no topo do fundo do app.
  static const backdropGlowBlue = Color(0xFF0055A9);

  /// oklch(0.5 0.19 295) — glow radial violeta na base do fundo do app.
  static const backdropGlowViolet = Color(0xFF6F41C1);

  /// oklch(0.9 0.05 220) — realce quase branco usado no highlight interno
  /// dos painéis e no tingimento sutil do scanline.
  static const insetHighlight = Color(0xFFBAE7F5);
}

/// Níveis de opacidade usados repetidamente em `styles.css`, extraídos dos
/// tokens e utilities (`--border`, `--glow-*`, gradientes, scanline etc.).
/// Use com `SystemPalette.x.withValues(alpha: SystemOpacities.y)`.
class SystemOpacities {
  const SystemOpacities._();

  /// Linhas do grid de fundo (`background-image` do body): 4%.
  static const gridLines = 0.04;

  /// Linhas do scanline (`@utility scanline`): 3%.
  static const scanline = 0.03;

  /// Realce interno (inset) no topo dos painéis: 10%.
  static const insetHighlightSoft = 0.10;

  /// Realce interno dos painéis com glow (`panel-glow`): 12%.
  static const insetHighlightGlow = 0.12;

  /// `--surface` usado como fundo de painel: 55%.
  static const surface = 0.55;

  /// `--surface-2` usado como fundo de painel secundário: 45%.
  static const surface2 = 0.45;

  /// `--border`: primary a 22%.
  static const border = 0.22;

  /// `--input`: primary a 25%.
  static const input = 0.25;

  /// Glow radial violeta de fundo: 16%.
  static const backdropGlowViolet = 0.16;

  /// Glow radial azul de fundo: 28%.
  static const backdropGlowBlue = 0.28;

  /// `--ring` e divisores de destaque (`divider-tech`): ~55–60%.
  static const divider = 0.55;
  static const ring = 0.60;

  /// Sombra preta usada nos painéis (parte de fora do glow): 90%.
  static const panelShadow = 0.90;

  /// `--glow-primary` (camada externa): 55%.
  static const glowPrimary = 0.55;

  /// `--glow-strong` (camada externa): 65%.
  static const glowStrong = 0.65;

  /// Texto com glow (`text-glow`, `text-glow-violet`): 70%.
  static const textGlow = 0.70;

  /// Brilho (shine) que passa pela barra de XP, sobre o foreground: 35%.
  static const shineHighlight = 0.35;

  /// Sombra da barra de XP preenchida: 80%.
  static const xpFillShadow = 0.80;

  /// Seleção de texto (`::selection`): 35%.
  static const selection = 0.35;

  /// `disabled:opacity-40`, usado em botões e inputs desabilitados: 40%.
  static const disabled = 0.40;

  /// Divisórias verticais dentro da barra de XP (`border-primary/10`): 10%.
  static const xpSegmentDivider = 0.10;
}
