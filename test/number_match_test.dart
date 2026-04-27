import 'dart:convert';

import 'package:phone_parser/phone_parser.dart';
import 'package:phone_parser/src/metadata/bundled_metadata.g.dart';
import 'package:test/test.dart';

void main() {
  setUpAll(() {
    MetadataFinder.info = jsonDecode(bundledMetadataJson) as Map<String, dynamic>;
  });

  group('PhoneNumber.isNumberMatch', () {
    test('returns exactMatch for identical fully qualified numbers', () {
      final first = PhoneNumber.parse('+33 655 5705 76');
      final second = PhoneNumber.parse('+33 655 5705 76');

      expect(PhoneNumber.isNumberMatch(first, second), MatchType.exactMatch);
    });

    test('returns nsnMatch when a local string matches a phone number via inferred region', () {
      final international = PhoneNumber.parse('+33 655 5705 76');

      expect(
        PhoneNumber.isNumberMatch('06 55 57 05 76', international),
        MatchType.nsnMatch,
      );
    });

    test('returns shortNsnMatch when one national number is a suffix of the other', () {
      const full = PhoneNumber(isoCode: 'US', nsn: '3456571234');
      const short = PhoneNumber(isoCode: 'US', nsn: '6571234');

      expect(PhoneNumber.isNumberMatch(full, short), MatchType.shortNsnMatch);
    });

    test('returns noMatch for different numbers', () {
      final first = PhoneNumber.parse('+33 655 5705 76');
      final second = PhoneNumber.parse('+33 655 5705 99');

      expect(PhoneNumber.isNumberMatch(first, second), MatchType.noMatch);
    });

    test('returns notANumber for unsupported local string comparisons without region context', () {
      expect(
        PhoneNumber.isNumberMatch('06 55 57 05 76', '06 55 57 05 76'),
        MatchType.notANumber,
      );
    });
  });
}
