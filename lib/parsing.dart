/// Розбір вхідних рядків у записи тренувань.
library;

import 'constants.dart';
import 'workout.dart';

/// Шаблон дати `yyyy-MM-dd` з іменованими групами року, місяця та дня.
final RegExp _datePattern = RegExp(
  r'^(?<year>\d{4})-(?<month>\d{2})-(?<day>\d{2})$',
);

/// Шаблон тривалості `г:хх` з іменованими групами годин і хвилин.
final RegExp _durationPattern = RegExp(
  r'^(?<hours>\d{1,2}):(?<minutes>[0-5]\d)$',
);

/// Розбирає рядок [raw] у дату формату `yyyy-MM-dd`.
///
/// Повертає `null`, якщо рядок не відповідає формату або описує неіснуючу
/// дату. `DateTime.tryParse` сам по собі не відкидає дати на кшталт
/// `2026-02-30` — він нормалізує їх до `2026-03-02`, — тому після розбору
/// місяць і день порівнюються з тими, що були записані у рядку.
DateTime? parseDate(String raw) {
  final match = _datePattern.firstMatch(raw);
  if (match == null) return null;

  final date = DateTime.tryParse(raw);
  if (date == null) return null;

  final month = int.tryParse(match.namedGroup('month') ?? '');
  final day = int.tryParse(match.namedGroup('day') ?? '');
  final isNormalized = date.month != month || date.day != day;
  return isNormalized ? null : date;
}

/// Розбирає рядок [raw] формату `г:хх` у тривалість.
///
/// Повертає `null`, якщо рядок не відповідає формату.
Duration? parseDuration(String raw) {
  final match = _durationPattern.firstMatch(raw);
  if (match == null) return null;

  final hours = int.tryParse(match.namedGroup('hours') ?? '');
  final minutes = int.tryParse(match.namedGroup('minutes') ?? '');
  if (hours == null || minutes == null) return null;

  return Duration(hours: hours, minutes: minutes);
}

/// Розбирає рядок [line] у запис тренування.
///
/// Ніколи не кидає винятків: у разі будь-якої невідповідності формату
/// повертає результат із заповненим полем `error`.
ParseResult parseLine(String line) {
  final parts = line.split(fieldSeparator).map((part) => part.trim()).toList();

  if (parts case [
    final rawDate,
    final activity,
    final rawDuration,
    final rawDistance,
    final rawHeartRate,
    final rawWellbeing,
    final deviceId,
  ]) {
    final date = parseDate(rawDate);
    if (date == null) return _failure('некоректна дата «$rawDate»');

    if (activity.isEmpty) return _failure('не вказано вид активності');

    final duration = parseDuration(rawDuration);
    if (duration == null) {
      return _failure('тривалість «$rawDuration» не у форматі г:хх');
    }

    final distanceKm = double.tryParse(rawDistance);
    if (distanceKm == null) {
      return _failure('дистанція «$rawDistance» не є числом');
    }

    final heartRate = int.tryParse(rawHeartRate);
    if (heartRate == null) {
      return _failure('пульс «$rawHeartRate» не є цілим числом');
    }

    final wellbeing = int.tryParse(rawWellbeing);
    if (wellbeing == null) {
      return _failure('самопочуття «$rawWellbeing» не є цілим числом');
    }

    return (
      value: (
        date: date,
        activity: activity,
        duration: duration,
        distanceKm: distanceKm,
        heartRate: heartRate,
        wellbeing: wellbeing,
        deviceId: deviceId,
      ),
      error: null,
    );
  }

  return _failure(
    'очікувалося $expectedFieldCount полів, отримано ${parts.length}',
  );
}

/// Створює невдалий результат розбору з описом [error].
ParseResult _failure(String error) => (value: null, error: error);

/// Створює лічильник, який при кожному виклику повертає наступне число,
/// починаючи з 1.
///
/// Повернена функція є замиканням: вона захоплює локальну змінну `count`,
/// яка живе доти, доки існує сама функція-лічильник.
int Function() makeCounter() {
  var count = 0;
  return () => ++count;
}

/// Розбирає всі рядки [lines].
///
/// Повертає розібрані тренування та перелік помилок із номерами рядків
/// (нумерація з 1).
({List<Workout> workouts, List<String> errors}) parseAll(List<String> lines) {
  final nextLineNumber = makeCounter();
  final results = lines
      .map((line) => (number: nextLineNumber(), result: parseLine(line)))
      .toList();

  final workouts = results.map((entry) => entry.result.value).nonNulls.toList();
  final errors = results
      .map((entry) {
        final error = entry.result.error;
        return error == null ? null : 'рядок ${entry.number}: $error';
      })
      .nonNulls
      .toList();

  return (workouts: workouts, errors: errors);
}
