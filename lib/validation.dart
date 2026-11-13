/// Перевірка діапазонів значень розібраних тренувань.
library;

import 'constants.dart';
import 'workout.dart';

/// Перевіряє, чи значення полів тренування [workout] лежать у допустимих
/// межах.
///
/// Дата порівнюється з [today]; якщо його не передано, використовується
/// поточна дата. Повертає перелік виявлених порушень; порожній перелік
/// означає, що запис коректний.
List<String> validateWorkout(Workout workout, {DateTime? today}) {
  final now = today ?? DateTime.now();
  final (
    :date,
    :duration,
    :distanceKm,
    :heartRate,
    :wellbeing,
    activity: _,
    deviceId: _,
  ) = workout;

  return [
    if (date.year < minYear) 'рік ${date.year} раніший за $minYear',
    if (date.isAfter(now)) 'дата тренування в майбутньому',
    if (duration <= Duration.zero) 'тривалість має бути додатною',
    if (duration > maxDuration)
      'тривалість перевищує ${maxDuration.inHours} год',
    if (distanceKm < 0) 'дистанція не може бути від\'ємною',
    if (distanceKm > maxDistanceKm)
      'дистанція перевищує ${maxDistanceKm.toStringAsFixed(0)} км',
    if (heartRate < minHeartRate || heartRate > maxHeartRate)
      'пульс $heartRate поза межами $minHeartRate–$maxHeartRate',
    if (wellbeing < minWellbeing || wellbeing > maxWellbeing)
      'самопочуття $wellbeing поза межами $minWellbeing–$maxWellbeing',
  ];
}

/// Розділяє [workouts] на коректні та некоректні за [validateWorkout].
///
/// Для кожного некоректного запису повертається перелік його порушень.
({List<Workout> valid, List<({Workout workout, List<String> issues})> invalid})
splitByValidity(List<Workout> workouts, {DateTime? today}) {
  final checked = workouts
      .map(
        (workout) =>
            (workout: workout, issues: validateWorkout(workout, today: today)),
      )
      .toList();

  return (
    valid: checked
        .where((entry) => entry.issues.isEmpty)
        .map((entry) => entry.workout)
        .toList(),
    invalid: checked.where((entry) => entry.issues.isNotEmpty).toList(),
  );
}
