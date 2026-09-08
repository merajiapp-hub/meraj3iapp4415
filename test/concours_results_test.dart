import 'package:flutter_test/flutter_test.dart';
import 'package:meraj3i/services/results_service.dart';

void main() {
  test('concours uses TOTAL boundaries for status', () {
    expect(StudentResult.fromCsv({'NAME': 'A', 'TOTAL': '84'}, ExamType.concours).status, 'راسب');
    expect(StudentResult.fromCsv({'NAME': 'B', 'TOTAL': '85'}, ExamType.concours).status, 'ناجح');
    expect(StudentResult.fromCsv({'NAME': 'C', 'TOTAL': '200'}, ExamType.concours).status, 'ناجح');
    expect(StudentResult.fromCsv({'NAME': 'D', 'TOTAL': '200.5'}, ExamType.concours).status, 'بيانات غير صالحة');
  });

  test('concours does not use another numeric field when TOTAL is missing', () {
    final result = StudentResult.fromCsv({'NAME': 'E', 'MOYENNE': '19', 'RANK': '150'}, ExamType.concours);
    expect(result.score, isNull);
    expect(result.status, 'راسب');
  });

  test('concours parses decimal and string TOTAL values', () {
    expect(StudentResult.fromCsv({'NAME': 'F', 'TOTAL': '85,5'}, ExamType.concours).score, 85.5);
    expect(StudentResult.fromCsv({'NAME': 'G', 'TOTAL': ''}, ExamType.concours).score, isNull);
  });
}
