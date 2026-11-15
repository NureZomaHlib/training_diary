/// Форматування текстового звіту за тренуваннями.
library;

import 'analytics.dart';
import 'constants.dart';
import 'parsing.dart';
import 'workout.dart';

/// Форматує тривалість [duration] як `г:хх`.
String formatDuration(Duration duration) {
  final minutes = (duration.inMinutes % minutesPerHour).toString().padLeft(
    twoDigits,
    '0',
  );
  return '${duration.inHours}:$minutes';
}

/// Форматує темп [secondsPerKm] як `хв:сс /км`.
String formatPace(int secondsPerKm) {
  final minutes = secondsPerKm ~/ secondsPerMinute;
  final seconds = (secondsPerKm % secondsPerMinute).toString().padLeft(
    twoDigits,
    '0',
  );
  return '$minutes:$seconds /км';
}

/// Форматує одне тренування [workout] в рядок таблиці.
///
/// Поля розділяються рядком [separator]; ідентифікатор трекера маскується.
String formatWorkout(Workout workout, {String separator = ' | '}) => [
  formatDateShort(workout.date),
  workout.activity.padRight(activityColumnWidth),
  formatDuration(workout.duration),
  '${workout.distanceKm.toStringAsFixed(fractionDigits)} км',
  '${workout.heartRate} уд/хв',
  'самоп. ${workout.wellbeing}',
  maskDeviceIds(workout.deviceId),
].join(separator);

/// Формує текстовий звіт за списком тренувань [items].
///
/// [topCount] — скільки найдовших за дистанцією тренувань показати;
/// [ascending] — напрям сортування в розділі «Хронологія»;
/// [separator] — роздільник полів у рядках таблиць;
/// [today] — дата, відносно якої рахується вік записів (за замовчуванням —
/// поточна).
String buildReport(
  List<Workout> items, {
  int topCount = 5,
  bool ascending = false,
  String separator = ' | ',
  DateTime? today,
}) {
  final now = today ?? DateTime.now();
  final buffer = StringBuffer()
    ..writeln('=== ЩОДЕННИК ТРЕНУВАНЬ: ЗВІТ ===')
    ..writeln('Коректних записів: ${items.length}')
    ..writeln();

  if (items.isEmpty) {
    buffer.writeln('Немає даних для звіту.');
    return buffer.toString();
  }

  // Хронологія: сортування за датою, при рівних датах — за тривалістю.
  buffer.writeln(
    '--- Хронологія (${ascending ? 'від старих' : 'від нових'}) ---',
  );
  final chronological = sortWorkouts(
    items,
    by: compareByDate,
    thenBy: compareByDuration,
    ascending: ascending,
  );
  for (final workout in chronological) {
    buffer.writeln(
      '${formatWorkout(workout, separator: separator)}'
      '$separator${ageInDays(workout, now)} дн. тому',
    );
  }
  buffer.writeln();

  // Топ за дистанцією, при рівній дистанції — новіші вище.
  buffer.writeln('--- Топ-$topCount за дистанцією ---');
  final top = sortWorkouts(
    items,
    by: compareByDistance,
    thenBy: compareByDate,
    ascending: false,
  ).take(topCount);
  for (final (index, workout) in top.indexed) {
    buffer.writeln(
      '${index + 1}. ${formatWorkout(workout, separator: separator)}',
    );
  }
  buffer.writeln();

  // Темп для тренувань із дистанцією.
  buffer.writeln('--- Темп (лише тренування з дистанцією) ---');
  for (final (:label, :paceSeconds) in paces(items)) {
    buffer.writeln(
      '${label.padRight(paceLabelColumnWidth)}$separator${formatPace(paceSeconds)}',
    );
  }
  buffer.writeln();

  // Групування за видом активності.
  buffer.writeln('--- За видами активності ---');
  final summary = summarizeGroups(groupByActivity(items));
  for (final MapEntry(key: activity, value: stats) in summary.entries) {
    buffer.writeln(
      [
        activity.padRight(activityColumnWidth),
        '${stats.count} трен.',
        formatDuration(stats.duration),
        '${stats.distanceKm.toStringAsFixed(fractionDigits)} км',
        'сер. пульс ${stats.avgHeartRate.toStringAsFixed(fractionDigits)}',
      ].join(separator),
    );
  }
  buffer.writeln();

  // Загальні агреговані значення.
  final longest = longestWorkout(items);
  final firstIntense = firstHighIntensity(items);
  final goodDays = items.where((w) => w.wellbeing >= goodWellbeing).length;
  final lastWorkout = sortWorkouts(items, by: compareByDate).last;

  buffer
    ..writeln('--- Підсумки ---')
    ..writeln(
      'Сумарна дистанція: '
      '${totalDistance(items).toStringAsFixed(fractionDigits)} км',
    )
    ..writeln('Сумарний час: ${formatDuration(totalDuration(items))}')
    ..writeln(
      'Середній пульс: '
      '${(averageHeartRate(items) ?? 0).toStringAsFixed(fractionDigits)} уд/хв',
    )
    ..writeln(
      'Найдовше тренування: '
      '${longest == null ? '—' : formatWorkout(longest, separator: separator)}',
    )
    ..writeln(
      'Перше інтенсивне (пульс ≥ $highIntensityHeartRate): '
      '${firstIntense == null ? 'немає' : formatDateShort(firstIntense.date)}',
    )
    ..writeln('Тренувань із самопочуттям ≥ $goodWellbeing: $goodDays')
    ..writeln('Днів від останнього тренування: ${ageInDays(lastWorkout, now)}');

  return buffer.toString();
}
