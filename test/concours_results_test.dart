import 'package:flutter_test/flutter_test.dart';
import 'package:meraj3i/services/results_service.dart';

void main() {
  test('concours uses TOTAL boundaries for status', () {
    expect(
      StudentResult.fromCsv({
        'NAME': 'A',
        'TOTAL': '84',
      }, ExamType.concours).status,
      'راسب',
    );
    expect(
      StudentResult.fromCsv({
        'NAME': 'B',
        'TOTAL': '85',
      }, ExamType.concours).status,
      'ناجح',
    );
    expect(
      StudentResult.fromCsv({
        'NAME': 'C',
        'TOTAL': '200',
      }, ExamType.concours).status,
      'ناجح',
    );
    expect(
      StudentResult.fromCsv({
        'NAME': 'D',
        'TOTAL': '200.5',
      }, ExamType.concours).status,
      'بيانات غير صالحة',
    );
  });

  test('concours does not mark an unreadable total as failed', () {
    final result = StudentResult.fromCsv({
      'NAME': 'E',
      'MOYENNE': '19',
      'RANK': '150',
    }, ExamType.concours);
    expect(result.score, isNull);
    expect(result.status, 'بيانات غير صالحة');
  });

  test('concours never substitutes average or rank for official total', () {
    final averageAndRank = StudentResult.fromCsv({
      'NAME': 'E4',
      'MOYENNE': '19',
      'RANK': '150',
    }, ExamType.concours);
    final rankOnly = StudentResult.fromCsv({
      'NAME': 'E5',
      'RANK': '150',
    }, ExamType.concours);

    expect(averageAndRank.score, isNull);
    expect(averageAndRank.status, 'بيانات غير صالحة');
    expect(rankOnly.score, isNull);
    expect(rankOnly.status, 'بيانات غير صالحة');
  });

  test('concours preserves an official admitted decision', () {
    final result = StudentResult.fromCsv({
      'NAME': 'E2',
      'TOTAL_GENERAL': '',
      'DECISION': 'Admis',
    }, ExamType.concours);
    expect(result.status, 'ناجح');
  });

  test('concours does not confuse a non-admitted decision with admitted', () {
    final result = StudentResult.fromCsv({
      'NAME': 'E3',
      'TOTAL_GENERAL': '',
      'DECISION': 'Non-admis',
    }, ExamType.concours);
    expect(result.status, 'راسب');
  });

  test('concours reads general total columns', () {
    final result = StudentResult.fromCsv({
      'NAME': 'E4',
      'TOTAL GENERAL': '165',
    }, ExamType.concours);
    expect(result.score, 165);
    expect(result.status, 'ناجح');
  });

  test('concours parses decimal and string TOTAL values', () {
    expect(
      StudentResult.fromCsv({
        'NAME': 'F',
        'TOTAL': '85,5',
      }, ExamType.concours).score,
      85.5,
    );
    expect(
      StudentResult.fromCsv({
        'NAME': 'G',
        'TOTAL': '',
      }, ExamType.concours).score,
      isNull,
    );
  });

  test('concours ignores stale status and derives it from TOTAL', () {
    final result = StudentResult.fromCsv({
      'NAME': 'G',
      'TOTAL': '100',
      'STATUS': 'راسب',
    }, ExamType.concours);
    expect(result.status, 'ناجح');
  });

  test('missing school-exam score is not classified as failed', () {
    final bac = StudentResult.fromCsv({
      'NAME': 'Student',
      'MOYENNE': '',
    }, ExamType.bac);
    final brevet = StudentResult.fromCsv({
      'NAME': 'Student',
      'MOYG': '',
    }, ExamType.brevet);

    expect(bac.score, isNull);
    expect(bac.isInvalid, isTrue);
    expect(bac.isFailed, isFalse);
    expect(brevet.score, isNull);
    expect(brevet.isInvalid, isTrue);
    expect(brevet.isFailed, isFalse);
  });

  test('cleans hash marks from registration number and imported rank', () {
    final result = StudentResult.fromCsv({
      'NAME': 'Student',
      'NUMERO': '#00123',
      'RANG': '#7',
      'TOTAL': '120',
    }, ExamType.concours);

    expect(result.id, '00123');
    expect(result.rank, '7');
  });

  test('concours filter omits invalid data but retains actual statuses', () {
    final results = [
      StudentResult.fromCsv({
        'NAME': 'Pass',
        'TOTAL': '100',
      }, ExamType.concours),
      StudentResult.fromCsv({'NAME': 'Fail', 'TOTAL': '84'}, ExamType.concours),
      StudentResult.fromCsv({
        'NAME': 'Invalid',
        'TOTAL': '',
      }, ExamType.concours),
    ];

    final filters = ResultsService.statusFilterOptions(
      ExamType.concours,
      results,
    );

    expect(filters, contains('ناجح'));
    expect(filters, contains('راسب'));
    expect(filters, isNot(contains('بيانات غير صالحة')));
  });

  test(
    'expelled filter is available for bac and brevet without current cases',
    () {
      for (final type in [ExamType.bac, ExamType.brevet]) {
        expect(
          ResultsService.statusFilterOptions(type, const []),
          contains('مطرود'),
        );
      }
    },
  );

  test('score range validation only uses /20 for non-concours exams', () {
    final concours = StudentResult.fromCsv({
      'NAME': 'Concours pass',
      'TOTAL': '120',
    }, ExamType.concours);
    final bac = StudentResult.fromCsv({
      'NAME': 'Invalid bac score',
      'MOYENNE': '21',
    }, ExamType.bac);

    expect(concours.isPassed, isTrue);
    expect(bac.isInvalid, isTrue);
  });

  test(
    'bac first-session pass rate treats complementary candidates as pending',
    () {
      expect(
        ResultsService.passRate(
          passed: 8188,
          failed: 199,
          complementary: 52188,
        ),
        closeTo(13.52, 0.01),
      );
      expect(
        ResultsService.passRate(passed: 8188, failed: 199),
        closeTo(97.62, 0.01),
      );
    },
  );

  test('bac complementary admission is not counted as a passed result', () {
    final result = StudentResult.fromCsv({
      'NAME': 'Complementary candidate',
      'MOY_BAC': '9.5',
      'DECISION': 'Admis à la session complémentaire',
    }, ExamType.bac);

    expect(result.isComplementary, isTrue);
    expect(result.isPassed, isFalse);
    expect(result.isFailed, isFalse);
  });
}
