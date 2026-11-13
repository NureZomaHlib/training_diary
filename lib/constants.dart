/// Іменовані константи формату даних і допустимих діапазонів значень.
library;

/// Роздільник полів у вхідному рядку.
const String fieldSeparator = ';';

/// Кількість полів, яку має містити коректний рядок.
const int expectedFieldCount = 7;

/// Найраніший рік, який вважається допустимим для запису щоденника.
const int minYear = 2000;

/// Мінімальний правдоподібний середній пульс, уд./хв.
const int minHeartRate = 40;

/// Максимальний правдоподібний середній пульс, уд./хв.
const int maxHeartRate = 220;

/// Мінімальна оцінка самопочуття.
const int minWellbeing = 1;

/// Максимальна оцінка самопочуття.
const int maxWellbeing = 5;

/// Максимальна дистанція одного тренування, км.
const double maxDistanceKm = 300;

/// Максимальна тривалість одного тренування.
const Duration maxDuration = Duration(hours: 12);

/// Пульс, починаючи з якого тренування вважається інтенсивним, уд./хв.
const int highIntensityHeartRate = 160;
