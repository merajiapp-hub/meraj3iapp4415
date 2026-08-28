class UnitConverterEngine {
  /// Converts Length
  static double convertLength(double value, String from, String to) {
    const Map<String, double> ratesToMeters = {
      'mm': 0.001,
      'cm': 0.01,
      'm': 1.0,
      'km': 1000.0,
      'inch': 0.0254,
      'ft': 0.3048,
      'yard': 0.9144,
      'mile': 1609.34,
    };
    
    if (!ratesToMeters.containsKey(from) || !ratesToMeters.containsKey(to)) {
      throw Exception('الوحدة غير مدعومة');
    }

    double valueInMeters = value * ratesToMeters[from]!;
    return valueInMeters / ratesToMeters[to]!;
  }

  /// Converts Temperature
  static double convertTemperature(double value, String from, String to) {
    if (from == to) return value;
    
    double celsius = value;
    if (from == 'F') {
      celsius = (value - 32) * 5 / 9;
    } else if (from == 'K') {
      celsius = value - 273.15;
    }

    if (to == 'C') return celsius;
    if (to == 'F') return (celsius * 9 / 5) + 32;
    if (to == 'K') return celsius + 273.15;

    throw Exception('الوحدة غير مدعومة');
  }
}
