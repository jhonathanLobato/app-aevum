import 'package:flutter/material.dart';

import 'system_clippers.dart';
import 'system_colors.dart';
import 'system_effects.dart';
import 'system_geometry.dart';
import 'system_motion.dart';
import 'system_spacing.dart';
import 'system_text_styles.dart';

/// Estado visual de [SystemTextField] (`status` em `SystemInput.tsx`).
enum SystemFieldStatus { idle, success, error }

/// Campo de texto do sistema, direto de `SystemInput.tsx`.
///
/// Este componente é usado intensamente durante o treino, então prioriza UX
/// sobre cópia literal do visual: mantém a área de toque e o foco padrão do
/// Flutter, aceita `keyboardType` (teclado numérico para carga/repetições) e
/// expõe o campo para leitores de tela via [Semantics].
///
/// Decisão de cascata CSS: no `SystemInput.tsx` original, `focus-within:`
/// e as classes de `status` disputam a mesma borda/sombra. Aqui [status]
/// sempre vence quando é `success`/`error` — mesmo com foco, o usuário
/// continua vendo que o campo está com problema — e o destaque de foco
/// (ciano) só aparece quando [status] é `idle`.
class SystemTextField extends StatefulWidget {
  const SystemTextField({
    super.key,
    required this.label,
    this.controller,
    this.placeholder,
    this.hint,
    this.icon,
    this.suffix,
    this.keyboardType,
    this.textInputAction,
    this.status = SystemFieldStatus.idle,
    this.enabled = true,
    this.autofocus = false,
    this.maxLines = 1,
    this.focusNode,
    this.onChanged,
    this.onSubmitted,
  });

  final String label;
  final TextEditingController? controller;

  /// Texto de exemplo dentro do campo. Não existe em `SystemInputProps`
  /// como prop nomeada, mas o componente original aceita qualquer atributo
  /// nativo de `<input>` via spread — incluído aqui por ser essencial para
  /// a UX de preenchimento rápido durante o treino.
  final String? placeholder;

  /// Mensagem auxiliar/erro abaixo do campo (`hint` em `SystemInput.tsx`).
  final String? hint;

  final Widget? icon;
  final String? suffix;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final SystemFieldStatus status;
  final bool enabled;
  final bool autofocus;

  /// Linhas do campo (observações usam mais de uma).
  final int maxLines;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  State<SystemTextField> createState() => _SystemTextFieldState();
}

class _SystemTextFieldState extends State<SystemTextField> {
  late final FocusNode _focusNode;
  late final bool _ownsFocusNode;
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _ownsFocusNode = widget.focusNode == null;
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_handleFocusChange);
  }

  void _handleFocusChange() {
    if (_focused == _focusNode.hasFocus) return;
    setState(() => _focused = _focusNode.hasFocus);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    if (_ownsFocusNode) _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isError = widget.status == SystemFieldStatus.error;
    final isSuccess = widget.status == SystemFieldStatus.success;

    final Color borderColor;
    final List<BoxShadow>? boxShadow;
    if (isSuccess) {
      borderColor = SystemPalette.success.withValues(alpha: 0.7);
      boxShadow =
          SystemShadows.coloredGlow(SystemPalette.success, blurRadius: 18);
    } else if (isError) {
      borderColor = SystemPalette.destructive.withValues(alpha: 0.7);
      boxShadow =
          SystemShadows.coloredGlow(SystemPalette.destructive, blurRadius: 18);
    } else if (_focused) {
      borderColor = SystemPalette.primary;
      boxShadow = SystemShadows.glowPrimary;
    } else {
      borderColor =
          SystemPalette.primary.withValues(alpha: SystemOpacities.input);
      boxShadow = null;
    }

    return Opacity(
      opacity: widget.enabled ? 1 : SystemOpacities.disabled,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child:
                Text(widget.label.toUpperCase(), style: SystemTextStyles.label),
          ),
          ClipPath(
            clipper: const DiagonalCutCornersClipper(SystemCutSizes.input),
            child: AnimatedContainer(
              duration: SystemDurations.pressDecoration,
              curve: SystemCurves.press,
              decoration: BoxDecoration(
                color: SystemPalette.background.withValues(alpha: 0.6),
                border: Border.all(
                    color: borderColor, width: SystemBorders.hairline),
                boxShadow: boxShadow,
              ),
              padding: const EdgeInsets.symmetric(
                  horizontal: SystemSpacing.md, vertical: 10),
              child: Row(
                children: [
                  if (widget.icon != null) ...[
                    IconTheme(
                      data: IconThemeData(
                        color: SystemPalette.primary.withValues(alpha: 0.8),
                        size: 18,
                      ),
                      child: widget.icon!,
                    ),
                    const SizedBox(width: SystemSpacing.sm),
                  ],
                  Expanded(
                    child: Semantics(
                      label: widget.label,
                      child: TextField(
                        controller: widget.controller,
                        focusNode: _focusNode,
                        enabled: widget.enabled,
                        autofocus: widget.autofocus,
                        maxLines: widget.maxLines,
                        keyboardType: widget.keyboardType,
                        textInputAction: widget.textInputAction,
                        onChanged: widget.onChanged,
                        onSubmitted: widget.onSubmitted,
                        cursorColor: SystemPalette.primary,
                        style: const TextStyle(
                          fontFamily: SystemFonts.display,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.9,
                          color: SystemPalette.foreground,
                        ),
                        decoration: InputDecoration(
                          isDense: true,
                          isCollapsed: true,
                          border: InputBorder.none,
                          hintText: widget.placeholder,
                          hintStyle: TextStyle(
                            fontFamily: SystemFonts.display,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.9,
                            color: SystemPalette.mutedForeground
                                .withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (widget.suffix != null) ...[
                    const SizedBox(width: SystemSpacing.sm),
                    Text(widget.suffix!.toUpperCase(),
                        style: SystemTextStyles.label.copyWith(fontSize: 9.6)),
                  ],
                ],
              ),
            ),
          ),
          if (widget.hint != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                widget.hint!,
                style: SystemTextStyles.bodySmall.copyWith(
                  color: isError
                      ? SystemPalette.destructive
                      : SystemPalette.mutedForeground,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
