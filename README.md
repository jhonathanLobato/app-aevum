<div align="center">

# ⚔️ AEVUM

### Transforme seu progresso real na academia em uma progressão de RPG.

Um "Sistema" que acompanha seus treinos, reconhece cada recorde,<br>
entrega missões, concede XP e faz você subir de nível e de rank.

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![SQLite](https://img.shields.io/badge/SQLite-003B57?style=for-the-badge&logo=sqlite&logoColor=white)
![Android](https://img.shields.io/badge/Android-3DDC84?style=for-the-badge&logo=android&logoColor=white)
![Offline](https://img.shields.io/badge/100%25-offline-3DA9FC?style=for-the-badge)
![License](https://img.shields.io/badge/licença-Apache%202.0-blue?style=for-the-badge)

</div>

---

## ✨ A ideia

O Aevum **não quer transformar a academia em um jogo complexo**. O objetivo é que
você olhe para a própria evolução e sinta:

> **"Estou ficando mais forte."**

O progresso real vem primeiro: a gamificação só reforça o que importa
(consistência, evolução de carga, retorno após uma pausa). Descanso planejado
nunca é tratado como falha, e o app não incentiva treinar só para ganhar XP.

---

## 🎮 O que o app tem

| | |
|---|---|
| 🖥️ **Sistema** | Painel do jogador: título, nível, rank, barra de XP, missão diária, treino do dia e faixa da semana. |
| 🏋️ **Treinos** | Biblioteca de treinos (A–F de exemplo), exercícios, programação semanal e treino ativo com registro de série em poucos toques. |
| 📈 **Progressão e PRs** | Detecta recorde de **carga**, **repetições** e **volume** por exercício, sem inflar o XP com registros falsos. |
| 🏃 **Atividades** | Corrida/Caminhada, Ciclismo, Muay Thai/Boxe, Jiu Jitsu, Basquete, Futebol e Skate, com duração em horas e minutos. |
| 🎯 **Missões** | Missão diária (50 flexões, 50 abdominais, 2 km), semanal (treinos programados) e desafios de carga por exercício. |
| 🏆 **Conquistas** | 40 conquistas em 7 categorias, com XP, títulos desbloqueáveis e progresso visível. |
| 👑 **Rank e exame** | Ranks de **F a S**. O nível sobe com XP, mas o **rank só sobe passando no exame de reavaliação**. |
| 📊 **Status** | Estatísticas globais, relatório semanal e histórico mensal. |
| 🧍 **Ficha do Caçador** | Perfil com avatar, classe, título, data do despertar, medidas do corpo (com gráfico de evolução) e preferências. |

### Como o Sistema funciona

```text
   ABRIR O APP
        ↓
 VER MISSÃO / TREINO
        ↓
 REGISTRAR AS SÉRIES  ──►  PR detectado?  ──►  +XP
        ↓
 FINALIZAR O TREINO   ──►  missões · conquistas · estatísticas
        ↓
   SUBIR DE NÍVEL  ──►  liberar o exame  ──►  SUBIR DE RANK
```

### Rank

```text
F  →  E  →  D  →  C  →  B  →  A  →  S
```

Para liberar o exame do próximo rank é preciso **nível mínimo** e **experiência
de caçador** (treinos e atividades reais). O exame tem prazo e exige uma
porcentagem de treinos programados, de missões diárias cumpridas e atividades
extras. Folgas planejadas não contam contra você.

> As regras completas (curva de XP, penalidade, folgas, requisitos de cada
> exame) estão no [`CLAUDE.md`](CLAUDE.md).

---

## 🧱 Tecnologias

| Camada | Escolha |
|---|---|
| Framework | **Flutter** / **Dart** |
| Banco de dados | **SQLite** com **Drift** (local, offline-first) |
| Estado | **Riverpod** |
| Navegação | **go_router** |
| Gráficos | **fl_chart** |
| Testes | `flutter_test` (mais de 400 testes) |

Sem backend, sem autenticação e sem serviços de nuvem: **os dados ficam só no
seu celular**.

---

## 🗂️ Estrutura

```text
lib/
├── app/             # tema, rotas e casca de navegação
├── database/        # banco Drift e migrações
├── design_system/   # componentes visuais do Sistema (painéis, botões, diálogos)
└── features/
    ├── system_home/   ├── workouts/      ├── exercises/
    ├── progression/   ├── daily/         ├── missions/
    ├── achievements/  ├── rank_exam/     ├── activities/
    ├── statistics/    ├── profile/       └── body/
```

Cada feature separa **domínio** (regras), **dados** (Drift) e **apresentação**
(telas e widgets).

---

## 🚀 Como rodar

Pré-requisito: [Flutter](https://docs.flutter.dev/get-started/install) instalado.

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # gera o código do Drift
flutter run
```

### Qualidade

```bash
flutter analyze
flutter test
```

---

## 📦 Gerar o APK

O APK de **debug** tem ~180 MB. O de **release** é bem menor:

```powershell
.\tool\build_release.ps1              # um APK por arquitetura (o arm64 serve na maioria)
.\tool\build_release.ps1 -Universal   # 1 APK que serve em qualquer celular
.\tool\build_release.ps1 -Bundle      # App Bundle (.aab) para a Play Store
```

| Build | Tamanho |
|---|---|
| Debug | ~182 MB |
| Release universal | ~56 MB |
| **Release arm64 (celular)** | **~19,5 MB** |

Os arquivos saem em `build/app/outputs/flutter-apk/`. Para instalar por fora da
loja, permita "instalar de fontes desconhecidas" no Android.

---

## 🧭 Roadmap

Fora do escopo atual, planejado para versões futuras: loja e moedas,
inventário e equipamentos, desafios especiais e bosses, missões bônus semanais
e mensais, integração com smartwatch e apps de saúde, IA para análise de
treino e recursos sociais.

---

## 📄 Documentação e licença

* [`CLAUDE.md`](CLAUDE.md): documento de design e regras do sistema.
* Licença [Apache 2.0](LICENSE).
