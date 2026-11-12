import 'package:test/test.dart';
import 'package:training_diary/training_diary.dart';

void main() {
  group('parseDate', () {
    test('розбирає коректну дату', () {
      expect(parseDate('2026-10-05'), DateTime(2026, 10, 5));
    });

    test('відкидає дати, які DateTime.tryParse нормалізує', () {
      expect(parseDate('2026-02-30'), isNull);
      expect(parseDate('2026-13-01'), isNull);
    });

    test('відкидає неправильний формат', () {
      expect(parseDate('2026-1-5'), isNull);
      expect(parseDate('вчора'), isNull);
    });
  });

  group('parseDuration', () {
    test('розбирає г:хх', () {
      expect(parseDuration('1:35'), const Duration(hours: 1, minutes: 35));
    });

    test('відкидає інші формати', () {
      expect(parseDuration('45хв'), isNull);
      expect(parseDuration('1:75'), isNull);
    });
  });

  group('parseLine', () {
    test('розбирає коректний рядок', () {
      final result = parseLine('2026-09-02;біг;0:42;7.1;152;4;GRM-4821-7731');
      expect(result.error, isNull);
      expect(result.value?.distanceKm, 7.1);
      expect(result.value?.duration, const Duration(minutes: 42));
    });

    test('повідомляє про відсутнє поле', () {
      final result = parseLine('2026-09-24;біг;0:38;6.5;149;GRM-4821-7731');
      expect(result.value, isNull);
      expect(result.error, contains('очікувалося 7 полів'));
    });

    test('повідомляє про нечислове значення', () {
      final result = parseLine(
        '2026-10-01;велосипед;1:15;двадцять;133;4;GRM-4821-7731',
      );
      expect(result.error, contains('дистанція'));
    });
  });

  test('parseAll нумерує рядки з помилками з одиниці', () {
    final (:workouts, :errors) = parseAll([
      '2026-09-02;біг;0:42;7.1;152;4;GRM-4821-7731',
      'зламаний рядок',
    ]);
    expect(workouts, hasLength(1));
    expect(errors.single, startsWith('рядок 2:'));
  });

  test('makeCounter створює незалежні лічильники', () {
    final a = makeCounter();
    final b = makeCounter();
    expect([a(), a(), b(), a()], [1, 2, 1, 3]);
  });
}
