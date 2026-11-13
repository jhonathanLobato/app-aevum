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
* finalizar exercício;
* finalizar treino;
* consultar histórico.

## 4.1 Finalizar exercício x finalizar treino

São duas ações diferentes, com efeitos diferentes:

* **Finalizar exercício** é reversível e só organiza o treino em andamento.
  No treino ativo, esconde todo o conteúdo do quadro "Nova série" (campos de
  carga e repetições e o botão de registrar) e mostra apenas o botão
  "Retornar ao exercício". Ao tocar nele, os campos voltam e é possível
  registrar novas séries. O estado de exercício finalizado é salvo no banco e
  sobrevive ao fechamento do aplicativo. Não gera XP nem altera PRs.
* **Finalizar treino** pede confirmação e, depois de confirmado, encerra o
  treino **definitivamente**: concede o XP de conclusão, avança as missões e
  verifica as conquistas. **Não existe "reabrir" ou "retornar treino"** —
  um treino concluído é somente leitura (aparece no histórico).

A carga e as repetições digitadas e ainda não registradas são salvas no banco
e restauradas ao reabrir o treino.

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

## 7.1 Regras de detecção de PR

* **O primeiro registro de um exercício não é recorde.** A primeira vez que
  um exercício recebe uma série (em qualquer treino) apenas estabelece a
  referência: não gera PR, não dá XP, não mostra o diálogo de PR e não cria
  missão de desafio. Isso vale para todas as séries desse primeiro treino.
* **A comparação é com o melhor resultado ANTERIOR ao treino atual**, isto é,
  com as séries de treinos já concluídos. Séries do próprio treino em
  andamento não servem de referência.
* **Cada tipo de PR (carga, repetições, volume) conta no máximo uma vez por
  exercício por treino.** Se, no mesmo treino, uma série seguinte superar de
  novo o mesmo tipo, o valor do recorde é atualizado, mas não há novo PR, XP
  ou diálogo.
* As conquistas que dependem de PR ("Evolução", "Quebra de Recorde",
  "Superação") só contam PRs gerados por essas regras.
* "PR ATUAL" exibido no treino é a maior carga já registrada no exercício
  (inclui a referência do primeiro treino).

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

> **Atualizado — ver a seção 30.**

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

> **Atualizado — ver a seção 30.**

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

> **Atualizado — ver a seção 30.**

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

> **Atualizado — ver a seção 30.**

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

---

# 30. REGRAS ATUAIS — MISSÃO DIÁRIA, FOLGAS, PENALIDADE, EXAME DE RANK E NAVEGAÇÃO

Esta seção vale sobre as anteriores quando houver conflito.

## 30.1 Navegação (5 abas)

SISTEMA, TREINOS, ATIVIDADES, MISSÕES, STATUS.

* **SISTEMA** (ordem): cabeçalho do jogador (avatar que abre o Perfil, nome,
  classe, nível, rank, barra de XP, aviso de penalidade); resumo da missão
  diária (3 barras; toque abre a tela da missão); "Hoje" (treino programado
  ou "Descanso programado" com "Iniciar treino", ou o cartão do treino em
  andamento); exame de rank (só se ativo); faixa da semana com contador de
  folgas. Sem atalho de Histórico/Exercícios nem "Progresso recente".
* **TREINOS**: quadro "Minha semana" (só mostra os dias marcados, ex. "Seg ·
  Qua · Sex"; tocar abre a tela `/week` com os 7 dias e o botão "Salvar" —
  sair sem salvar descarta), meus treinos (inclui a biblioteca A–F), botão
  Exercícios, cartão de treino em andamento. Criar/renomear treino é um
  diálogo.
* **ATIVIDADES**: 7 modalidades — Corrida/Caminhada, Ciclismo, Muay Thai/Boxe,
  Jiu Jitsu, Basquete, Futebol e Skate (registros antigos migrados).
* **MISSÕES**: Missão Diária no topo, penalidade pendente, semanal, desafios,
  exame de rank e concluídas recentemente.
