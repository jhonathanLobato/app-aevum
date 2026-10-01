# SISTEMA DE PROGRESSÃO PARA ACADEMIA

## Documento de Design — MVP

**Versão:** 0.1
**Status:** Especificação inicial
**Objetivo:** Servir como documento-base para desenvolvimento do aplicativo.

---

# 1. VISÃO DO APLICATIVO

O aplicativo será um sistema de acompanhamento de academia com elementos de gamificação inspirados na sensação de progressão de sistemas de RPG, especialmente na ideia de um "Sistema" que acompanha o jogador, apresenta missões, registra progresso e recompensa evolução.

A inspiração estética e conceitual pode remeter a sistemas de progressão de jogos/animes, mas o aplicativo deve possuir identidade visual, nomes, elementos gráficos e implementação próprios.

O objetivo principal não é transformar a academia em um jogo complexo.

O objetivo é:

> **Transformar o progresso físico e a consistência do usuário em uma experiência de progressão semelhante a um RPG.**

O aplicativo deve fazer o usuário sentir que está evoluindo tanto fisicamente quanto dentro do sistema.

---

# 2. PRINCÍPIOS DO PROJETO

O desenvolvimento deve seguir estes princípios:

## 2.1 Progresso real acima da gamificação

O aplicativo não deve incentivar o usuário a treinar apenas para ganhar XP.

O progresso real dos exercícios deve ser uma parte central do sistema.

Exemplo:

```text
Supino

Semana 1
30 kg × 10

Semana 4
32 kg × 10
```

O aplicativo deve reconhecer essa evolução.

---

## 2.2 Consistência

O aplicativo deve incentivar frequência e consistência, mas não deve punir descanso planejado.

Um dia programado como descanso não deve quebrar uma sequência de progresso.

---

## 2.3 Simplicidade

O MVP deve ser simples o suficiente para ser utilizado durante o treino sem atrapalhar o treinamento.

Registrar uma série deve exigir o mínimo possível de interações.

---

## 2.4 Evolução gradual

O MVP deve possuir uma arquitetura que permita adicionar posteriormente:

* loja;
* moedas;
* inventário;
* equipamentos;
* desafios;
* bosses;
* integração com smartwatch;
* integração com aplicativos de saúde;
* recursos sociais;
* IA;
* notificações avançadas.

Esses recursos NÃO fazem parte do MVP inicial.

---

# 3. ESCOPO DO MVP

O MVP será composto pelos seguintes sistemas:

1. Sistema de treinos
2. Registro de exercícios
3. Progressão dos exercícios
4. Sistema de XP
5. Sistema de níveis
6. Sistema de missões
7. Sistema de conquistas
8. Sistema de estatísticas
9. Sistema de Rank
10. Perfil e personalização
11. Tela principal "Sistema"

---

# 4. SISTEMA DE TREINOS

O usuário poderá criar e administrar seus treinos.

Exemplo:

```text
TREINO A
Peito + Tríceps

Supino reto
Supino inclinado
Crucifixo
Tríceps pulley
```

Cada treino poderá conter vários exercícios.

O usuário deve conseguir:

* criar treino;
* editar treino;
* excluir treino;
* alterar ordem dos exercícios;
* adicionar exercícios;
* remover exercícios;
* iniciar treino;
* finalizar treino;
* consultar histórico.

---

# 5. SISTEMA DE EXERCÍCIOS

Cada exercício deve possuir informações suficientes para acompanhar sua evolução.

Dados mínimos:

```text
Nome
Grupo muscular
Séries
Repetições
Carga
Data
Observações
```

Durante o treino, o usuário deve conseguir registrar cada série.

Exemplo:

```text
SUPINO RETO

Série 1
30 kg × 10

Série 2
30 kg × 10

Série 3
32 kg × 8
```

O sistema deve guardar o histórico.

---

# 6. SISTEMA DE PROGRESSÃO

Este é um dos sistemas mais importantes do aplicativo.

O aplicativo deve detectar evolução nos exercícios.

Tipos de progresso:

## 6.1 Carga

Exemplo:

```text
30 kg → 32 kg
```

## 6.2 Repetições

```text
10 → 12
```

