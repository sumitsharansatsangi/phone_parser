import 'dart:convert';

import 'package:phone_parser/phone_parser.dart';
import 'package:phone_parser/src/metadata/bundled_metadata.g.dart';
import 'package:test/test.dart';

void main() {
  setUpAll(() {
    MetadataFinder.info =
        jsonDecode(bundledMetadataJson) as Map<String, dynamic>;
  });

  group('PhoneNumberOfflineGeocoder', () {
    test('returns the English territory for a unique country code', () {
      final phoneNumber = PhoneNumber.parse('+33 655 5705 76');

      expect(
        PhoneNumberOfflineGeocoder.instance.getDescriptionForNumber(
          phoneNumber,
          Locale.english,
        ),
        'France',
      );
      expect(phoneNumber.getDescription(), 'France');
    });

    test('returns the resolved NANPA territory name', () {
      final phoneNumber = PhoneNumber.parse('+1 268 460 1234');

      expect(
        PhoneNumberOfflineGeocoder.instance.getDescriptionForNumber(
          phoneNumber,
          Locale.english,
        ),
        'Antigua & Barbuda',
      );
    });

    test('omits the territory when user region matches', () {
      final phoneNumber = PhoneNumber.parse('+33 655 5705 76');

      expect(
        PhoneNumberOfflineGeocoder.instance.getDescriptionForNumber(
          phoneNumber,
          Locale.english,
          'FR',
        ),
        isEmpty,
      );
    });

    test('returns empty for invalid numbers', () {
      const phoneNumber = PhoneNumber(isoCode: 'FR', nsn: '123');

      expect(
        PhoneNumberOfflineGeocoder.instance.getDescriptionForNumber(
          phoneNumber,
          Locale.english,
        ),
        isEmpty,
      );
    });
  });
}
