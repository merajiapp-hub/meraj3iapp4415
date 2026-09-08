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
}
