import 'package:flutter_test/flutter_test.dart';
import 'package:maktaba_ihsan/core/utils/bengali_text_utils.dart';

void main() {
  group('BengaliTextUtils Tests', () {
    test('isSameSubject recognizes kar differences as same subject', () {
      expect(BengaliTextUtils.isSameSubject('তাফসীর', 'তাফসির'), isTrue);
      expect(BengaliTextUtils.isSameSubject('হাদিস', 'হাদীস'), isTrue);
      expect(BengaliTextUtils.isSameSubject('ফিকহ', 'ফিকাহ'), isTrue);
      expect(BengaliTextUtils.isSameSubject('উসুলুল ফিকহ', 'উসূলুল ফিকহ'), isTrue);
      expect(BengaliTextUtils.isSameSubject('আকীদা', 'আকিদা'), isTrue);
      expect(BengaliTextUtils.isSameSubject('সীরাত', 'সিরাত'), isTrue);
      expect(BengaliTextUtils.isSameSubject('জীবনী', 'জিবনী'), isTrue);
      expect(BengaliTextUtils.isSameSubject('আরবী সাহিত্য', 'আরবি সাহিত্য'), isTrue);
    });

    test('isSameSubject distinguishes different subjects', () {
      expect(BengaliTextUtils.isSameSubject('হাদিস', 'তাফসির'), isFalse);
      expect(BengaliTextUtils.isSameSubject('ফিকহ', 'ইতিহাস'), isFalse);
    });

    test('aggregateCategoryCounts groups variants and sums counts', () {
      final raw = {
        'তাফসির': 162,
        'তাফসীর': 25,
        'হাদিস': 650,
        'হাদীস': 10,
        'ফিকহ': 450,
      };

      final aggregated = BengaliTextUtils.aggregateCategoryCounts(raw);

      expect(aggregated['তাফসির'], equals(187));
      expect(aggregated.containsKey('তাফসীর'), isFalse);
      expect(aggregated['হাদিস'], equals(660));
      expect(aggregated.containsKey('হাদীস'), isFalse);
      expect(aggregated['ফিকহ'], equals(450));
    });
  });
}
