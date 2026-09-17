import 'package:flutter_test/flutter_test.dart';
import 'package:meraj3i/services/results_service.dart';

void main() {
  test('concours uses TOTAL boundaries for status', () {
    expect(StudentResult.fromCsv({'NAME': 'A', 'TOTAL': '84'}, ExamType.concours).status, 'راسب');
    expect(StudentResult.fromCsv({'NAME': 'B', 'TOTAL': '85'}, ExamType.concours).status, 'ناجح');
    expect(StudentResult.fromCsv({'NAME': 'C', 'TOTAL': '200'}, ExamType.concours).status, 'ناجح');
    expect(StudentResult.fromCsv({'NAME': 'D', 'TOTAL': '200.5'}, ExamType.concours).status, 'بيانات غير صالحة');
  });

  test('concours does not mark an unreadable total as failed', () {
    final result = StudentResult.fromCsv({'NAME': 'E', 'MOYENNE': '19', 'RANK': '150'}, ExamType.concours);
    expect(result.score, isNull);
    expect(result.status, 'بيانات غير صالحة');
  });

  test('concours preserves an official admitted decision', () {
    final result = StudentResult.fromCsv({
      'NAME': 'E2',
      'TOTAL_GENERAL': '',
      'DECISION': 'Admis',
    }, ExamType.concours);
    expect(result.status, 'ناجح');
  });

  test('concours reads general total columns', () {
    final result = StudentResult.fromCsv({
      'NAME': 'E3',
      'TOTAL GENERAL': '165',
    }, ExamType.concours);
    expect(result.score, 165);
    expect(result.status, 'ناجح');
  });

  test('concours parses decimal and string TOTAL values', () {
    expect(StudentResult.fromCsv({'NAME': 'F', 'TOTAL': '85,5'}, ExamType.concours).score, 85.5);
    expect(StudentResult.fromCsv({'NAME': 'G', 'TOTAL': ''}, ExamType.concours).score, isNull);
  });

  test('concours ignores stale status and derives it from TOTAL', () {
    final result = StudentResult.fromCsv({
      'NAME': 'G',
      'TOTAL': '100',
      'STATUS': 'راسب',
    }, ExamType.concours);
    expect(result.status, 'ناجح');
  });
}
