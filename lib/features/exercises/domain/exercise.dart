class Exercise {
  const Exercise({
    required this.id,
    required this.nome,
    required this.grupoMuscular,
  });

  final int id;
  final String nome;
  final String grupoMuscular;

  Exercise copyWith({String? nome, String? grupoMuscular}) {
    return Exercise(
      id: id,
      nome: nome ?? this.nome,
      grupoMuscular: grupoMuscular ?? this.grupoMuscular,
    );
  }
}
