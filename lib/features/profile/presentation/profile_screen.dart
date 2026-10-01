import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/app_theme.dart';
import '../domain/avatar_catalog.dart';
import '../domain/player_class.dart';
import 'profile_providers.dart';

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

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
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

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextField(
                controller: _nomeController,
                decoration: const InputDecoration(labelText: 'Nome'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _tituloController,
                decoration: const InputDecoration(labelText: 'Título'),
              ),
              const SizedBox(height: 24),
              Text('Avatar', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  for (final chave in kAvatarCatalog)
                    ChoiceChip(
                      label: Icon(_iconeDoAvatar(chave)),
                      selected: _avatar == chave,
                      onSelected: (_) => setState(() => _avatar = chave),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              Text('Classe', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  for (final classe in PlayerClass.values)
                    ChoiceChip(
                      label: Text(nomeDaClasse(classe)),
                      selected: _classe == classe,
                      onSelected: (_) => setState(() => _classe = classe),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Tema escuro'),
                value: _tema == AppTheme.escuro,
                onChanged: (ligado) => setState(
                  () => _tema = ligado ? AppTheme.escuro : AppTheme.claro,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _salvar,
                child: const Text('Salvar'),
              ),
            ],
          );
        },
        error: (error, stackTrace) => Center(child: Text('Erro: $error')),
        loading: () => const Center(child: CircularProgressIndicator()),
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
