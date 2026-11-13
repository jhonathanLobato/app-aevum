import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../design_system/rank_badge.dart';
import '../../../design_system/system_back_button.dart';
import '../../../design_system/system_button.dart';
import '../../../design_system/system_colors.dart';
import '../../../design_system/system_empty_state.dart';
import '../../../design_system/system_panel.dart';
import '../../../design_system/system_scaffold.dart';
import '../../../design_system/system_spacing.dart';
import '../../../design_system/system_text_field.dart';
import '../../../design_system/system_text_styles.dart';
import '../../achievements/domain/achievement.dart';
import '../../achievements/presentation/achievement_providers.dart';
import '../../body/domain/body.dart';
import '../../body/presentation/body_summary.dart';
import '../domain/app_theme.dart';
import '../domain/avatar_catalog.dart';
import '../domain/level_curve.dart';
import '../domain/player_class.dart';
import '../domain/titles.dart';
import '../domain/units.dart';
import 'avatar_icons.dart';
import 'option_tile.dart';
import 'profile_providers.dart';

/// Ficha do Caçador: identidade, corpo e preferências. Nada é gravado até
/// tocar em "Salvar" no fim da tela (sair sem salvar descarta as mudanças).
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

String _numero(double v) {
  final t = v.toStringAsFixed(1);
  return t.endsWith('.0') ? t.substring(0, t.length - 2) : t;
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _nomeController = TextEditingController();
  final _alturaController = TextEditingController();
  String? _avatar;
  PlayerClass _classe = PlayerClass.guerreiro;
  String _titulo = tituloPadrao;
  AppTheme _tema = AppTheme.escuro;
  Units _units = const Units();
  DateTime? _nascimento;
  Sexo? _sexo;
  bool _inicializado = false;

  @override
  void dispose() {
    _nomeController.dispose();
    _alturaController.dispose();
    super.dispose();
  }

  double? get _alturaDigitada {
    final t = _alturaController.text.trim().replaceAll(',', '.');
    if (t.isEmpty) return null;
    return double.tryParse(t) ?? double.nan;
  }

  void _mudarComprimento(LengthUnit nova) {
    if (nova == _units.comprimento) return;
    final atual = _alturaDigitada;
    final novas = Units(peso: _units.peso, comprimento: nova);
    setState(() {
      if (atual != null && !atual.isNaN) {
        final cm = _units.comprimentoParaBanco(atual);
        _alturaController.text = _numero(novas.comprimentoParaExibir(cm));
      }
      _units = novas;
    });
  }

  Future<void> _escolherNascimento() async {
    final agora = DateTime.now();
    final data = await showDatePicker(
      context: context,
      initialDate: _nascimento ?? DateTime(agora.year - 25),
      firstDate: DateTime(1900),
      lastDate: agora,
    );
    if (data != null) setState(() => _nascimento = data);
  }

  Future<void> _escolherTitulo(Set<String> conquistas, String rank) async {
    final escolhido = await showDialog<String>(
      context: context,
      builder: (_) =>
          _TituloDialog(atual: _titulo, conquistas: conquistas, rank: rank),
    );
    if (escolhido != null) setState(() => _titulo = escolhido);
  }

  Future<void> _salvar() async {
    final altura = _alturaDigitada;
    if (altura != null && (altura.isNaN || altura <= 0)) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Altura inválida.')));
      return;
    }
    final nome = _nomeController.text.trim();
    await ref.read(profileRepositoryProvider).salvarFicha(
          nome: nome.isEmpty ? 'Jogador' : nome,
          avatar: _avatar,
          classe: _classe,
          titulo: _titulo,
          tema: _tema,
          unidades: _units,
          alturaCm: altura == null ? null : _units.comprimentoParaBanco(altura),
          nascimento: _nascimento,
          sexo: _sexo,
        );
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Ficha salva.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);
    final conquistas = <String>{
      for (final a in ref.watch(achievementsProvider).valueOrNull ?? const [])
        if (a.status == AchievementStatus.desbloqueada) a.chave,
    };
    final despertar = ref.watch(despertarProvider).valueOrNull;

    return SystemScaffold(
      title: 'FICHA DO CAÇADOR',
      subtitle: 'PERFIL DO JOGADOR',
      leading: const SystemBackButton(),
      body: userAsync.when(
        data: (user) {
          if (!_inicializado) {
            _nomeController.text = user?.nome ?? '';
            _avatar = user?.avatar;
            _classe = user?.classe ?? PlayerClass.guerreiro;
            _titulo = user?.titulo ?? tituloPadrao;
            _tema = user?.tema ?? AppTheme.escuro;
            _units = user?.unidades ?? const Units();
            final altura = user?.alturaCm;
            _alturaController.text = altura == null
                ? ''
                : _numero(_units.comprimentoParaExibir(altura));
            _nascimento = user?.nascimento;
            _sexo = user?.sexo;
            _inicializado = true;
          }
          final rank = user?.rank ?? 'F';
          final hoje = DateTime.now();
          final dias = despertar == null
              ? 0
              : DateTime(hoje.year, hoje.month, hoje.day)
                  .difference(
                      DateTime(despertar.year, despertar.month, despertar.day))
                  .inDays;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Cabecalho(
                nome: _nomeController,
                avatar: _avatar,
                classe: _classe,
                titulo: _titulo,
                rank: rank,
                nivel: const LevelCurve().calcularNivel(user?.xp ?? 0).nivel,
                despertar: despertar,
                dias: dias,
              ),
              const SizedBox(height: SystemSpacing.lg),
              SystemPanel(
                title: 'IDENTIDADE',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SystemTextField(
                      key: const Key('profile_nome_field'),
                      label: 'Nome',
                      controller: _nomeController,
                      textInputAction: TextInputAction.done,
                    ),
                    const SizedBox(height: SystemSpacing.md),
                    _Recolhivel(
                      id: 'avatar',
                      titulo: 'AVATAR',
                      resumo: Icon(iconeDoAvatar(_avatar),
                          size: 20, color: SystemPalette.primary),
                      child: Wrap(
                        spacing: SystemSpacing.sm,
                        runSpacing: SystemSpacing.sm,
                        children: [
                          for (final chave in kAvatarCatalog)
                            OptionTile(
                              selected: _avatar == chave,
                              semanticLabel: 'Avatar $chave',
                              onTap: () => setState(() => _avatar = chave),
                              child: Icon(
                                iconeDoAvatar(chave),
                                size: 22,
                                color: _avatar == chave
                                    ? SystemPalette.primary
                                    : SystemPalette.mutedForeground,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: SystemSpacing.sm),
                    _Recolhivel(
                      id: 'classe',
                      titulo: 'CLASSE',
                      resumo: Text(nomeDaClasse(_classe).toUpperCase(),
                          style: SystemTextStyles.label
                              .copyWith(color: SystemPalette.violet)),
                      child: Wrap(
                        spacing: SystemSpacing.sm,
                        runSpacing: SystemSpacing.sm,
                        children: [
                          for (final classe in PlayerClass.values)
                            OptionTile(
                              selected: _classe == classe,
                              semanticLabel: 'Classe ${nomeDaClasse(classe)}',
                              onTap: () => setState(() => _classe = classe),
                              child: OptionLabel(nomeDaClasse(classe),
                                  selected: _classe == classe),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: SystemSpacing.md),
                    const _Rotulo('TÍTULO'),
                    OptionTile(
                      key: const Key('profile_titulo_button'),
                      selected: true,
                      semanticLabel: 'Título $_titulo',
                      onTap: () => _escolherTitulo(conquistas, rank),
                      child: Row(
                        children: [
                          Expanded(
                              child: Text(_titulo.toUpperCase(),
                                  style: SystemTextStyles.label
                                      .copyWith(color: SystemPalette.gold))),
                          const Icon(Icons.expand_more,
                              size: 18, color: SystemPalette.mutedForeground),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: SystemSpacing.lg),
              SystemPanel(
                title: 'CORPO',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Resumo: cartão tocável que abre a tela Corpo.
                    InkWell(
                      key: const Key('body_summary'),
                      onTap: () => context.push('/body'),
                      child: Container(
                        padding: const EdgeInsets.all(SystemSpacing.md),
                        decoration: BoxDecoration(
                          color: SystemPalette.surface2
                              .withValues(alpha: SystemOpacities.surface2),
                          border: Border.all(
                              color:
                                  SystemPalette.primary.withValues(alpha: 0.4)),
                        ),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                    child: Text('EVOLUÇÃO CORPORAL',
                                        style: SystemTextStyles.label)),
                                Text('VER TUDO',
                                    style: SystemTextStyles.labelTiny),
                                Icon(Icons.chevron_right,
                                    size: 18, color: SystemPalette.primary),
                              ],
                            ),
                            SizedBox(height: SystemSpacing.sm),
                            BodySummary(),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: SystemSpacing.md),
                    SystemButton(
                      key: const Key('body_novo_registro'),
                      label: 'Novo registro',
                      variant: SystemButtonVariant.action,
                      icon: const Icon(Icons.add,
                          size: 16, color: SystemPalette.foreground),
                      onPressed: () => context.push('/body/new'),
                    ),
                    const SizedBox(height: SystemSpacing.lg),
                    const _Rotulo('CADASTRO'),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: SystemTextField(
                            key: const Key('profile_altura_field'),
                            label: 'Altura',
                            controller: _alturaController,
                            suffix: _units.comprimentoSufixo,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            textInputAction: TextInputAction.done,
                          ),
                        ),
                        const SizedBox(width: SystemSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const _Rotulo('NASCIMENTO'),
                              OptionTile(
                                key: const Key('profile_nascimento_button'),
                                selected: _nascimento != null,
                                semanticLabel: 'Data de nascimento',
                                onTap: _escolherNascimento,
                                child: OptionLabel(
                                    _nascimento == null
                                        ? 'Informar'
                                        : formatarDataBr(_nascimento!),
                                    selected: _nascimento != null),
                              ),
                              if (_nascimento != null)
                                Row(
                                  children: [
                                    Text('${idadeEm(_nascimento!, hoje)} anos',
                                        key: const Key('profile_idade'),
                                        style: SystemTextStyles.body),
                                    IconButton(
                                      tooltip: 'Limpar data de nascimento',
                                      icon: const Icon(Icons.close, size: 18),
                                      onPressed: () =>
                                          setState(() => _nascimento = null),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: SystemSpacing.md),
                    const _Rotulo('SEXO'),
                    Wrap(
                      spacing: SystemSpacing.sm,
                      children: [
                        for (final (sexo, nome) in const [
                          (Sexo.masculino, 'Masculino'),
                          (Sexo.feminino, 'Feminino'),
                        ])
                          OptionTile(
                            selected: _sexo == sexo,
                            semanticLabel: 'Sexo $nome',
                            // Tocar de novo limpa a escolha (opcional).
                            onTap: () => setState(
                                () => _sexo = _sexo == sexo ? null : sexo),
                            child: OptionLabel(nome, selected: _sexo == sexo),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: SystemSpacing.lg),
              SystemPanel(
                title: 'PREFERÊNCIAS',
                child: _Recolhivel(
                  id: 'preferencias',
                  titulo: 'TEMA E UNIDADES',
                  resumo: Text(
                    '${_tema == AppTheme.escuro ? 'Escuro' : 'Claro'} · ${_units.peso.name} · ${_units.comprimento.name}',
                    style: SystemTextStyles.body
                        .copyWith(color: SystemPalette.mutedForeground),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _Rotulo('TEMA'),
                      Wrap(
                        spacing: SystemSpacing.sm,
                        children: [
                          for (final (tema, nome) in const [
                            (AppTheme.escuro, 'Escuro'),
                            (AppTheme.claro, 'Claro'),
                          ])
                            OptionTile(
                              key: Key('profile_tema_${tema.name}'),
                              selected: _tema == tema,
                              semanticLabel: 'Tema $nome',
                              onTap: () => setState(() => _tema = tema),
                              child: OptionLabel(nome, selected: _tema == tema),
                            ),
                        ],
                      ),
                      const SizedBox(height: SystemSpacing.md),
                      const _Rotulo('PESO'),
                      Wrap(
                        spacing: SystemSpacing.sm,
                        children: [
                          for (final u in WeightUnit.values)
                            OptionTile(
                              key: Key('profile_peso_${u.name}'),
                              selected: _units.peso == u,
                              semanticLabel: 'Peso em ${u.name}',
                              onTap: () => setState(() => _units = Units(
                                  peso: u, comprimento: _units.comprimento)),
                              child: OptionLabel(u.name,
                                  selected: _units.peso == u),
                            ),
                        ],
                      ),
                      const SizedBox(height: SystemSpacing.md),
                      const _Rotulo('COMPRIMENTO'),
                      Wrap(
                        spacing: SystemSpacing.sm,
                        children: [
                          for (final u in LengthUnit.values)
                            OptionTile(
                              key: Key('profile_comprimento_${u.name}'),
                              selected: _units.comprimento == u,
                              semanticLabel: 'Comprimento em ${u.name}',
                              onTap: () => _mudarComprimento(u),
                              child: OptionLabel(u.name,
                                  selected: _units.comprimento == u),
                            ),
                        ],
                      ),
                      const SizedBox(height: SystemSpacing.sm),
                      Text('Distância continua em km.',
                          style: SystemTextStyles.body
                              .copyWith(color: SystemPalette.mutedForeground)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: SystemSpacing.lg),
              SystemButton(
                key: const Key('profile_salvar'),
                label: 'Salvar',
                variant: SystemButtonVariant.action,
                size: SystemButtonSize.lg,
                onPressed: _salvar,
              ),
              const SizedBox(height: SystemSpacing.xs),
              Text(
                'As mudanças só valem depois de salvar.',
                textAlign: TextAlign.center,
                style: SystemTextStyles.body
                    .copyWith(color: SystemPalette.mutedForeground),
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
}

/// Resumo de leitura no topo da ficha: quem você é agora (reflete o que está
/// sendo editado, mesmo antes de salvar).
class _Cabecalho extends StatelessWidget {
  const _Cabecalho({
    required this.nome,
    required this.avatar,
    required this.classe,
    required this.titulo,
    required this.rank,
    required this.nivel,
    required this.despertar,
    required this.dias,
  });

  final TextEditingController nome;
  final String? avatar;
  final PlayerClass classe;
  final String titulo;
  final String rank;
  final int nivel;
  final DateTime? despertar;
  final int dias;

  @override
  Widget build(BuildContext context) {
    return SystemPanel(
      glow: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 64,
                height: 64,
                margin: const EdgeInsets.only(right: SystemSpacing.md),
                decoration: BoxDecoration(
                  color: SystemPalette.primary.withValues(alpha: 0.08),
                  border: Border.all(color: SystemPalette.primary),
                ),
                child: Icon(iconeDoAvatar(avatar),
                    color: SystemPalette.primary, size: 34),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ValueListenableBuilder<TextEditingValue>(
                      valueListenable: nome,
                      builder: (_, v, __) => Text(
                        (v.text.trim().isEmpty ? 'Jogador' : v.text.trim())
                            .toUpperCase(),
                        key: const Key('profile_cabecalho_nome'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: SystemTextStyles.displaySmall,
                      ),
                    ),
                    const SizedBox(height: SystemSpacing.xs),
                    Text('⚔ ${nomeDaClasse(classe).toUpperCase()}',
                        style: SystemTextStyles.label
                            .copyWith(color: SystemPalette.violet)),
                    const SizedBox(height: SystemSpacing.xs),
                    Text(titulo.toUpperCase(),
                        key: const Key('profile_cabecalho_titulo'),
                        style: SystemTextStyles.label
                            .copyWith(color: SystemPalette.gold)),
                  ],
                ),
              ),
              Column(
                children: [
                  RankBadge(rank: rank, size: 44),
                  const SizedBox(height: SystemSpacing.xs),
                  Text('LV. $nivel', style: SystemTextStyles.label),
                ],
              ),
            ],
          ),
          const SizedBox(height: SystemSpacing.md),
          Text(
            despertar == null
                ? 'Despertar: —'
                : 'Despertou em ${formatarDataBr(despertar!)} · $dias ${dias == 1 ? 'dia' : 'dias'} de jornada',
            key: const Key('profile_despertar'),
            style: SystemTextStyles.body
                .copyWith(color: SystemPalette.mutedForeground),
          ),
        ],
      ),
    );
  }
}

/// Grupo de opções recolhido por padrão: mostra o rótulo e um resumo do valor
/// atual; tocar abre as opções.
class _Recolhivel extends StatefulWidget {
  const _Recolhivel({
    required this.id,
    required this.titulo,
    required this.resumo,
    required this.child,
  });

  final String id;
  final String titulo;
  final Widget resumo;
  final Widget child;

  @override
  State<_Recolhivel> createState() => _RecolhivelState();
}

class _RecolhivelState extends State<_Recolhivel> {
  bool _aberto = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          key: Key('profile_toggle_${widget.id}'),
          onTap: () => setState(() => _aberto = !_aberto),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: Row(
              children: [
                Text(widget.titulo,
                    style: SystemTextStyles.label
                        .copyWith(color: SystemPalette.mutedForeground)),
                const SizedBox(width: SystemSpacing.md),
                Expanded(
                  child: Align(
                      alignment: Alignment.centerRight, child: widget.resumo),
                ),
                const SizedBox(width: SystemSpacing.sm),
                Icon(_aberto ? Icons.expand_less : Icons.expand_more,
                    size: 20, color: SystemPalette.mutedForeground),
              ],
            ),
          ),
        ),
        if (_aberto) ...[
          const SizedBox(height: SystemSpacing.sm),
          widget.child,
        ],
      ],
    );
  }
}

class _Rotulo extends StatelessWidget {
  const _Rotulo(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: SystemSpacing.xs),
      child: Text(texto,
          style: SystemTextStyles.label
              .copyWith(color: SystemPalette.mutedForeground)),
    );
  }
}

/// Lista de títulos: desbloqueados selecionáveis; bloqueados com cadeado e a
/// condição para liberar.
class _TituloDialog extends StatelessWidget {
  const _TituloDialog(
      {required this.atual, required this.conquistas, required this.rank});

  final String atual;
  final Set<String> conquistas;
  final String rank;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: SystemPalette.popover,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 520),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.all(SystemSpacing.md),
              child: Text('ESCOLHER TÍTULO', style: SystemTextStyles.label),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final t in kTitleCatalog)
                    _linha(context, t,
                        t.desbloqueado(conquistas: conquistas, rank: rank)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _linha(BuildContext context, TitleDef t, bool liberado) {
    return ListTile(
      key: Key('titulo_${t.nome}'),
      enabled: liberado,
      leading: Icon(
        liberado
            ? (t.nome == atual ? Icons.check_circle : Icons.circle_outlined)
            : Icons.lock_outline,
        color: liberado ? SystemPalette.gold : SystemPalette.mutedForeground,
      ),
      title: Text(t.nome,
          style: SystemTextStyles.body.copyWith(
              color: liberado
                  ? SystemPalette.foreground
                  : SystemPalette.mutedForeground)),
      subtitle: liberado
          ? null
          : Text(t.condicao,
              style: SystemTextStyles.body
                  .copyWith(color: SystemPalette.mutedForeground)),
      onTap: liberado ? () => Navigator.of(context).pop(t.nome) : null,
    );
  }
}