## 6.3 Séries

```text
3 → 4
```

## 6.4 Volume

O sistema deve poder calcular:

```text
Volume = carga × repetições × séries
```

Exemplo:

```text
30 kg × 10 × 3 = 900 kg
```

---

# 7. PR — RECORDE PESSOAL

O sistema deve identificar automaticamente novos recordes pessoais.

Exemplo:

```text
PR DETECTADO

Supino reto

Novo recorde:
32 kg × 10

Recorde anterior:
30 kg × 10
```

O sistema poderá registrar diferentes tipos de PR.

Exemplos:

* maior carga;
* maior número de repetições;
* maior volume;
* melhor desempenho registrado.

O conceito de PR deve permanecer separado do XP.

> XP é uma recompensa de gamificação.
> PR representa progresso registrado no exercício.

---

# 8. SISTEMA DE XP

XP será utilizado para representar progressão dentro do sistema.

O XP deve ser obtido principalmente por ações reais realizadas dentro do treino.

Valores iniciais sugeridos:

| Ação                      |   XP |
| ------------------------- | ---: |
| Completar exercício       |  +10 |
| Completar todas as séries |  +20 |
| Finalizar treino          | +100 |
| Novo PR                   |  +50 |
| Missão diária             |  +50 |
| Missão semanal            | +250 |

Esses valores são iniciais e devem ser facilmente configuráveis.

O sistema deve evitar exploração do XP.

O usuário não deve conseguir ganhar XP indefinidamente realizando ações artificiais ou repetindo registros inválidos.

---

# 9. SISTEMA DE NÍVEIS

O usuário possui um nível geral.

Exemplo:

```text
Nível 1
Nível 2
Nível 3
...
```

O nível deve ser calculado com base no XP acumulado.

A fórmula de XP necessária para cada nível deve ser implementada de maneira configurável.

Uma possibilidade inicial:

```text
XP necessário = 1000 × nível^1.2
```

Porém, essa fórmula NÃO deve ser considerada definitiva.

O sistema deve permitir alterar a curva de progressão posteriormente sem precisar reescrever toda a aplicação.

Ao subir de nível:

```text
╔══════════════════════╗
║                      ║
║      LEVEL UP!       ║
║                      ║
║       LV. 12         ║
║         ↓            ║
║       LV. 13         ║
║                      ║
║      + XP            ║
║                      ║
╚══════════════════════╝
```

---

# 10. SISTEMA DE RANK

O usuário possuirá um Rank baseado no nível.

Ranks iniciais:

```text
F
E
D
C
B
A
S
```

Sugestão inicial:

```text
F → níveis 1–9
E → níveis 10–19
D → níveis 20–29
C → níveis 30–39
B → níveis 40–49
A → níveis 50–59
S → nível 60+
```

Essa distribuição deve ser configurável.

O Rank é principalmente um elemento de progressão e identidade dentro do aplicativo.

---

# 11. SISTEMA DE MISSÕES

O aplicativo possuirá missões.

Serão utilizados inicialmente três tipos.

## 11.1 Missões diárias

Exemplo:

```text
MISSÃO DIÁRIA

Complete seu treino.

[██████████] 100%

Recompensa:
+50 XP
```

---

## 11.2 Missões semanais

Exemplo:

```text
MISSÃO SEMANAL

Complete 4 treinos.

Progresso:
3 / 4

Recompensa:
+250 XP
```

---

## 11.3 Desafios

Desafios podem estar relacionados ao progresso real.

Exemplo:

```text
DESAFIO

Supino reto

Aumente seu recorde de carga.

Atual:
30 kg

Objetivo:
32 kg

Recompensa:
+150 XP
```

Os desafios devem conectar a gamificação com o progresso real do usuário.

---

# 12. DESCANSO E SEQUÊNCIAS

O sistema não deve considerar descanso planejado como falha.

O usuário poderá possuir uma programação de treino.

Exemplo:

```text
Segunda  → Treino
Terça    → Treino
Quarta   → Descanso
Quinta   → Treino
Sexta    → Treino
```

Quarta-feira não deve quebrar uma sequência.

O sistema deve diferenciar:

