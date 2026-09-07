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

    expect(numeric.order, 4);
    expect(stringOrder.order, 2);
    expect(stringOrder.isPublished, isTrue);
    expect(numeric.link, startsWith('https://'));
  });
}