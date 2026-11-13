/// Unidades de exibição/entrada. O banco guarda SEMPRE kg e cm; só a tela
/// converte (peso: kg/lb; comprimento: cm/pol). Distância segue em km.
enum WeightUnit { kg, lb }

enum LengthUnit { cm, pol }

enum Sexo { masculino, feminino }

class Units {
  const Units({this.peso = WeightUnit.kg, this.comprimento = LengthUnit.cm});

  static const kgPorLb = 0.45359237;
  static const cmPorPol = 2.54;

  final WeightUnit peso;
  final LengthUnit comprimento;

  double pesoParaExibir(double kg) => peso == WeightUnit.kg ? kg : kg / kgPorLb;
  double pesoParaBanco(double valor) =>
      peso == WeightUnit.kg ? valor : valor * kgPorLb;
  double comprimentoParaExibir(double cm) =>
      comprimento == LengthUnit.cm ? cm : cm / cmPorPol;
  double comprimentoParaBanco(double valor) =>
      comprimento == LengthUnit.cm ? valor : valor * cmPorPol;

  String get pesoSufixo => peso == WeightUnit.kg ? 'KG' : 'LB';
  String get comprimentoSufixo => comprimento == LengthUnit.cm ? 'CM' : 'POL';

  /// Peso (em kg no banco) já convertido, ex.: "32.5 KG" / "71.7 LB".
  String formatarPeso(double kg, {int casas = 1, bool sufixo = true}) {
    final texto = pesoParaExibir(kg).toStringAsFixed(casas);
    return sufixo ? '$texto $pesoSufixo' : texto;
  }

  String formatarComprimento(double cm, {int casas = 1, bool sufixo = true}) {
    final texto = comprimentoParaExibir(cm).toStringAsFixed(casas);
    return sufixo ? '$texto $comprimentoSufixo' : texto;
  }

  @override
  bool operator ==(Object other) =>
      other is Units && other.peso == peso && other.comprimento == comprimento;

  @override
  int get hashCode => Object.hash(peso, comprimento);
}
