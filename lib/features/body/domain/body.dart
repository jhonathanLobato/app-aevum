import '../../profile/domain/units.dart';

/// Medidas de um registro corporal. Peso em kg e medidas em cm no banco.
enum BodyMeasure {
  peso('Peso'),
  gordura('% Gordura'),
  braco('Braço'),
  peito('Peito'),
  cintura('Cintura'),
  quadril('Quadril'),
  coxa('Coxa'),
  panturrilha('Panturrilha');

  const BodyMeasure(this.label);
  final String label;

  bool get ehPeso => this == peso;
  bool get ehGordura => this == gordura;
  bool get ehComprimento => !ehPeso && !ehGordura;

  /// Valor guardado (kg / % / cm) deste registro, ou null se não informado.
  double? de(BodyRecord r) => switch (this) {
        peso => r.pesoKg,
        gordura => r.gorduraPct,
        braco => r.bracoCm,
        peito => r.peitoCm,
        cintura => r.cinturaCm,
        quadril => r.quadrilCm,
        coxa => r.coxaCm,
        panturrilha => r.panturrilhaCm,
      };

  /// Valor convertido para a unidade de exibição (sem sufixo).
  double paraExibir(double v, Units u) => ehPeso
      ? u.pesoParaExibir(v)
      : ehComprimento
          ? u.comprimentoParaExibir(v)
          : v;

  double paraBanco(double v, Units u) => ehPeso
      ? u.pesoParaBanco(v)
      : ehComprimento
          ? u.comprimentoParaBanco(v)
          : v;

  String sufixo(Units u) => ehPeso
      ? u.pesoSufixo
      : ehGordura
          ? '%'
          : u.comprimentoSufixo;

  String formatar(double v, Units u, {bool comSufixo = true}) {
    final t = paraExibir(v, u).toStringAsFixed(1);
    return comSufixo ? '$t ${sufixo(u)}' : t;
  }
}

class BodyRecord {
  const BodyRecord({
    required this.id,
    required this.data,
    this.pesoKg,
    this.gorduraPct,
    this.bracoCm,
    this.peitoCm,
    this.cinturaCm,
    this.quadrilCm,
    this.coxaCm,
    this.panturrilhaCm,
  });

  final int id;
  final DateTime data;
  final double? pesoKg,
      gorduraPct,
      bracoCm,
      peitoCm,
      cinturaCm,
      quadrilCm,
      coxaCm,
      panturrilhaCm;
}

/// Valores de um registro a gravar (tudo opcional, mas ao menos um).
class BodyRecordInput {
  const BodyRecordInput({
    required this.data,
    this.pesoKg,
    this.gorduraPct,
    this.bracoCm,
    this.peitoCm,
    this.cinturaCm,
    this.quadrilCm,
    this.coxaCm,
    this.panturrilhaCm,
  });

  final DateTime data;
  final double? pesoKg,
      gorduraPct,
      bracoCm,
      peitoCm,
      cinturaCm,
      quadrilCm,
      coxaCm,
      panturrilhaCm;

  bool get temValor => [
        pesoKg,
        gorduraPct,
        bracoCm,
        peitoCm,
        cinturaCm,
        quadrilCm,
        coxaCm,
        panturrilhaCm
      ].any((v) => v != null);
}

/// IMC = peso (kg) / altura (m)². `null` sem peso ou altura válidos.
double? calcularImc(double? pesoKg, double? alturaCm) {
  if (pesoKg == null || alturaCm == null || alturaCm <= 0 || pesoKg <= 0) {
    return null;
  }
  final m = alturaCm / 100;
  return pesoKg / (m * m);
}

String faixaImc(double imc) {
  if (imc < 18.5) return 'Abaixo do peso';
  if (imc < 25) return 'Normal';
  if (imc < 30) return 'Sobrepeso';
  return 'Obesidade';
}

int idadeEm(DateTime nascimento, DateTime hoje) {
  var idade = hoje.year - nascimento.year;
  final fezAniversario = hoje.month > nascimento.month ||
      (hoje.month == nascimento.month && hoje.day >= nascimento.day);
  if (!fezAniversario) idade--;
  return idade;
}

/// Evolução de uma medida: série cronológica e comparações.
class MeasureEvolution {
  const MeasureEvolution(this.pontos);

  /// (data, valor guardado) dos registros que têm a medida, em ordem de data.
  final List<({DateTime data, double valor})> pontos;

  bool get vazia => pontos.isEmpty;
  double? get primeiro => pontos.isEmpty ? null : pontos.first.valor;
  double? get ultimo => pontos.isEmpty ? null : pontos.last.valor;
  double? get anterior =>
      pontos.length < 2 ? null : pontos[pontos.length - 2].valor;

  /// Variação do último registro em relação ao primeiro / ao anterior (nos
  /// valores guardados; converta com [BodyMeasure.paraExibir] para exibir).
  double? get variacaoDesdePrimeiro =>
      pontos.length < 2 ? null : ultimo! - primeiro!;
  double? get variacaoDesdeAnterior =>
      pontos.length < 2 ? null : ultimo! - anterior!;
}

MeasureEvolution evolucaoDe(List<BodyRecord> registros, BodyMeasure medida) {
  final ordenados = [...registros]..sort((a, b) {
      final c = a.data.compareTo(b.data);
      return c != 0 ? c : a.id.compareTo(b.id);
    });
  return MeasureEvolution([
    for (final r in ordenados)
      if (medida.de(r) != null) (data: r.data, valor: medida.de(r)!),
  ]);
}