```text
DESCANSO PROGRAMADO
```

de:

```text
TREINO NÃO REALIZADO
```

Posteriormente poderá existir um sistema de sequência/streak.

---

# 13. SISTEMA DE CONQUISTAS

Conquistas representam marcos importantes.

Exemplos:

### Primeiros Passos

Complete seu primeiro treino.

### Evolução

Bata seu primeiro PR.

### Disciplina

Complete 10 treinos.

### Constância

Complete 25 treinos.

### Veterano

Complete 100 treinos.

### Superação

Bata um PR após ficar 7 ou mais dias sem treinar.

As conquistas devem ser desbloqueadas automaticamente quando seus requisitos forem atingidos.

Cada conquista deve possuir:

```text
ID
Nome
Descrição
Ícone
Requisito
Status
Data de desbloqueio
```

---

# 14. SISTEMA DE ESTATÍSTICAS

O aplicativo deve possuir uma área dedicada à análise do progresso.

Estatísticas iniciais:

```text
Treinos realizados
Tempo total treinando
Exercícios realizados
PRs
Volume total
XP acumulado
Nível atual
Maior sequência
```

Também devem existir estatísticas por exercício.

Exemplo:

```text
SUPINO RETO

Maior carga:
32 kg

Maior repetição:
12

Maior volume:
960 kg

Treinos realizados:
18

Primeiro registro:
01/10/2026

Último registro:
27/10/2026
```

Posteriormente poderão existir gráficos.

Exemplos:

* evolução da carga;
* evolução do volume;
* frequência de treino;
* PRs ao longo do tempo.

---

# 15. ATRIBUTOS / STATUS

O sistema poderá apresentar atributos de maneira gamificada.

A princípio, os atributos não devem fornecer bônus artificiais que alterem o treino.

Sugestão:

```text
FORÇA
RESISTÊNCIA
CONSISTÊNCIA
```

Esses valores poderão futuramente ser calculados a partir dos dados reais.

Exemplo:

```text
STATUS

FORÇA
████████░░ 82

RESISTÊNCIA
███████░░░ 71

CONSISTÊNCIA
█████████░ 93
```

No MVP, esse sistema deve permanecer simples.

Não criar uma árvore complexa de atributos ou habilidades.

---

# 16. PERSONALIZAÇÃO

O usuário poderá personalizar seu perfil.

Informações iniciais:

```text
Nome
Avatar
Classe
Título
Tema
```

Classes iniciais:

```text
Guerreiro
Guardião
Atleta
Assassino
```

As classes serão inicialmente cosméticas.

Não devem fornecer bônus diferentes de XP ou desempenho.

O objetivo é criar identidade visual sem criar problemas de balanceamento.

---

# 17. TELA PRINCIPAL — SISTEMA

A tela principal deve funcionar como um painel de controle.

Ela deve mostrar principalmente:

```text
Nome
Classe
Nível
Rank
Barra de XP
Missão atual
Treino atual
Progresso recente
PRs recentes
```

Exemplo conceitual:

```text
╔══════════════════════════════╗
║                              ║
║       SISTEMA ONLINE         ║
║                              ║
║       JOGADOR                ║
║       ⚔️ GUERREIRO           ║
║                              ║
║       LV. 12                 ║
║       RANK E                 ║
║                              ║
║ ███████████████░░░  82%      ║
║                              ║
║       🔥 12 DIAS             ║
║                              ║
╠══════════════════════════════╣
║                              ║
║       MISSÃO ATUAL           ║
║                              ║
║       TREINO A               ║
║                              ║
║       [ INICIAR TREINO ]     ║
║                              ║
╠══════════════════════════════╣
║                              ║
║  🏆 3 PRs recentes           ║
║  📈 +12% volume              ║
║  🎯 2 missões                ║
║                              ║
╚══════════════════════════════╝
```

A tela deve responder à pergunta:

> "O que eu preciso fazer agora?"

---

# 18. LOOP PRINCIPAL DO APLICATIVO

O fluxo principal esperado é:

