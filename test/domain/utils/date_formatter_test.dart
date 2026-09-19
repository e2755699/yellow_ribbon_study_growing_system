import 'package:flutter_test/flutter_test.dart';
import 'package:yellow_ribbon_study_growing_system/domain/utils/date_formatter.dart';

void main() {
  test('attendance document IDs round-trip leap-day dates and class names', () {
    final date = DateTime(2024, 2, 29, 18, 30);
    final id = DateFormatter.formatToDocId(date, 'tainanNorthDistrict');
    expect(id, '2024-02-29_tainanNorthDistrict');
    expect(DateFormatter.extractDateFromDocId(id), DateTime(2024, 2, 29));
  });

  test('unparseable document IDs return null', () {
    expect(DateFormatter.extractDateFromDocId('invalid_class'), isNull);
    expect(DateFormatter.extractDateFromDocId(''), isNull);
  });
}
