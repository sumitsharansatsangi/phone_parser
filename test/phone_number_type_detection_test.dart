import 'dart:convert';

import 'package:phone_parser/phone_parser.dart';
import 'package:phone_parser/src/metadata/bundled_metadata.g.dart';
import 'package:test/test.dart';

void main() {
  setUpAll(() {
    MetadataFinder.info = jsonDecode(bundledMetadataJson) as Map<String, dynamic>;
  });

  group('PhoneNumber.getNumberType', () {
    test('detects a fixed line or mobile number when the metadata overlaps', () {
      const phone = PhoneNumber(isoCode: 'US', nsn: '2015550123');

      expect(phone.getNumberType(), PhoneNumberType.fixedLineOrMobile);
    });

    test('detects a mobile number', () {
      const phone = PhoneNumber(isoCode: 'ZA', nsn: '711234567');

      expect(phone.getNumberType(), PhoneNumberType.mobile);
    });

    test('detects a toll free number', () {
      const phone = PhoneNumber(isoCode: 'ZA', nsn: '801234567');

      expect(phone.getNumberType(), PhoneNumberType.tollFree);
    });

    test('returns unknown for an invalid number', () {
      const phone = PhoneNumber(isoCode: 'ZA', nsn: '123');

      expect(phone.getNumberType(), PhoneNumberType.unknown);
    });
  });
}
