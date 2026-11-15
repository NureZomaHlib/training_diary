/// Типи даних щоденника тренувань.
///
/// У лабораторній роботі 1 класи навмисно не використовуються, тому
/// тренування представлено записом (record) з іменованими полями.
library;

/// Одне тренування зі щоденника.
///
/// Поля: дата, вид активності, тривалість, дистанція в кілометрах,
/// середній пульс (уд./хв), самопочуття за шкалою 1–5 та ідентифікатор
/// фітнес-трекера, яким записано тренування.
typedef Workout = ({
  DateTime date,
  String activity,
  Duration duration,
  double distanceKm,
  int heartRate,
  int wellbeing,
  String deviceId,
});

/// Результат розбору одного рядка.
///
/// Рівно одне з полів має значення: [value] — розібране тренування,
/// або [error] — опис причини, з якої рядок не вдалося розібрати.
typedef ParseResult = ({Workout? value, String? error});

/// Порівнювач двох тренувань для сортування.
typedef WorkoutComparator = int Function(Workout a, Workout b);

/// Предикат для фільтрації тренувань.
typedef WorkoutPredicate = bool Function(Workout workout);
