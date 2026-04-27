import 'dart:convert';

import 'package:phone_parser/phone_parser.dart';
import 'package:phone_parser/src/metadata/bundled_metadata.g.dart';
import 'package:test/test.dart';

void main() {
  setUpAll(() {
    MetadataFinder.info =
        jsonDecode(bundledMetadataJson) as Map<String, dynamic>;
  });

  group('AsYouTypeFormatter', () {
    test('formats US numbers progressively', () {
      final formatter = PhoneNumber.getAsYouTypeFormatter('US');
      final outputs = <String>[];

      for (final digit in '2025550119'.split('')) {
        outputs.add(formatter.inputDigit(digit));
      }

      expect(outputs.first, '2');
      expect(outputs[2], '202');
      expect(outputs.last, '(202) 555-0119');
    });

    test('keeps national prefix formatting for French numbers', () {
      final formatter = PhoneNumber.getAsYouTypeFormatter('FR');

      String output = '';
      for (final digit in '0655570576'.split('')) {
        output = formatter.inputDigit(digit);
      }

      expect(output, '06 55 57 05 76');
    });

    test('formats international input with a leading plus sign', () {
      final formatter = PhoneNumber.getAsYouTypeFormatter('FR');

      String output = '';
      for (final digit in '+33655570576'.split('')) {
        output = formatter.inputDigit(digit);
      }

      expect(output, '+33 6 55 57 05 76');
    });

    test('normalizes eastern arabic digits', () {
      final formatter = PhoneNumber.getAsYouTypeFormatter('FR');

      String output = '';
      for (final digit in '٠٦٥٥٥٧٠٥٧٦'.split('')) {
        output = formatter.inputDigit(digit);
      }

      expect(output, '06 55 57 05 76');
    });

    test('can be cleared and reused', () {
      final formatter = PhoneNumber.getAsYouTypeFormatter('US');

      for (final digit in '2025550119'.split('')) {
        formatter.inputDigit(digit);
      }

      formatter.clear();

      expect(formatter.currentOutput, isEmpty);
      expect(formatter.inputDigit('4'), '4');
    });
  });
}