* **STATUS**, em quadros nesta ordem: **Rank** (rank, nível e estado do
  próximo exame; abre a tela de Rank), **Relatório semanal** (e lista de
  anteriores), um quadro único com as entradas **Histórico** e
  **Conquistas**, e as estatísticas globais. Os atributos
  (Força/Resistência/Constância) estão comentados na tela (código mantido
  para uso futuro) e o "Detalhe por exercício" foi removido (o histórico
  cobre). A identidade fica só na tela Sistema.
* **Tela de Rank** (`/rank`): lugar único de tudo sobre rank — explica os
  ranks F a S (nível mínimo, tempo mínimo, requisitos de cada exame), a
  janela de 7 dias e a regra de reinício; mostra o que falta para liberar o
  próximo exame (nível e dias) ou o progresso do exame em andamento (cada
  requisito em número absoluto e os dias restantes) e o botão "Iniciar
  exame". Os cards de exame na Sistema e em Missões são só um resumo que
  leva para essa tela.

## 30.2 Missão diária

Todos os dias, inclusive de descanso: **50 flexões, 50 abdominais e 2 km** de
caminhada/corrida, somados ao longo do dia (botões +10/+25, campo livre e
desfazer; km em vários registros). Vale **50 XP** e só quando as 3 partes
estão completas (parcial não dá XP nem evita a penalidade). Tela própria
(`/missions/daily`). É separada dos treinos de academia: **não** conta como
treino para missão semanal, exame de rank nem estatísticas. Os km da missão
ficam só nela; corrida/caminhada fora da missão vai para Atividades; um não
conta para o outro e ciclismo não conta.

## 30.3 Programação semanal e missão semanal

O usuário escolhe livremente os dias de treino (os demais são descanso). A
missão semanal é "concluir todos os treinos de academia programados na
semana" (tudo ou nada). XP por treinos programados: 1=50, 2=100, 3=150,
4=250, 5=300, 6=350, 7=400. Sem programação não há missão semanal. O desafio
de carga por exercício continua como antes.

## 30.4 Folgas e penalidade

* **4 folgas por mês**, sem acumular. Marcadas tocando no dia (hoje ou
  futuro) na faixa da semana ou na tela da missão diária. Dia de folga não
  cobra a missão nem dá XP. Faixa: ✔ cumprida, ⏸ folga, ✖ falhou, ◉ hoje, ○
  futuro, ponto nos dias de treino.
* **Penalidade**: na virada do dia, missão do dia anterior não cumprida e sem
  folga perde **100 XP**, no máximo **300 XP por semana** (seg–dom). O XP nunca
  fica abaixo do início do nível atual (não cai de nível) e o rank nunca cai.
  Aviso vermelho na próxima abertura, até o usuário confirmar.

## 30.5 Curva de nível, rank e exame de rank

**Curva**: XP para sair do nível n = `480 + 10 × n` (XP **por nível**; o XP
total para entrar num nível é a soma dos anteriores). Níveis mínimos para
liberar o exame de cada rank: **E=10, D=25, C=45, B=70, A=100, S=140** (XP
total: 4.770 / 14.520 / 31.020 / 57.270 / 97.020 / 164.020).

**Liberação**: o nível sobe pelo XP, mas o **rank só sobe ao passar no
exame**. O exame do próximo rank só é liberado quando os DOIS forem
cumpridos: o nível mínimo do próximo rank **e** um tempo mínimo no rank
atual — **F=2, E=3, D=5, C=7, B=9, A=10 meses** (contados da data em que
entrou no rank; usuários antigos contam a partir da data da migração).

**Início (manual)**: o exame não começa sozinho ao ser liberado. Na abertura
do app aparece o aviso "[SISTEMA] Exame de reavaliação disponível". O usuário
tem **7 dias** para iniciá-lo na tela de Rank, escolhendo as atividades
extras; o prazo do exame conta a partir do início. Se não iniciar, no 8º dia
o exame começa sozinho, com as modalidades extras mais registradas pelo
usuário, e um aviso. Para iniciar (manual ou automático) é preciso ter **2+
dias de treino programados por semana**; senão o início espera.

