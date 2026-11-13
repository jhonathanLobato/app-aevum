/// Deslocamento do fuso local em relação ao UTC para o instante [utc].
typedef DeslocamentoLocal = Duration Function(DateTime utc);

Duration deslocamentoDoAparelho(DateTime utc) => utc.toLocal().timeZoneOffset;

/// Maior sequência de dias corridos consecutivos com pelo menos um instante
/// em [instantes], contando o dia no FUSO LOCAL (e não em UTC): um treino às
/// 22h em Brasília é do dia local, mesmo que em UTC já seja o dia seguinte.
///
/// [deslocamento] existe para os testes fixarem um fuso (ex.: UTC-3); por
/// padrão usa o fuso do aparelho.
int maiorSequenciaDeDias(
  Iterable<DateTime> instantes, {
  DeslocamentoLocal deslocamento = deslocamentoDoAparelho,
}) {
  const msPorDia = Duration.millisecondsPerDay;
  final dias = <int>{
    for (final instante in instantes)
      () {
        final utc = instante.toUtc();
        final local = utc.add(deslocamento(utc));
        return local.millisecondsSinceEpoch ~/ msPorDia -
            (local.millisecondsSinceEpoch < 0 &&
                    local.millisecondsSinceEpoch % msPorDia != 0
                ? 1
                : 0);
      }(),
  }.toList()
    ..sort();

  var melhor = 0;
  var atual = 0;
  int? anterior;
  for (final dia in dias) {
    atual = anterior != null && dia == anterior + 1 ? atual + 1 : 1;
    if (atual > melhor) melhor = atual;
    anterior = dia;
  }
  return melhor;
}
