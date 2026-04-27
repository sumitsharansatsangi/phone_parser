import 'dart:convert';

import 'package:phone_parser/phone_parser.dart';
import 'package:phone_parser/src/metadata/bundled_metadata.g.dart';
import 'package:test/test.dart';

void main() {
  setUpAll(() {
    MetadataFinder.info = jsonDecode(bundledMetadataJson) as Map<String, dynamic>;
  });

  group('MetadataFinder utilities', () {
    test('lists supported regions', () {
      expect(MetadataFinder.supportedRegions, containsAll(['FR', 'US', 'ZA']));
    });

    test('lists supported calling codes without duplicates', () {
      final callingCodes = MetadataFinder.supportedCallingCodes;

      expect(callingCodes, contains('1'));
      expect(callingCodes.where((code) => code == '1').length, 1);
    });

    test('returns the main region for a country calling code', () {
      expect(MetadataFinder.getRegionCodeForCountryCode('1'), 'US');
      expect(MetadataFinder.getRegionCodeForCountryCode('999999'), isNull);
    });

    test('returns all regions for a country calling code', () {
      final regions = MetadataFinder.getRegionCodesForCountryCode('1');

      expect(regions, containsAll(['US', 'AG']));
    });

    test('returns the country calling code for a region', () {
      expect(MetadataFinder.getCountryCodeForRegion('FR'), '33');
      expect(MetadataFinder.getCountryCodeForRegion('ZZZ'), isNull);
    });

    test('returns supported types for a region', () {
      final types = MetadataFinder.getSupportedTypesForRegion('ZA');

      expect(
        types,
        containsAll([
          PhoneNumberType.fixedLine,
          PhoneNumberType.mobile,
          PhoneNumberType.voip,
          PhoneNumberType.tollFree,
          PhoneNumberType.premiumRate,
          PhoneNumberType.sharedCost,
          PhoneNumberType.uan,
        ]),
      );
      expect(types, isNot(contains(PhoneNumberType.fixedLineOrMobile)));
      expect(types, isNot(contains(PhoneNumberType.unknown)));
    });
  });
}
