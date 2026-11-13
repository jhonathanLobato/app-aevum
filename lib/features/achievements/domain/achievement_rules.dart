// Regras puras (sem banco) usadas pelas conquistas que dependem de datas.

/// Um dia da missão diária, como guardado em `daily_days`.
class DiaDaMissao {
  const DiaDaMissao({
    required this.dia,
    required this.concluida,
    required this.folga,
    required this.processado,
  });

  final DateTime dia;
  final bool concluida;
  final bool folga;

  /// `true` quando a virada já avaliou o dia (hoje e o futuro não contam
  /// como falha).
  final bool processado;
}

DateTime _soData(DateTime d) => DateTime(d.year, d.month, d.day);

/// Maior sequência de dias seguidos com a missão diária cumprida.
///
/// * Dia cumprido soma 1.
/// * Folga é neutra: não quebra a sequência, mas também não soma.
/// * Dia ainda não avaliado (hoje) é neutro.
/// * Dia falhado, ou um buraco de dias sem registro, zera a sequência.
int maiorSequenciaDaMissao(Iterable<DiaDaMissao> dias) {
  final ordenados = dias.toList()..sort((a, b) => a.dia.compareTo(b.dia));
  var atual = 0;
  var melhor = 0;
  DateTime? anterior;
  for (final d in ordenados) {
    final dia = _soData(d.dia);
    if (anterior != null) {
      final salto = DateTime.utc(dia.year, dia.month, dia.day)
          .difference(DateTime.utc(anterior.year, anterior.month, anterior.day))
          .inDays;
      if (salto > 1) atual = 0;
    }
    anterior = dia;
    if (d.concluida) {
      atual++;
      if (atual > melhor) melhor = atual;
    } else if (d.folga || !d.processado) {
      // neutro
    } else {
      atual = 0;
    }
  }
  return melhor;
}

/// `true` se existe um mês civil já encerrado (anterior ao de [hoje]) em que
/// todos os dias foram registrados, avaliados e cumpridos (ou de folga) — ou
/// seja, nenhum dia falhado e nenhuma penalidade.
bool temMesLimpo(Iterable<DiaDaMissao> dias, DateTime hoje) {
  final porMes = <int, List<DiaDaMissao>>{};
  for (final d in dias) {
    porMes.putIfAbsent(d.dia.year * 12 + d.dia.month - 1, () => []).add(d);
  }
  final mesAtual = hoje.year * 12 + hoje.month - 1;
  for (final e in porMes.entries) {
    if (e.key >= mesAtual) continue;
    final ano = e.key ~/ 12;
    final mes = e.key % 12 + 1;
    final diasNoMes = DateTime(ano, mes + 1, 0).day;
    final distintos = {for (final d in e.value) d.dia.day};
    if (distintos.length != diasNoMes) continue;
    if (e.value.every((d) => d.processado && (d.concluida || d.folga))) {
      return true;
    }
  }
  return false;
}

/// Maior quantidade de meses civis seguidos entre [datas] (basta uma data em
/// cada mês).
int maiorSequenciaDeMeses(Iterable<DateTime> datas) {
  final meses = {for (final d in datas) d.year * 12 + d.month - 1}.toList()
    ..sort();
  var atual = 0;
  var melhor = 0;
  int? anterior;
  for (final m in meses) {
    atual = anterior != null && m == anterior + 1 ? atual + 1 : 1;
    if (atual > melhor) melhor = atual;
    anterior = m;
  }
  return melhor;
}