```text
ABRIR APLICATIVO
       ↓
VER MISSÃO / TREINO
       ↓
INICIAR TREINO
       ↓
REGISTRAR EXERCÍCIOS
       ↓
FINALIZAR TREINO
       ↓
CALCULAR PROGRESSO
       ↓
VERIFICAR PR
       ↓
GANHAR XP
       ↓
COMPLETAR MISSÕES
       ↓
VERIFICAR LEVEL UP
       ↓
DESBLOQUEAR CONQUISTAS
       ↓
ATUALIZAR ESTATÍSTICAS
       ↓
VOLTAR AO SISTEMA
```

Esse é o loop fundamental do MVP.

---

# 19. BANCO DE DADOS

O aplicativo deverá possuir uma estrutura de dados capaz de armazenar pelo menos:

## Usuário

```text
id
nome
avatar
classe
título
tema
xp
nível
rank
```

## Exercício

```text
id
nome
grupo muscular
```

## Treino

```text
id
nome
data
duração
status
```

## Registro de exercício

```text
id
treino_id
exercicio_id
série
repetições
carga
volume
```

## PR

```text
id
exercicio_id
tipo
valor
data
```

## Missão

```text
id
tipo
nome
descrição
recompensa
progresso
objetivo
status
```

## Conquista

```text
id
nome
descrição
requisito
status
data_desbloqueio
```

A arquitetura exata do banco de dados deve ser definida após análise técnica do projeto.

---

# 20. O QUE NÃO FAZ PARTE DO MVP

Os seguintes recursos devem ficar fora da primeira versão:

* Loja
* Moedas
* Inventário
* Equipamentos virtuais
* Sistema de equipamentos com atributos
* Multiplayer
* Ranking entre usuários
* Feed social
* IA para criação de treinos
* IA para análise de treino
* Smartwatch
* Google Fit
* Apple Health
* Integrações externas
* Sistema complexo de notificações
* Animações elaboradas
* Sistema de Boss
* Sistema de PvP
* Sistema de guildas
* Sistema de combate

Esses recursos podem ser considerados para versões futuras.

---

# 21. REQUISITOS IMPORTANTES DE UX

O aplicativo será utilizado durante exercícios.

Portanto:

* registrar uma série deve ser rápido;
* os controles devem ser fáceis de tocar;
* informações importantes devem ser visualmente claras;
* o usuário não deve precisar navegar por várias telas para registrar uma série;
* o aplicativo deve funcionar bem em uma sessão de treino longa;
* os dados não podem ser perdidos caso o aplicativo seja fechado durante o treino.

---

# 22. FILOSOFIA DE GAMIFICAÇÃO

A gamificação deve reforçar comportamentos positivos.

O sistema deve recompensar:

* consistência;
* conclusão dos treinos;
* progresso;
* retorno após períodos sem treinar;
* estabelecimento de recordes;
* cumprimento de objetivos.

O sistema deve evitar:

* incentivar excesso de treino;
* punir descanso;
* criar ansiedade por sequência;
* recompensar registros falsos;
* transformar XP em substituto do progresso físico.

---

# 23. DIREÇÃO VISUAL

A interface deve transmitir a sensação de um "Sistema" de RPG.

Possíveis características:

* interface escura;
* elementos holográficos;
* painéis;
* barras de progresso;
* efeitos sutis;
* tipografia tecnológica;
* feedback visual para LEVEL UP;
* notificações de PR;
* telas de missão;
* hierarquia visual forte.

A inspiração pode vir de interfaces de RPG e sistemas de progressão, mas a identidade visual deve ser original.

Não utilizar diretamente personagens, imagens, logos ou outros elementos protegidos de obras existentes.

---

# 24. ARQUITETURA E TECNOLOGIA

Antes de começar a implementação, analisar:

1. Plataforma alvo;
2. Framework adequado;
3. Linguagem;
4. Banco de dados;
5. Persistência local;
6. Possibilidade de sincronização futura;
7. Arquitetura de pastas;
8. Gerenciamento de estado;
9. Testes;
10. Estratégia de build e distribuição.

### Regra importante

Não iniciar a implementação imediatamente.

Primeiro apresentar uma proposta técnica para o projeto e explicar as decisões.

A implementação deve começar somente depois de definir a arquitetura inicial.

---

# 25. METODOLOGIA DE DESENVOLVIMENTO

