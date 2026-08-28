import 'dart:math';

class StatisticsEngine {
  /// Calculates the mean of a dataset
  static double mean(List<double> data) {
    if (data.isEmpty) return 0;
    double sum = data.reduce((a, b) => a + b);
    return sum / data.length;
  }

  /// Calculates the median of a dataset
  static double median(List<double> data) {
    if (data.isEmpty) return 0;
    List<double> sorted = List.from(data)..sort();
    int middle = sorted.length ~/ 2;
    if (sorted.length % 2 == 1) {
      return sorted[middle];
    } else {
      return (sorted[middle - 1] + sorted[middle]) / 2.0;
    }
  }

  /// Calculates the mode(s) of a dataset
  static List<double> mode(List<double> data) {
    if (data.isEmpty) return [];
    Map<double, int> counts = {};
    for (var val in data) {
      counts[val] = (counts[val] ?? 0) + 1;
    }
    int maxCount = counts.values.reduce(max);
    return counts.entries.where((e) => e.value == maxCount).map((e) => e.key).toList();
  }

  /// Calculates the variance of a dataset (sample variance by default)
  static double variance(List<double> data, {bool isPopulation = false}) {
    if (data.length <= 1) return 0;
    double m = mean(data);
    double sumSquares = data.map((val) => pow(val - m, 2)).reduce((a, b) => a + b).toDouble();
    return sumSquares / (data.length - (isPopulation ? 0 : 1));
  }

  /// Calculates the standard deviation of a dataset
  static double standardDeviation(List<double> data, {bool isPopulation = false}) {
    return sqrt(variance(data, isPopulation: isPopulation));
  }
}
