import 'package:training_diary/training_diary.dart';

/// Точка входу: розбирає вбудовані дані, виводить помилки розбору та
/// валідації.
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
      print('${formatDateShort(workout.date)} ${workout.activity}');
      print('  → ${issues.join('; ')}');
    }
  }

  print('\nКоректних записів: ${valid.length}');
  print('Сумарна дистанція: ${totalDistance(valid).toStringAsFixed(1)} км');
}
