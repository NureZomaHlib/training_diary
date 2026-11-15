import 'package:test/test.dart';
import 'package:training_diary/training_diary.dart';

void main() {
  final today = DateTime(2026, 11, 15);

  Workout sample({
    DateTime? date,
    String activity = 'біг',
    Duration duration = const Duration(minutes: 40),
    double distanceKm = 8,
    int heartRate = 150,
    int wellbeing = 4,
  }) => (
    date: date ?? DateTime(2026, 11, 1),
    activity: activity,
    duration: duration,
    distanceKm: distanceKm,
    heartRate: heartRate,
    wellbeing: wellbeing,
    deviceId: 'GRM-4821-7731',
  );

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

    test('повідомляє про невірний ідентифікатор трекера', () {
      final result = parseLine('2026-11-05;плавання;0:55;2.0;133;4;xmi-1');
      expect(result.error, contains('трекера'));
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

  group('validateWorkout', () {
    test('коректний запис не має порушень', () {
      expect(validateWorkout(sample(), today: today), isEmpty);
    });

    test('виявляє кілька порушень одночасно', () {
      final issues = validateWorkout(
        sample(heartRate: 250, wellbeing: 7, distanceKm: -1),
        today: today,
      );
      expect(issues, hasLength(3));
    });

    test('виявляє дату в майбутньому', () {
      final issues = validateWorkout(
        sample(date: DateTime(2027)),
        today: today,
      );
      expect(issues.single, contains('майбутньому'));
    });
  });

  group('аналітика', () {
    final items = [
      sample(distanceKm: 5, heartRate: 140),
      sample(activity: 'йога', distanceKm: 0, heartRate: 90),
      sample(
        distanceKm: 10,
        heartRate: 170,
        duration: const Duration(hours: 1),
      ),
    ];

    test('згортання', () {
      expect(totalDistance(items), 15);
      expect(averageHeartRate(items), 400 / 3);
      expect(averageHeartRate([]), isNull);
      expect(longestWorkout(items)?.distanceKm, 10);
      expect(longestWorkout([]), isNull);
    });

    test('firstHighIntensity', () {
      expect(firstHighIntensity(items)?.heartRate, 170);
      expect(firstHighIntensity(items.take(2)), isNull);
    });

    test('групування', () {
      final groups = groupByActivity(items);
      expect(groups.keys, unorderedEquals(['біг', 'йога']));
      expect(groups['біг'], hasLength(2));
    });

    test('сортування не змінює вихідний список і враховує напрям', () {
      final desc = sortWorkouts(items, by: compareByDistance, ascending: false);
      expect(desc.map((w) => w.distanceKm), [10, 5, 0]);
      expect(items.first.distanceKm, 5);
    });

    test('фабрики предикатів', () {
      expect(items.where(byActivity('йога')), hasLength(1));
      expect(items.where(minDistance(5)), hasLength(2));
    });

    test('темп і вік запису', () {
      expect(paceSecondsPerKm(items[0]), 480);
      expect(paceSecondsPerKm(items[1]), isNull);
      expect(ageInDays(items[0], today), 14);
    });
  });

  test('maskDeviceIds приховує серійну частину', () {
    expect(
      maskDeviceIds('трекер GRM-4821-7731 і XMI-1034-5520'),
      'трекер GRM-****-7731 і XMI-****-5520',
    );
  });
}
