import 'package:training_diary/training_diary.dart';

/// Точка входу: розбирає вбудовані дані та виводить помилки розбору.
void main() {
  final (:workouts, :errors) = parseAll(rawWorkouts);
  print(
    'Прочитано рядків: ${rawWorkouts.length}, '
    'розібрано: ${workouts.length}, з помилками: ${errors.length}',
  );
  if (errors.isNotEmpty) {
    print('\n--- Помилки розбору ---');
    errors.forEach(print);
  }
}
