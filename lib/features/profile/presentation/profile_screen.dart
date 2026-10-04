import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/system_back_button.dart';
import '../../../design_system/system_button.dart';
import '../../../design_system/system_colors.dart';
import '../../../design_system/system_effects.dart';
import '../../../design_system/system_empty_state.dart';
import '../../../design_system/system_panel.dart';
import '../../../design_system/system_scaffold.dart';
import '../../../design_system/system_spacing.dart';
import '../../../design_system/system_text_field.dart';
import '../../../design_system/system_text_styles.dart';
import '../domain/app_theme.dart';
import '../domain/avatar_catalog.dart';
import '../domain/player_class.dart';
import 'profile_providers.dart';

/// Perfil do jogador (nome, título, avatar, classe, tema), redesenhado na
/// Fase 11 — mesmos campos e mesma persistência de antes, só com a
/// linguagem visual do Aevum em vez de `TextField`/`ChoiceChip` Material.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _nomeController = TextEditingController();
  final _tituloController = TextEditingController();
  String? _avatar;
  PlayerClass _classe = PlayerClass.guerreiro;
  AppTheme _tema = AppTheme.escuro;
  bool _inicializado = false;

  @override
  void dispose() {
    _nomeController.dispose();
    _tituloController.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    await ref.read(profileRepositoryProvider).updateProfile(
          nome: _nomeController.text.trim().isEmpty
              ? 'Jogador'
              : _nomeController.text.trim(),
          avatar: _avatar,
          classe: _classe,
          titulo: _tituloController.text.trim().isEmpty
              ? null
              : _tituloController.text.trim(),
          tema: _tema,
        );
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Perfil salvo.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);

    return SystemScaffold(
      title: 'PERFIL',
      subtitle: 'IDENTIDADE DO JOGADOR',
      leading: const SystemBackButton(),
      body: userAsync.when(
        data: (user) {
          if (!_inicializado) {
            _nomeController.text = user?.nome ?? '';
            _tituloController.text = user?.titulo ?? '';
            _avatar = user?.avatar;
            _classe = user?.classe ?? PlayerClass.guerreiro;
            _tema = user?.tema ?? AppTheme.escuro;
            _inicializado = true;
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SystemPanel(
                title: 'IDENTIDADE',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SystemTextField(
                      key: const Key('profile_nome_field'),
                      label: 'Nome',
                      controller: _nomeController,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: SystemSpacing.md),
                    SystemTextField(
                      key: const Key('profile_titulo_field'),
                      label: 'Título',
                      controller: _tituloController,
                      textInputAction: TextInputAction.done,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: SystemSpacing.lg),
              SystemPanel(
                title: 'AVATAR',
                child: Wrap(
                  spacing: SystemSpacing.sm,
                  runSpacing: SystemSpacing.sm,
                  children: [
                    for (final chave in kAvatarCatalog)
                      _OptionTile(
                        selected: _avatar == chave,
                        semanticLabel: 'Avatar $chave',
                        onTap: () => setState(() => _avatar = chave),
                        child: Icon(
                          _iconeDoAvatar(chave),
                          size: 22,
                          color: _avatar == chave
                              ? SystemPalette.primary
                              : SystemPalette.mutedForeground,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: SystemSpacing.lg),
              SystemPanel(
                title: 'CLASSE',
                child: Wrap(
                  spacing: SystemSpacing.sm,
                  runSpacing: SystemSpacing.sm,
                  children: [
                    for (final classe in PlayerClass.values)
                      _OptionTile(
                        selected: _classe == classe,
                        semanticLabel: 'Classe ${nomeDaClasse(classe)}',
                        onTap: () => setState(() => _classe = classe),
                        child: Text(
                          nomeDaClasse(classe).toUpperCase(),
                          style: SystemTextStyles.label.copyWith(
                            fontSize: 10,
                            color: _classe == classe
                                ? SystemPalette.primary
                                : SystemPalette.mutedForeground,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: SystemSpacing.lg),
              SystemPanel(
                title: 'TEMA',
                child: Row(
                  children: [
                    const Expanded(
                      child: Text('TEMA ESCURO', style: SystemTextStyles.label),
                    ),
                    Switch(
                      value: _tema == AppTheme.escuro,
                      activeThumbColor: SystemPalette.primary,
                      onChanged: (ligado) => setState(
                        () => _tema = ligado ? AppTheme.escuro : AppTheme.claro,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: SystemSpacing.lg),
              SystemButton(
                label: 'Salvar',
                variant: SystemButtonVariant.action,
                size: SystemButtonSize.lg,
                onPressed: _salvar,
              ),
            ],
          );
        },
        error: (error, stackTrace) => const SystemEmptyState(
          icon: Icons.error_outline,
          message: 'ERRO AO CARREGAR PERFIL',
        ),
        loading: () => const Center(
          child: CircularProgressIndicator(color: SystemPalette.primary),
        ),
      ),
    );
  }

  IconData _iconeDoAvatar(String chave) {
    switch (chave) {
      case 'sword':
        return Icons.gavel;
      case 'shield':
        return Icons.shield;
      case 'bolt':
        return Icons.bolt;
      case 'star':
        return Icons.star;
      case 'flame':
        return Icons.local_fire_department;
      case 'person':
      default:
        return Icons.person;
    }
  }
}

/// Opção selecionável (avatar/classe): borda e glow ciano quando ativa.
class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.selected,
    required this.onTap,
    required this.child,
    required this.semanticLabel,
  });

  final bool selected;
  final VoidCallback onTap;
  final Widget child;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          padding: const EdgeInsets.symmetric(
              horizontal: SystemSpacing.md, vertical: SystemSpacing.sm),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected
                ? SystemPalette.primary.withValues(alpha: 0.15)
                : SystemPalette.surface2
                    .withValues(alpha: SystemOpacities.surface2),
            border: Border.all(
              color: selected
                  ? SystemPalette.primary.withValues(alpha: 0.7)
                  : SystemPalette.primary
                      .withValues(alpha: SystemOpacities.border),
            ),
            boxShadow: selected ? SystemShadows.glowPrimary : null,
          ),
          child: child,
        ),
      ),
    );
  }
}
