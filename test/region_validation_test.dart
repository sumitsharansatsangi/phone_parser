import 'dart:convert';

import 'package:phone_parser/phone_parser.dart';
import 'package:phone_parser/src/metadata/bundled_metadata.g.dart';
import 'package:test/test.dart';

void main() {
  setUpAll(() {
    MetadataFinder.info = jsonDecode(bundledMetadataJson) as Map<String, dynamic>;
  });

  group('PhoneNumber.isValidForRegion', () {
    test('returns true for the number home region', () {
      const phone = PhoneNumber(isoCode: 'AG', nsn: '2684601234');

      expect(phone.isValidForRegion('AG'), isTrue);
    });

    test('returns false for a region with a different pattern on the same country code', () {
      const phone = PhoneNumber(isoCode: 'AG', nsn: '2684601234');

      expect(phone.isValidForRegion('US'), isFalse);
    });

    test('returns false for a region with a different country calling code', () {
      const phone = PhoneNumber(isoCode: 'FR', nsn: '655570576');

      expect(phone.isValidForRegion('US'), isFalse);
    });

    test('returns false for an invalid region code', () {
      const phone = PhoneNumber(isoCode: 'FR', nsn: '655570576');

      expect(phone.isValidForRegion('ZZZ'), isFalse);
    });
  });
}
