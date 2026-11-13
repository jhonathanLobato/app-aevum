/// Modalidades esportivas fixas (Fase 1 do módulo Atividades). Não existe
/// "Outra" nem modalidade personalizada nesta versão.
enum SportType {
  corridaCaminhada('Corrida/Caminhada', usaDistancia: true),
  ciclismo('Ciclismo', usaDistancia: true),
  muayThaiBoxe('Muay Thai/Boxe', usaRounds: true),
  jiuJitsu('Jiu Jitsu'),
  basquete('Basquete'),
  futebol('Futebol'),
  skate('Skate');

  const SportType(this.nome,
      {this.usaDistancia = false, this.usaRounds = false});

  final String nome;

  /// Corrida, ciclismo e caminhada aceitam distância (opcional).
  final bool usaDistancia;

  /// Boxe e Muay Thai aceitam rounds (opcional).
  final bool usaRounds;

  /// Ritmo médio (min/km) faz sentido pra corrida e caminhada.
  bool get calculaRitmo => this == SportType.corridaCaminhada;

  /// Velocidade média (km/h) faz sentido pro ciclismo.
  bool get calculaVelocidade => this == SportType.ciclismo;

  /// Converte o parâmetro de rota (`SportType.name`) de volta pro enum.
  static SportType? fromName(String? name) {
    for (final tipo in SportType.values) {
      if (tipo.name == name) return tipo;
    }
    return null;
  }
}

/// Registro esportivo manual. Atividades NÃO concedem XP, nível, rank,
/// missões, conquistas, PR nem atributos — este módulo é só um diário.
class SportActivity {
  const SportActivity({
    required this.id,
    required this.tipo,
    required this.data,
    required this.duracaoMinutos,
    required this.criadoEm,
    this.distanciaKm,
    this.rounds,
    this.observacoes,
  });

  final int id;
  final SportType tipo;
  final DateTime data;
  final int duracaoMinutos;
  final double? distanciaKm;
  final int? rounds;
  final String? observacoes;
  final DateTime criadoEm;

  /// Ritmo médio em minutos por km (derivado, não persistido). `null` quando
  /// a modalidade não calcula ritmo ou não há distância > 0.
  double? get ritmoMinPorKm {
    final km = distanciaKm;
    if (!tipo.calculaRitmo || km == null || km <= 0) return null;
    return duracaoMinutos / km;
  }

  /// Velocidade média em km/h (derivada, não persistida).
  double? get velocidadeMediaKmh {
    final km = distanciaKm;
    if (!tipo.calculaVelocidade || km == null || km <= 0) return null;
    return km / (duracaoMinutos / 60);
  }
}

/// Dados de criação/edição de um registro.
class SportActivityInput {
  const SportActivityInput({
    required this.tipo,
    required this.data,
    required this.duracaoMinutos,
    this.distanciaKm,
    this.rounds,
    this.observacoes,
  });

  final SportType tipo;
  final DateTime data;
  final int duracaoMinutos;
  final double? distanciaKm;
  final int? rounds;
  final String? observacoes;

  /// Regras simples de validação (seção 17 da especificação).
  List<SportActivityError> validar() {
    return [
      if (duracaoMinutos <= 0) SportActivityError.duracaoInvalida,
      if (distanciaKm != null && distanciaKm! < 0)
        SportActivityError.distanciaNegativa,
      if (rounds != null && rounds! < 0) SportActivityError.roundsNegativo,
    ];
  }
}

enum SportActivityError { duracaoInvalida, distanciaNegativa, roundsNegativo }

class SportActivityValidationException implements Exception {
  const SportActivityValidationException(this.erros);

  final List<SportActivityError> erros;

  @override
  String toString() => 'SportActivityValidationException($erros)';
}
