/// Valores de XP por ação (seção 8). Mantidos num só lugar para serem
/// fáceis de ajustar sem procurar pelo código.
///
/// "Completar exercício" (+10), "Completar todas as séries" (+20), "Missão
/// diária" (+50) e "Missão semanal" (+250) ainda não são concedidos: os dois
/// primeiros dependem de metas de séries/repetições por exercício que o
/// usuário ainda não define ao montar um treino, e missões são a Fase 9.
class XpValues {
  const XpValues._();

  static const finalizarTreino = 100;
  static const novoRecordePessoal = 50;
}
