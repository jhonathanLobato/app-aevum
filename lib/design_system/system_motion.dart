import 'package:flutter/animation.dart';

/// Durações portadas das `@keyframes`/transições de `styles.css` e dos
/// componentes `.tsx`.
class SystemDurations {
  const SystemDurations._();

  /// `panel-in`: entrada de painel (fade + slide + blur-out).
  static const panelIn = Duration(milliseconds: 420);

  /// `level-burst`: escala de entrada do painel de level up.
  static const levelBurst = Duration(milliseconds: 520);

  /// `ring-expand`: anéis se expandindo no level up (looping).
  static const ringExpand = Duration(milliseconds: 1400);

  /// `float-up`: partículas subindo no level up.
  static const floatUp = Duration(milliseconds: 1200);

  /// `xp-shine`: brilho varrendo a barra de XP. No protótipo é um loop
  /// contínuo; na Fase 9 vira uma varredura única disparada só quando o XP
  /// realmente aumenta (ver [SystemXpBar]) — reaproveita a mesma duração do
  /// CSS original pra manter a sensação de velocidade do efeito, sem
  /// manter nenhuma animação rodando à toa.
  static const xpShine = Duration(milliseconds: 2600);

  /// `sys-pulse`: pulso do indicador "ONLINE" (looping — uma das poucas
  /// animações contínuas autorizadas na Fase 9, isolada num widget pequeno).
  static const sysPulse = Duration(milliseconds: 2000);

  /// Fase 9: intervalo entre a entrada de um painel e o próximo, quando uma
  /// tela tem vários painéis em sequência (`panel-in` com stagger discreto).
  static const staggerStep = Duration(milliseconds: 60);

  /// Fase 9: quanto tempo a borda de destaque de uma série recém-registrada
  /// fica acesa antes de voltar ao estado normal.
  static const setHighlight = Duration(milliseconds: 900);

  /// Preenchimento animado da barra de XP (`transition-[width]` no XpBar).
  static const xpFill = Duration(milliseconds: 1200);

  /// Shine do botão ao passar/tocar (`duration-700` no SystemButton).
  static const buttonShine = Duration(milliseconds: 700);

  /// `.press`: feedback de toque — transform.
  static const pressTransform = Duration(milliseconds: 120);

  /// `.press`: feedback de toque — sombra/cor de fundo.
  static const pressDecoration = Duration(milliseconds: 200);

  /// Tempo até o `LevelUpOverlay` fechar sozinho.
  static const levelUpAutoClose = Duration(milliseconds: 4200);
}

/// Curvas portadas das `cubic-bezier()` e `ease-*` de `styles.css`.
class SystemCurves {
  const SystemCurves._();

  /// `panel-in`: `cubic-bezier(0.2, 0.8, 0.2, 1)`.
  static const panelIn = Cubic(0.2, 0.8, 0.2, 1);

  /// `level-burst`: `cubic-bezier(0.2, 0.9, 0.2, 1)`.
  static const levelBurst = Cubic(0.2, 0.9, 0.2, 1);

  /// `ring-expand` / `float-up`: `ease-out`.
  static const easeOut = Curves.easeOut;

  /// `xp-shine` / `sys-pulse`: `ease-in-out`.
  static const easeInOut = Curves.easeInOut;

  /// `.press`: transições simples (`ease`).
  static const press = Curves.ease;
}
