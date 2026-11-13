import 'package:flutter/material.dart';

import 'system_background.dart';
import 'system_colors.dart';
import 'system_geometry.dart';
import 'system_online_indicator.dart';
import 'system_spacing.dart';
import 'system_text_styles.dart';

/// Cabeçalho padrão das telas do sistema, direto do `<header>` de
/// `SystemLayout.tsx`: título em Orbitron, subtítulo opcional (`label-sys`),
/// indicador "SYSTEM ONLINE" e ações opcionais.
///
/// O ponto verde do indicador respira lentamente (`sys-pulse`, Fase 9) —
/// ver [SystemOnlineIndicator] pra como isso fica isolado do resto do
/// cabeçalho e pausa sozinho quando a aba não está em foco.
///
/// Diferença deliberada do protótipo: lá o header é `position: sticky` com
/// `backdrop-blur-xl` por cima do conteúdo que rola por baixo dele. Aqui
/// ele fica num slot fixo, acima da área rolável, não sobreposto a ela —
/// uma blur "sticky" de verdade precisaria recalcular o blur a cada frame
/// de scroll, caro no Android. O visual (fundo escuro translúcido + borda
/// inferior ciano) fica praticamente igual sem esse custo.
class SystemHeader extends StatelessWidget {
  const SystemHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    this.leading,
  });

  final String title;
  final String? subtitle;
  final List<Widget>? actions;

  /// Widget opcional antes do título (ex.: botão de voltar numa tela
  /// secundária em tela cheia, como o treino ativo). `null` por padrão —
  /// as telas das 6 abas principais não precisam de um.
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: SystemPalette.background.withValues(alpha: 0.8),
        border: Border(
          bottom: BorderSide(
            color:
                SystemPalette.primary.withValues(alpha: SystemOpacities.border),
            width: SystemBorders.hairline,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: SystemSpacing.xl, vertical: SystemSpacing.md),
        child: Row(
          children: [
            if (leading != null) ...[
              leading!,
              const SizedBox(width: SystemSpacing.sm)
            ],
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: SystemFonts.display,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 4.2, // tracking-[0.3em] de 14px
                      color: SystemPalette.foreground,
                    ),
                  ),
                  if (subtitle != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        subtitle!.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: SystemTextStyles.label.copyWith(
                          fontSize: 8.8, // 0.55rem
                          letterSpacing: 1.94, // tracking-[0.22em] de 8.8px
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (actions != null) ...[
              const SizedBox(width: SystemSpacing.sm),
              ...actions!,
            ],
            const SizedBox(width: SystemSpacing.sm),
            const SystemOnlineIndicator(),
            const SizedBox(width: SystemSpacing.xs),
            Text(
              'ONLINE',
              style: SystemTextStyles.label.copyWith(
                fontSize: 8.8,
                letterSpacing: 1.94,
                color: SystemPalette.success,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Estrutura base das telas do sistema, direto de `SystemLayout.tsx`.
///
/// Puramente de apresentação: não conhece XP, treino, missão, usuário nem
/// banco de dados — só recebe título, subtítulo, corpo e ações já prontos.
/// A navegação da Fase 4 (`SystemNavigationBar`) é passada de fora via
/// [navigationBar], sem exigir mudanças nesta API quando ela existir.
class SystemScaffold extends StatelessWidget {
  const SystemScaffold({
    super.key,
    required this.title,
    required this.body,
    this.subtitle,
    this.actions,
    this.leading,
    this.header,
    this.navigationBar,
    this.scrollable = true,
    this.applyTopSafeArea = true,
    this.applyBottomSafeArea = true,
    this.bodyPadding = const EdgeInsets.fromLTRB(
      SystemSpacing.xl,
      SystemSpacing.xl,
      SystemSpacing.xl,
      SystemSpacing.xl2,
    ),
  });

  final String title;
  final String? subtitle;
  final Widget body;

  /// Ações exibidas no cabeçalho, entre o título e o indicador "ONLINE".
  final List<Widget>? actions;

  /// Widget antes do título no header padrão — usado pelas telas
  /// secundárias (fora das 6 abas) pra oferecer um botão de voltar visível
  /// (ver [SystemBackButton]).
  final Widget? leading;

  /// Substitui o header padrão inteiro (título + subtítulo + ONLINE) por um
  /// widget próprio, para telas que precisem de algo diferente.
  final Widget? header;

  /// Slot fixo abaixo do corpo — a `SystemNavigationBar` das 6 abas
  /// principais (Fase 4), mas serve pra qualquer barra de ação fixa no
  /// rodapé (ex.: "Finalizar treino" na sessão ativa, Fase 6). Quando
  /// informado, a `SafeArea` inferior passa a ser responsabilidade dele.
  final Widget? navigationBar;

  /// Envolve [body] num `SingleChildScrollView`. Desligue quando [body] já
  /// gerencia seu próprio scroll (ex.: uma `ListView`), para não aninhar
  /// dois scrolls.
  final bool scrollable;

  final bool applyTopSafeArea;
  final bool applyBottomSafeArea;
  final EdgeInsetsGeometry bodyPadding;

  @override
  Widget build(BuildContext context) {
    final content = Padding(padding: bodyPadding, child: body);

    return Scaffold(
      backgroundColor: SystemPalette.background,
      body: SystemBackground(
        child: SafeArea(
          top: applyTopSafeArea,
          bottom: applyBottomSafeArea && navigationBar == null,
          child: Column(
            children: [
              header ??
                  SystemHeader(
                      title: title,
                      subtitle: subtitle,
                      actions: actions,
                      leading: leading),
              Expanded(
                child: scrollable
                    ? SingleChildScrollView(child: content)
                    : content,
              ),
              if (navigationBar != null) navigationBar!,
            ],
          ),
        ),
      ),
    );
  }
}
