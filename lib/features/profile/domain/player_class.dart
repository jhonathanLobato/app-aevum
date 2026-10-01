/// Classes cosméticas (seção 16). Não concedem bônus de XP ou desempenho.
enum PlayerClass { guerreiro, guardiao, atleta, assassino }

String nomeDaClasse(PlayerClass classe) {
  switch (classe) {
    case PlayerClass.guerreiro:
      return 'Guerreiro';
    case PlayerClass.guardiao:
      return 'Guardião';
    case PlayerClass.atleta:
      return 'Atleta';
    case PlayerClass.assassino:
      return 'Assassino';
  }
}
