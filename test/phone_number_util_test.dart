import 'dart:convert';

import 'package:phone_parser/phone_parser.dart';
import 'package:phone_parser/src/metadata/bundled_metadata.g.dart';
import 'package:test/test.dart';

void main() {
  setUpAll(() {
    MetadataFinder.info =
        jsonDecode(bundledMetadataJson) as Map<String, dynamic>;
  });

  group('PhoneNumberUtil', () {
    final phoneUtil = PhoneNumberUtil.instance;

    test('parses and validates numbers', () {
      final phoneNumber = phoneUtil.parse('0 655 5705 76', callerCountry: 'FR');

      expect(phoneNumber.international, '+33655570576');
      expect(phoneUtil.isValidNumber(phoneNumber), isTrue);
      expect(phoneUtil.isPossibleNumber(phoneNumber), isTrue);
      expect(phoneUtil.isValidNumberForRegion(phoneNumber, 'FR'), isTrue);
    });

    test('formats and detects number type', () {
      final phoneNumber =
          phoneUtil.parse('2025550119', destinationCountry: 'US');

      expect(phoneUtil.format(phoneNumber), '(202) 555-0119');
      expect(phoneUtil.getNumberType(phoneNumber),
          PhoneNumberType.fixedLineOrMobile);
    });

    test('returns a libphonenumber-style as-you-type formatter', () {
      final formatter = phoneUtil.getAsYouTypeFormatter('US');

      for (final digit in '2025550119'.split('')) {
        formatter.inputDigit(digit);
      }

      expect(formatter.currentOutput, '(202) 555-0119');
    });

    test('matches and finds numbers', () {
      final phoneNumber = phoneUtil.parse('+33 655 5705 76');
      final found =
          phoneUtil.findNumbers('Call +33 655 5705 76 tomorrow').toList();

      expect(phoneUtil.isNumberMatch(phoneNumber, '+33 655 5705 76'),
          MatchType.exactMatch);
      expect(found, hasLength(1));
      expect(found.single, phoneNumber);
    });

    test('returns geocoding descriptions', () {
      final phoneNumber = phoneUtil.parse('+33 655 5705 76');

      expect(
        phoneUtil.getDescriptionForNumber(phoneNumber, Locale.english),
        'France',
      );
    });
  });
}
