import '../../statistics/domain/statistics.dart';

/// Progresso real (atual, objetivo) de uma conquista contável, derivado só
/// na apresentação a partir de [GlobalStatistics] — nenhuma coluna nova no
/// banco, nenhuma mudança de domínio. `null` para conquistas binárias
/// (ex. "evolucao"/"superacao"/"rank_e": já tem ou não tem, uma fração não
/// faria sentido — seção 23 da Fase 8: "para conquistas binárias, não
/// inventar percentual artificial").
///
/// As chaves aqui têm que bater com `kAchievementCatalog` e com os
/// critérios reais de `DriftAchievementRepository` — se um dia divergirem,
/// o progresso mostrado na tela fica errado (puramente cosmético, não
/// afeta se a conquista desbloqueia ou não).
(int atual, int objetivo)? progressoDaConquista(
    String chave, GlobalStatistics stats) {
  switch (chave) {
    case 'primeiros_passos':
      return (stats.treinosRealizados.clamp(0, 1), 1);
    case 'disciplina':
      return (stats.treinosRealizados.clamp(0, 10), 10);
    case 'constancia':
      return (stats.treinosRealizados.clamp(0, 25), 25);
    case 'veterano':
      return (stats.treinosRealizados.clamp(0, 100), 100);
    case 'quebra_de_recorde':
      return (stats.totalPRs.clamp(0, 5), 5);
    case 'primeiro_milhar':
      return (stats.volumeTotal.clamp(0, 1000).round(), 1000);
    default:
      return null;
  }
}
