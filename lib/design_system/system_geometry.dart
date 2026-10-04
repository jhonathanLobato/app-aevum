/// Constantes geométricas da identidade visual "cortes diagonais".
///
/// O Lovable usa `clip-path: polygon(...)` para cortar dois cantos opostos
/// (superior-esquerdo + inferior-direito) de painéis, botões, inputs e
/// elementos de navegação, em tamanhos diferentes por componente. O
/// `RankBadge` e os ícones de conquista usam uma forma diferente — um
/// hexágono completo, sem relação com o tamanho de corte.
///
/// Esta classe só guarda os números; os `CustomClipper`s que de fato
/// recortam os widgets ficam na Fase 2 (Componentes básicos).
class SystemCutSizes {
  const SystemCutSizes._();

  /// Painéis (`Panel`): 14px.
  static const panel = 14.0;

  /// Botões (`SystemButton`): 12px.
  static const button = 12.0;

  /// Campos de entrada (`SystemInput`): 8px.
  static const input = 8.0;

  /// Caixa do ícone ativo na navegação e trilho da barra de XP: 6px.
  static const small = 6.0;
}

/// Espessura de borda — sempre 1px (hairline) em toda a interface do Lovable.
class SystemBorders {
  const SystemBorders._();

  static const hairline = 1.0;
}

/// `--radius` e derivados de `styles.css`. Portados por completude, mas
/// pouco usados na prática: a identidade visual usa cortes diagonais
/// (`SystemCutSizes`), não cantos arredondados.
class SystemRadius {
  const SystemRadius._();

  static const base = 4.0; // --radius: 0.25rem
  static const sm = 0.0; // --radius-sm: calc(var(--radius) - 4px)
  static const md = 2.0; // --radius-md: calc(var(--radius) - 2px)
  static const lg = 4.0; // --radius-lg: var(--radius)
  static const xl = 8.0; // --radius-xl: calc(var(--radius) + 4px)
  static const xl2 = 12.0; // --radius-2xl: calc(var(--radius) + 8px)
}
