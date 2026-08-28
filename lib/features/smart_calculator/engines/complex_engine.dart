import 'package:complex/complex.dart';

class ComplexEngine {
  /// Parses a complex string like "3 + 4i" into a Complex object
  static Complex parse(String input) {
    try {
      // Basic parser for "a + bi" or "a - bi"
      String normalized = input.replaceAll(' ', '').replaceAll('i', '');
      if (normalized.contains('+')) {
        var parts = normalized.split('+');
        return Complex(double.parse(parts[0]), double.parse(parts[1]));
      } else if (normalized.contains('-')) {
        // Handle negative numbers carefully
        if (normalized.startsWith('-')) {
          var parts = normalized.substring(1).split('-');
          if (parts.length == 1) { // -a
             return Complex(-double.parse(parts[0]), 0);
          } else { // -a - bi
             return Complex(-double.parse(parts[0]), -double.parse(parts[1]));
          }
        } else { // a - bi
          var parts = normalized.split('-');
          return Complex(double.parse(parts[0]), -double.parse(parts[1]));
        }
      } else {
        // Pure real or pure imaginary (handled roughly for now)
        return Complex(double.parse(normalized), 0); 
      }
    } catch (e) {
      throw Exception('تنسيق العدد المركب غير صحيح. استخدم a + bi.');
    }
  }

  static Complex add(Complex a, Complex b) => a + b;
  static Complex subtract(Complex a, Complex b) => a - b;
  static Complex multiply(Complex a, Complex b) => a * b;
  static Complex divide(Complex a, Complex b) => a / b;

  static double absolute(Complex a) => a.abs();
  static double argument(Complex a) => a.argument();
  
  static String toPolar(Complex a) {
    return '${a.abs().toStringAsFixed(4)} (cos(${a.argument().toStringAsFixed(4)}) + i sin(${a.argument().toStringAsFixed(4)}))';
  }
}
