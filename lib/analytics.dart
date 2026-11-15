/// Конвеєри обробки, групування та сортування тренувань.
library;

import 'constants.dart';
import 'workout.dart';

// ---------------------------------------------------------------------------
// Фабрики предикатів (замикання)
// ---------------------------------------------------------------------------

/// Створює предикат, що відбирає тренування виду [activity].
///
/// Повернена функція захоплює параметр [activity].
WorkoutPredicate byActivity(String activity) =>
    (workout) => workout.activity == activity;

/// Створює предикат, що відбирає тренування з дистанцією не менше [km].
///
/// Повернена функція захоплює параметр [km].
WorkoutPredicate minDistance(double km) =>
    (workout) => workout.distanceKm >= km;

/// Предикат: тренування з ненульовою дистанцією (біг, велосипед тощо).
bool hasDistance(Workout workout) => workout.distanceKm > 0;

// ---------------------------------------------------------------------------
// Згортання до агрегованих значень
// ---------------------------------------------------------------------------

/// Обчислює сумарну дистанцію тренувань [items], км.
double totalDistance(Iterable<Workout> items) =>
    items.map((workout) => workout.distanceKm).fold(0, (sum, km) => sum + km);

/// Обчислює сумарну тривалість тренувань [items].
Duration totalDuration(Iterable<Workout> items) => items
    .map((workout) => workout.duration)
    .fold(Duration.zero, (sum, duration) => sum + duration);

/// Обчислює середній пульс тренувань [items].
///
/// Повертає `null` для порожньої колекції, оскільки середнє в цьому випадку
/// не визначене.
double? averageHeartRate(Iterable<Workout> items) {
  if (items.isEmpty) return null;
  final sum = items
      .map((workout) => workout.heartRate)
      .fold(0, (total, pulse) => total + pulse);
  return sum / items.length;
}

/// Знаходить найтриваліше тренування серед [items].
///
/// Повертає `null` для порожньої колекції. Використано `fold` з початковим
/// значенням `null`, а не `reduce`, який кидає виняток на порожній колекції.
Workout? longestWorkout(Iterable<Workout> items) => items.fold<Workout?>(
  null,
  (best, workout) =>
      best == null || workout.duration > best.duration ? workout : best,
);

/// Знаходить перше інтенсивне тренування (пульс не нижче
/// [highIntensityHeartRate]) або `null`, якщо таких немає.
Workout? firstHighIntensity(Iterable<Workout> items) => items
    .where((workout) => workout.heartRate >= highIntensityHeartRate)
    .firstOrNull;

// ---------------------------------------------------------------------------
// Перетворення
// ---------------------------------------------------------------------------

/// Обчислює темп тренування [workout] у секундах на кілометр.
///
/// Повертає `null`, якщо дистанція нульова — темп у цьому випадку не має
/// сенсу.
int? paceSecondsPerKm(Workout workout) {
  if (workout.distanceKm <= 0) return null;
  return (workout.duration.inSeconds / workout.distanceKm).round();
}

/// Обчислює вік запису [workout] у днях відносно дати [today].
int ageInDays(Workout workout, DateTime today) =>
    today.difference(workout.date).inDays;

/// Перетворює тренування з дистанцією на пари «опис — темп».
///
/// Конвеєр: фільтрація ([hasDistance]) → перетворення.
List<({String label, int paceSeconds})> paces(Iterable<Workout> items) => items
    .where(hasDistance)
    .map(
      (workout) => (
        label: '${workout.activity} ${formatDateShort(workout.date)}',
        paceSeconds: paceSecondsPerKm(workout) ?? 0,
      ),
    )
    .toList();

/// Форматує дату [date] як `yyyy-MM-dd`.
String formatDateShort(DateTime date) {
  final month = date.month.toString().padLeft(twoDigits, '0');
  final day = date.day.toString().padLeft(twoDigits, '0');
  return '${date.year}-$month-$day';
}

// ---------------------------------------------------------------------------
// Групування
// ---------------------------------------------------------------------------

/// Групує тренування [items] за видом активності.
Map<String, List<Workout>> groupByActivity(Iterable<Workout> items) =>
    items.fold(<String, List<Workout>>{}, (groups, workout) {
      groups.putIfAbsent(workout.activity, () => []).add(workout);
      return groups;
    });

/// Обчислює для кожної групи з [groups] кількість тренувань, сумарну
/// тривалість, сумарну дистанцію та середній пульс.
Map<
  String,
  ({int count, Duration duration, double distanceKm, double avgHeartRate})
>
summarizeGroups(Map<String, List<Workout>> groups) => groups.map(
  (activity, items) => MapEntry(activity, (
    count: items.length,
    duration: totalDuration(items),
    distanceKm: totalDistance(items),
    avgHeartRate: averageHeartRate(items) ?? 0,
  )),
);

// ---------------------------------------------------------------------------
// Сортування
// ---------------------------------------------------------------------------

/// Порівнює тренування за датою.
int compareByDate(Workout a, Workout b) => a.date.compareTo(b.date);

/// Порівнює тренування за дистанцією.
int compareByDistance(Workout a, Workout b) =>
    a.distanceKm.compareTo(b.distanceKm);

/// Порівнює тренування за тривалістю.
int compareByDuration(Workout a, Workout b) => a.duration.compareTo(b.duration);

/// Повертає нову відсортовану копію [items].
///
/// Записи впорядковуються за критерієм [by]; записи, рівні за ним,
/// додатково впорядковуються за [thenBy], якщо його передано. Напрям
/// сортування задається параметром [ascending] і застосовується до обох
/// критеріїв. Вихідний список не змінюється.
List<Workout> sortWorkouts(
  Iterable<Workout> items, {
  required WorkoutComparator by,
  WorkoutComparator? thenBy,
  bool ascending = true,
}) {
  int compare(Workout a, Workout b) {
    final primary = by(a, b);
    if (primary != 0 || thenBy == null) return primary;
    return thenBy(a, b);
  }

  return [...items]..sort((a, b) => ascending ? compare(a, b) : compare(b, a));
}
