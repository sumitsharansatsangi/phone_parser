import 'dart:convert';

import 'package:phone_parser/phone_parser.dart';
import 'package:phone_parser/src/metadata/bundled_metadata.g.dart';
import 'package:test/test.dart';

void main() {
  setUpAll(() {
    MetadataFinder.info =
        jsonDecode(bundledMetadataJson) as Map<String, dynamic>;
  });

  group('Region code resolution', () {
    test('returns the region for a number with a unique country calling code',
        () {
      final phone = PhoneNumber.parse('+33 655 5705 76');

      expect(phone.getRegionCode(), 'FR');
      expect(
          MetadataFinder.getRegionCodeForNumber(phone.countryCode, phone.nsn),
          'FR');
    });

    test('resolves a shared country calling code using leading digits', () {
      final phone = PhoneNumber.parse('+1 268 460 1234');

      expect(phone.getRegionCode(), 'AG');
      expect(
          MetadataFinder.getRegionCodeForNumber(phone.countryCode, phone.nsn),
          'AG');
    });

    test('resolves the main NANPA region for a US number', () {
      final phone = PhoneNumber.parse('+1 201 555 0123');

      expect(phone.getRegionCode(), 'US');
      expect(
        MetadataFinder.getRegionCodeForNumber(phone.countryCode, phone.nsn),
        'US',
      );
    });

    test('lists both US and AG for NANPA country code 1', () {
      final regions = MetadataFinder.getRegionCodesForCountryCode('1');

      expect(regions, contains('US'));
      expect(regions, contains('AG'));
    });

    test(
        'returns the main region when the country calling code has one region match only',
        () {
      expect(MetadataFinder.getRegionCodeForNumber('33', '655570576'), 'FR');
    });

    test('returns null when no region can be resolved', () {
      expect(MetadataFinder.getRegionCodeForNumber('999999', '123456'), isNull);
    });
  });
}