Requisitos, todos dentro do prazo:

| Exame | Prazo | Treinos programados cumpridos | Missão diária cumprida | Atividades extras |
| ----- | ----: | ----------------------------: | ---------------------: | ----------------- |
| F→E | 35 dias | 80% | 75% | 3 modalidades, 1 registro cada |
| E→D | 50 dias | 80% | 75% | 3 modalidades, 2 registros cada |
| D→C | 70 dias | 85% | 80% | 3 modalidades, 2 registros cada |
| C→B | 90 dias | 85% | 80% | 4 modalidades, 2 registros cada |
| B→A | 110 dias | 90% | 85% | 4 modalidades, 3 registros cada |
| A→S | 140 dias | 95% | 90% | 4 modalidades, 3 registros cada |

* **Meta de treinos** = ⌈% × treinos programados nos dias do período⌉, mostrada
  em número absoluto. Conta 1 treino de academia concluído por dia.
* **Folga** tira o dia do cálculo da missão diária e, se era dia de treino,
  tira aquele treino da meta.
* Durante o exame a programação semanal **pode ganhar dias, mas não perder**
  (a tela "Minha semana" trava a remoção dos dias salvos).
* Atividades extras: só contam registros de 30+ min nas modalidades escolhidas.
* **Reinício**: quando a meta de treinos ou a de missões diárias fica
  matematicamente impossível, ou o prazo acaba incompleto, o progresso zera e
  abre uma **nova janela de 7 dias** para iniciar de novo (as atividades
  extras são escolhidas outra vez; sem iniciar, começa sozinho no 8º dia).
* Ao passar: overlay "RANK UP" e a conquista "Rank E" conforme o exame. Se o
  app estiver fechado, o RANK UP fica **pendente** e o overlay aparece na
  próxima abertura (até ser exibido). Passar de rank reinicia a contagem do
  tempo mínimo no novo rank.

## 30.6 Biblioteca padrão e treinos

Na primeira instalação (ou na migração, se não houver treino) são criados 6
treinos — A Push 1, B Pull 1, C Legs 1, D Push 2, E Pull 2, F Legs 2 — só com
os exercícios (sem séries/repetições-alvo; a meta de séries × repetições foi
removida). Exercícios repetidos são o mesmo registro. Tudo editável/apagável.

## 30.7 Relatório semanal

Cartão em Status com treinos concluídos, atividades registradas e recordes
quebrados da semana (seg–dom); relatórios anteriores numa lista (`/reports`).
Calculado dos dados reais.

## 30.8 XP de atividades extras

Cada registro de **30+ min** em Atividades vale **+30 XP**, no máximo
**3 por semana** (segunda a domingo; vale a data da atividade). Editar (data
ou duração) ou excluir o registro reconcilia a semana e ajusta o XP (o 4º
registro da semana entra no limite se um dos 3 primeiros sair). Continuam sem
PR, missão, conquista nem contar como treino de academia.

## 30.9 Calibração esperada (simulação)

Com estas regras (curva 480+10n, tempo mínimo por rank, exames acima) e PRs
mais raros ao longo do tempo (meia-vida de 12 meses, piso de 25%), supondo
que o exame é iniciado no dia da liberação:

| Perfil | Tempo até o rank S |
| ------ | ------------------ |
| Hardcore (6 treinos/sem, missão 100%) | ~4,2 anos |
| Constante (4 treinos/sem, missão 90%) | ~4,2 anos |
| Casual (3 treinos/sem), missão em 80% dos dias | ~4,7 anos |
| Casual (3 treinos/sem), missão em 70% dos dias | não passa do B (o exame B→A pede 85% de missões) |

O tempo mínimo por rank (36 meses no total) domina: Hardcore e Constante
empatam no S, e o XP só pesa para o Casual.