O projeto deve ser desenvolvido incrementalmente.

Não implementar o aplicativo inteiro de uma vez.

Ordem sugerida:

### Fase 1

Estrutura inicial do projeto.

### Fase 2

Banco de dados e modelos.

### Fase 3

Cadastro e gerenciamento de exercícios.

### Fase 4

Sistema de treinos.

### Fase 5

Registro de séries.

### Fase 6

Histórico e progressão.

### Fase 7

PRs.

### Fase 8

XP e níveis.

### Fase 9

Missões.

### Fase 10

Conquistas.

### Fase 11

Estatísticas.

### Fase 12

Perfil e personalização.

### Fase 13

Tela Sistema.

### Fase 14

Polimento e testes.

Cada fase deve ser implementada, testada e validada antes da próxima.

---

# 26. REGRAS PARA O DESENVOLVIMENTO COM CLAUDE

O Claude deve:

* analisar este documento antes de implementar;
* não assumir requisitos que não foram definidos;
* apresentar decisões arquiteturais antes de grandes mudanças;
* manter o código organizado;
* evitar dependências desnecessárias;
* criar componentes reutilizáveis;
* separar lógica de negócio da interface;
* criar testes para sistemas críticos;
* evitar implementar recursos fora do MVP sem autorização;
* explicar alterações relevantes;
* trabalhar em pequenas etapas;
* testar cada etapa antes de prosseguir.

Quando houver uma decisão de design não definida neste documento, o Claude deve apresentar opções e aguardar decisão antes de implementar uma solução que altere significativamente o funcionamento do sistema.

---

# 27. CRITÉRIO DE CONCLUSÃO DO MVP

O MVP será considerado funcional quando o usuário conseguir:

```text
Criar exercícios
      ↓
Criar um treino
      ↓
Iniciar o treino
      ↓
Registrar séries, repetições e cargas
      ↓
Finalizar o treino
      ↓
Visualizar seu histórico
      ↓
Visualizar progresso
      ↓
Receber XP
      ↓
Subir de nível
      ↓
Completar missões
      ↓
Desbloquear conquistas
      ↓
Visualizar estatísticas
      ↓
Personalizar seu perfil
      ↓
Visualizar tudo na tela Sistema
```

---

# 28. VISÃO FUTURA

Após o MVP estar estável, o projeto poderá evoluir para:

### Versão 2

* moedas;
* loja;
* inventário;
* equipamentos;
* títulos desbloqueáveis;
* mais personalização;
* desafios especiais;
* Boss mensal;
* sistema avançado de atributos.

### Versão 3

* IA;
* análise automática de progressão;
* recomendações;
* integração com dispositivos;
* dados de saúde;
* notificações inteligentes.

### Versão 4

* recursos sociais;
* grupos;
* desafios entre usuários;
* rankings opcionais;
* sistemas cooperativos.

Essas versões não devem influenciar a arquitetura de maneira que aumente desnecessariamente a complexidade do MVP.

---

# 29. RESUMO DO PRODUTO

O aplicativo é essencialmente:

> **Um sistema de progressão gamificado para acompanhar a evolução na academia.**

O usuário treina.

Registra seu desempenho.

O sistema identifica progresso.

O usuário recebe XP.

Completa missões.

Desbloqueia conquistas.

Sobe de nível.

Acompanha suas estatísticas.

E retorna ao treino para continuar evoluindo.

O objetivo é fazer o usuário olhar para a própria evolução e sentir:

> **"Estou ficando mais forte."**

Plataforma principal:
Android

Framework:
Flutter

Linguagem:
Dart

Banco de dados:
SQLite

Camada de acesso ao banco:
Drift

Gerenciamento de estado:
Riverpod

Navegação:
go_router

Gráficos:
fl_chart

Testes:
flutter_test

Análise estática:
Dart Analyzer

Formatação:
dart format

Controle de versão:
Git

Repositório:
GitHub

IDE:
VS Code ou Android Studio

Backend:
Não utilizar no MVP

Autenticação:
Não utilizar no MVP

Serviços de nuvem:
Não utilizar no MVP

Arquitetura:
Offline-first / local-first