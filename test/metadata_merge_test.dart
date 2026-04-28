import 'package:phone_parser/src/download_file/download_file.dart';
import 'package:test/test.dart';

void main() {
  group('deepMergeMetadataMaps', () {
    test('fills empty format lists from the incoming source', () {
      final google = <String, dynamic>{
        'isoCode': 'AG',
        'formats': <dynamic>[],
        'examples': <String, dynamic>{'fixedLine': '2684601234'},
      };
      final apple = <String, dynamic>{
        'isoCode': 'AG',
        'formats': <dynamic>[
          <String, dynamic>{
            'pattern': r'(\d{3})(\d{3})(\d{4})',
            'format': r'$1-$2-$3',
          },
        ],
        'examples': <String, dynamic>{'fixedLine': '2684601234'},
      };

      final merged = deepMergeMetadataMaps(google, apple);

      expect((merged['formats'] as List), isNotEmpty);
      expect((merged['formats'] as List).single['format'], r'$1-$2-$3');
    });

    test('keeps existing non-empty Google format lists', () {
      final google = <String, dynamic>{
        'isoCode': 'US',
        'formats': <dynamic>[
          <String, dynamic>{'pattern': r'(\d{3})(\d{3})(\d{4})'},
        ],
      };
      final apple = <String, dynamic>{
        'isoCode': 'US',
        'formats': <dynamic>[
          <String, dynamic>{'pattern': r'(\d{2})(\d{4})(\d{4})'},
        ],
      };

      final merged = deepMergeMetadataMaps(google, apple);

      expect((merged['formats'] as List).single['pattern'],
          r'(\d{3})(\d{3})(\d{4})');
    });

    test('fills empty strings from the incoming source', () {
      final google = <String, dynamic>{'leadingDigits': ''};
      final apple = <String, dynamic>{'leadingDigits': '268'};

      final merged = deepMergeMetadataMaps(google, apple);

      expect(merged['leadingDigits'], '268');
    });
  });
}
