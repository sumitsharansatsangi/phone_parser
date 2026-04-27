import 'dart:convert';

import 'package:phone_parser/phone_parser.dart';
import 'package:phone_parser/src/metadata/bundled_metadata.g.dart';
import 'package:test/test.dart';

void main() {
  setUpAll(() {
    MetadataFinder.info = jsonDecode(bundledMetadataJson) as Map<String, dynamic>;
  });

  group('PhoneNumber example numbers', () {
    test('returns the default fixed line example for a region', () {
      final example = PhoneNumber.getExampleNumber('ZA');

      expect(example, isNotNull);
      expect(example!.isoCode, 'ZA');
      expect(example.nsn, '101234567');
      expect(example.getNumberType(), PhoneNumberType.fixedLine);
    });

    test('returns a typed example when present', () {
      final example = PhoneNumber.getExampleNumberForType(
        isoCode: 'ZA',
        type: PhoneNumberType.mobile,
      );

      expect(example, isNotNull);
      expect(example!.nsn, '711234567');
      expect(example.getNumberType(), PhoneNumberType.mobile);
    });

    test('returns null for unsupported example types', () {
      final example = PhoneNumber.getExampleNumberForType(
        isoCode: 'ZA',
        type: PhoneNumberType.unknown,
      );

      expect(example, isNull);
    });

    test('returns null for invalid regions', () {
      final example = PhoneNumber.getExampleNumber('ZZZ');

      expect(example, isNull);
    });
  });
}
