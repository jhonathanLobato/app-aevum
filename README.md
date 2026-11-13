# Aevum (gym_system)

Aplicativo Android de acompanhamento de academia com progressão gamificada,
inspirada na sensação de um "Sistema" de RPG. Você monta seus treinos,
registra cada série (carga × repetições) e o app detecta recordes pessoais,
dá XP, sobe seu nível e rank, gera missões e desbloqueia conquistas. Tudo
funciona offline, com os dados guardados no próprio aparelho.

## O que o app tem

* **Sistema** — painel do jogador (nível, rank, XP), missão atual e treino em andamento.
* **Treinos** — biblioteca de treinos e de exercícios, treino ativo com registro de séries.
* **Atividades** — registro manual de corrida, ciclismo, caminhada, boxe, muay thai, basquete, futebol e skate.
* **Missões**, **Status** (estatísticas e atributos) e **Conquistas**.
* **Histórico** — linha do tempo por mês, com um cartão por treino e as atividades esportivas.
* **Perfil** — nome, título, avatar, classe e tema.

## Tecnologias

Flutter / Dart, SQLite com Drift, Riverpod e go_router. Sem backend,
autenticação ou serviços de nuvem (offline-first).

## Como rodar

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # gera o código do Drift
flutter run
```

## Qualidade

```bash
flutter analyze
flutter test
```

O documento de design do projeto está em [CLAUDE.md](CLAUDE.md).
