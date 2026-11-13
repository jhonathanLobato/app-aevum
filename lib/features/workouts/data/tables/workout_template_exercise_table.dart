import 'package:drift/drift.dart';

import '../../../exercises/data/tables/exercise_table.dart';
import 'workout_template_table.dart';

/// Associa exercícios a um treino, com ordem.
class WorkoutTemplateExercises extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get templateId => integer()
      .references(WorkoutTemplates, #id, onDelete: KeyAction.cascade)();
  IntColumn get exerciseId => integer().references(Exercises, #id)();
  IntColumn get ordem => integer()();
}
