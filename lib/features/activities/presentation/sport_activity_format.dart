import 'package:flutter/material.dart';

import '../domain/sport_activity.dart';

const _meses = [
  'JAN',
  'FEV',
  'MAR',
  'ABR',
  'MAI',
  'JUN',
  'JUL',
  'AGO',
  'SET',
  'OUT',
  'NOV',
  'DEZ',
];

/// Ícones das modalidades (só ícones já disponíveis no Flutter).
IconData iconeDaModalidade(SportType tipo) {
  switch (tipo) {
    case SportType.corrida:
      return Icons.directions_run;
    case SportType.ciclismo:
      return Icons.directions_bike;
    case SportType.caminhada:
      return Icons.directions_walk;
    case SportType.boxe:
      return Icons.sports_mma;
    case SportType.muayThai:
      return Icons.sports_kabaddi;
    case SportType.basquete:
      return Icons.sports_basketball;
    case SportType.futebol:
      return Icons.sports_soccer;
    case SportType.skate:
      return Icons.skateboarding;
  }
}

/// "04 OUT" (ou "04 OUT 2026" com [comAno]).
String formatarDataCurta(DateTime data, {bool comAno = false}) {
  final base =
      '${data.day.toString().padLeft(2, '0')} ${_meses[data.month - 1]}';
  return comAno ? '$base ${data.year}' : base;
}

/// "04/10/2026" — usado no campo de data do formulário.
String formatarDataCompleta(DateTime data) {
  return '${data.day.toString().padLeft(2, '0')}/'
      '${data.month.toString().padLeft(2, '0')}/${data.year}';
}

/// "5,2" / "4,75" / "5" — até 2 casas, sem zeros sobrando, vírgula decimal.
String formatarNumero(double valor) {
  var texto = valor.toStringAsFixed(2);
  if (texto.contains('.')) {
    texto = texto.replaceFirst(RegExp(r'0+$'), '');
    texto = texto.replaceFirst(RegExp(r'\.$'), '');
  }
  return texto.replaceAll('.', ',');
}

String formatarDistancia(double km) => '${formatarNumero(km)} KM';

/// "31 MIN" — sempre em minutos ("60 MIN", "90 MIN"), como no histórico.
String formatarDuracao(int minutos) => '$minutos MIN';

/// "5:58 /KM" a partir de minutos por km.
String formatarRitmo(double minPorKm) {
  var minutos = minPorKm.floor();
  var segundos = ((minPorKm - minutos) * 60).round();
  if (segundos == 60) {
    minutos += 1;
    segundos = 0;
  }
  return '$minutos:${segundos.toString().padLeft(2, '0')} /KM';
}

/// "24,5 KM/H".
String formatarVelocidade(double kmh) =>
    '${formatarNumero(double.parse(kmh.toStringAsFixed(1)))} KM/H';

/// "5,2 KM · 31 MIN" / "31 MIN · 8 ROUNDS" / "45 MIN" — só o que existe.
String resumoDaAtividade(SportActivity a) {
  final partes = <String>[
    if (a.distanciaKm != null) formatarDistancia(a.distanciaKm!),
    formatarDuracao(a.duracaoMinutos),
    if (a.rounds != null) '${a.rounds} ROUNDS',
  ];
  return partes.join(' · ');
}

/// Métrica derivada (ritmo ou velocidade) quando há dados suficientes.
String? metricaDerivada(SportActivity a) {
  final ritmo = a.ritmoMinPorKm;
  if (ritmo != null) return formatarRitmo(ritmo);
  final velocidade = a.velocidadeMediaKmh;
  if (velocidade != null) return formatarVelocidade(velocidade);
  return null;
}
