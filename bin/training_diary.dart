import 'package:training_diary/training_diary.dart';

/// Кількість найдовших тренувань у розділі «Топ» звіту.
const int _reportTopCount = 3;

/// Точка входу: розбирає вбудовані дані, виводить помилки розбору та
/// валідації, а потім — текстовий звіт.
void main() {
  final today = DateTime.now();

  final (:workouts, :errors) = parseAll(rawWorkouts);
  print(
    'Прочитано рядків: ${rawWorkouts.length}, '
    'розібрано: ${workouts.length}, з помилками: ${errors.length}',
  );
  if (errors.isNotEmpty) {
    print('\n--- Помилки розбору ---');
    errors.forEach(print);
  }

  final (:valid, :invalid) = splitByValidity(workouts, today: today);
  if (invalid.isNotEmpty) {
    print('\n--- Порушення допустимих меж ---');
    for (final (:workout, :issues) in invalid) {
      print('${formatWorkout(workout)}\n  → ${issues.join('; ')}');
    }
  }

  print('');
  print(buildReport(valid, topCount: _reportTopCount, today: today));
}
