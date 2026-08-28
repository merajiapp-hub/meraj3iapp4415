import 'package:ml_linalg/matrix.dart';

class MatrixEngine {
  /// Adds two matrices
  static Matrix add(Matrix a, Matrix b) {
    if (a.rowCount != b.rowCount || a.columnCount != b.columnCount) {
      throw Exception('لجمع المصفوفات يجب أن تكون متساوية الأبعاد.');
    }
    return a + b;
  }

  /// Subtracts matrix b from matrix a
  static Matrix subtract(Matrix a, Matrix b) {
     if (a.rowCount != b.rowCount || a.columnCount != b.columnCount) {
      throw Exception('لطرح المصفوفات يجب أن تكون متساوية الأبعاد.');
    }
    return a - b;
  }

  /// Multiplies two matrices
  static Matrix multiply(Matrix a, Matrix b) {
    if (a.columnCount != b.rowCount) {
      throw Exception('عدد أعمدة المصفوفة الأولى يجب أن يساوي عدد صفوف المصفوفة الثانية.');
    }
    return a * b;
  }

  /// Multiplies matrix by a scalar
  static Matrix scalarMultiply(Matrix a, double scalar) {
    return a * scalar;
  }

  /// Transposes a matrix
  static Matrix transpose(Matrix a) {
    return a.transpose();
  }

  /// Calculates the determinant of a square matrix
  static double determinant(Matrix a) {
    if (a.rowCount != a.columnCount) {
      throw Exception('لا يمكن حساب المحدد إلا لمصفوفة مربعة.');
    }
    // Using ml_linalg doesn't have a direct determinant method, but we can implement a basic one or use another package.
    // For now, implement 2x2 and 3x3 manually, or use LU decomposition if available.
    if (a.rowCount == 2) {
      return a[0][0] * a[1][1] - a[0][1] * a[1][0];
    } else if (a.rowCount == 3) {
      return a[0][0] * (a[1][1] * a[2][2] - a[1][2] * a[2][1]) -
             a[0][1] * (a[1][0] * a[2][2] - a[1][2] * a[2][0]) +
             a[0][2] * (a[1][0] * a[2][1] - a[1][1] * a[2][0]);
    }
    // General case: recursive cofactor expansion along the first row
    return _determinantRecursive(a);
  }

  /// Recursive cofactor (Laplace) expansion for n×n matrices.
  static double _determinantRecursive(Matrix m) {
    final n = m.rowCount;
    if (n == 1) return m[0][0].toDouble();
    if (n == 2) return (m[0][0] * m[1][1] - m[0][1] * m[1][0]).toDouble();

    double det = 0;
    for (int col = 0; col < n; col++) {
      final subData = <List<double>>[];
      for (int r = 1; r < n; r++) {
        final row = <double>[];
        for (int c = 0; c < n; c++) {
          if (c != col) row.add(m[r][c].toDouble());
        }
        subData.add(row);
      }
      final sub = Matrix.fromList(subData);
      final sign = (col % 2 == 0) ? 1.0 : -1.0;
      det += sign * m[0][col] * _determinantRecursive(sub);
    }
    return det;
  }

  /// Calculates the inverse of a square matrix
  static Matrix inverse(Matrix a) {
     if (a.rowCount != a.columnCount) {
      throw Exception('لا يمكن حساب المعكوس إلا لمصفوفة مربعة.');
    }
    // ml_linalg Matrix has inverse method:
    try {
      return a.inverse();
    } catch (e) {
      throw Exception('هذه المصفوفة ليس لها معكوس (المحدد = 0).');
    }
  }
}
