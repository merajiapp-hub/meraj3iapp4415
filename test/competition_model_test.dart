import 'package:flutter_test/flutter_test.dart';
import 'package:meraj3i/models/competition_model.dart';

void main() {
  test('parses Firestore competition fields with numeric/string order', () {
    final numeric = CompetitionModel.fromJson('bac_2026', {
      'title': 'Bac 2026',
      'link': 'https://example.com/bac.csv',
      'is_published': true,
      'order': 4,
    });
    final stringOrder = CompetitionModel.fromJson('brevet_2026', {
      'title': 'Brevet 2026',
      'link': 'https://example.com/brevet.csv',
      'is_published': 'true',
      'order': '2',
    });
    final disabledCamelCase = CompetitionModel.fromJson('concours_2026', {
      'title': 'Concours 2026',
      'link': 'https://example.com/concours.csv',
      'isPublished': false,
    });

    expect(numeric.order, 4);
    expect(stringOrder.order, 2);
    expect(stringOrder.isPublished, isTrue);
    expect(numeric.link, startsWith('https://'));
    expect(disabledCamelCase.isPublished, isFalse);
  });

  test('infers competition type from title when document ID is generic', () {
    final concours = CompetitionModel.fromJson('results_2026', {
      'type': 'competition',
      'title': 'نتائج مسابقة كونكور 2026',
      'link': 'https://example.com/concours.csv',
      'is_published': true,
    });

    expect(concours.type, CompetitionType.concours);
  });

  test('complementary Bac is detected before the general Bac marker', () {
    final complementary = CompetitionModel.fromJson('exam_2026', {
      'type': 'exam',
      'title': 'نتائج الباكلوريا - الدورة التكميلية',
      'link': 'https://example.com/bac-complementary.csv',
      'is_published': true,
    });

    expect(complementary.type, CompetitionType.complementary);
  });
}
