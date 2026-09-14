import 'package:flutter_test/flutter_test.dart';
import 'package:meraj3i/services/results_service.dart';

void main() {
  Map<String, String> row(String total) => {
        'NOM': 'Student',
        'TOTAL': total,
      };

  test('concours passes totals from 85 through 200', () {
    expect(StudentResult.fromCsv(row('84/200'), ExamType.concours).status, 'راسب');
    expect(StudentResult.fromCsv(row('85/200'), ExamType.concours).status, 'ناجح');
    expect(StudentResult.fromCsv(row('200'), ExamType.concours).status, 'ناجح');
    expect(StudentResult.fromCsv(row('201'), ExamType.concours).status, 'بيانات غير صالحة');
  });

  test('concours classification handles numeric input types and ignores stale status', () {
    expect(StudentResult.concoursStatusFromTotal('85'), 'ناجح');
    expect(StudentResult.concoursStatusFromTotal(200), 'ناجح');
    expect(StudentResult.concoursStatusFromTotal(84), 'راسب');
    expect(StudentResult.concoursStatusFromTotal(0.0), 'راسب');
    expect(StudentResult.concoursStatusFromTotal('85,5'), 'ناجح');
  });
}
