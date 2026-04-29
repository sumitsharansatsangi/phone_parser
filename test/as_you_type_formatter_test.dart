import 'dart:convert';

import 'package:phone_parser/phone_parser.dart';
import 'package:phone_parser/src/metadata/bundled_metadata.g.dart';
import 'package:test/test.dart';

void main() {
  setUpAll(() {
    MetadataFinder.info =
        jsonDecode(bundledMetadataJson) as Map<String, dynamic>;
  });

  group('PhoneParserTextInputFormatter', () {
    test('formats US numbers progressively', () {
      final formatter = PhoneNumber.getAsYouTypeFormatter('US');
      final outputs = <String>[];

      for (final digit in '2025550119'.split('')) {
        outputs.add(formatter.inputDigit(digit));
      }

      expect(outputs.first, '2');
      expect(outputs[2], '(202');
      expect(outputs[3], '(202) 5');
      expect(outputs[5], '(202) 555');
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

    test('formats UK mobile numbers progressively', () {
      final formatter = PhoneNumber.getAsYouTypeFormatter('GB');
      final outputs = <String>[];

      for (final digit in '07400123456'.split('')) {
        outputs.add(formatter.inputDigit(digit));
      }

      expect(outputs[4], '07400');
      expect(outputs[5], '07400 1');
      expect(outputs.last, '07400 123456');
    });

    test('formats German fixed line numbers progressively', () {
      final formatter = PhoneNumber.getAsYouTypeFormatter('DE');
      final outputs = <String>[];

      for (final digit in '030123456'.split('')) {
        outputs.add(formatter.inputDigit(digit));
      }

      expect(outputs[2], '030');
      expect(outputs[3], '030 1');
      expect(outputs.last, '030 123456');
    });

    test('formats numbers whose first metadata group is one digit', () {
      final formatter = PhoneNumber.getAsYouTypeFormatter('AE');
      final outputs = <String>[];

      for (final digit in '021234567'.split('')) {
        outputs.add(formatter.inputDigit(digit));
      }

      expect(outputs[1], '02');
      expect(outputs[2], '02 1');
      expect(outputs.last, '02 123 4567');
    });

    test('does not inject optional Indian national prefix while typing mobile',
        () {
      final formatter = PhoneNumber.getAsYouTypeFormatter('IN');
      final outputs = <String>[];

      for (final digit in '9931571989'.split('')) {
        outputs.add(formatter.inputDigit(digit));
      }

      expect(
        outputs,
        [
          '9',
          '99',
          '993',
          '9931',
          '99315',
          '99315 7',
          '99315 71',
          '99315 719',
          '99315 7198',
          '99315 71989',
        ],
      );

      final deletionOutputs = <String>[];
      for (var i = 0; i < 9; i++) {
        deletionOutputs.add(formatter.removeLastDigit());
      }

      expect(
        deletionOutputs,
        [
          '99315 7198',
          '99315 719',
          '99315 71',
          '99315 7',
          '99315',
          '9931',
          '993',
          '99',
          '9',
        ],
      );
    });

    test('keeps optional Indian national prefix when the user enters it', () {
      final formatter = PhoneNumber.getAsYouTypeFormatter('IN');

      String output = '';
      for (final digit in '09931571989'.split('')) {
        output = formatter.inputDigit(digit);
      }

      expect(output, '099315 71989');
    });

    test('formats international input with a leading plus sign', () {
      final formatter = PhoneNumber.getAsYouTypeFormatter('FR');

      String output = '';
      for (final digit in '+33655570576'.split('')) {
        output = formatter.inputDigit(digit);
      }

      expect(output, '+33 6 55 57 05 76');
    });

    test(
        'formats NANPA international input and preserves shared country code prefix',
        () {
      final formatter = PhoneNumber.getAsYouTypeFormatter('US');

      String output = '';
      for (final digit in '+12684601234'.split('')) {
        output = formatter.inputDigit(digit);
      }

      expect(output, '+1 268-460-1234');
    });

    test('normalizes eastern arabic digits', () {
      final formatter = PhoneNumber.getAsYouTypeFormatter('FR');

      String output = '';
      for (final digit in '٠٦٥٥٥٧٠٥٧٦'.split('')) {
        output = formatter.inputDigit(digit);
      }

      expect(output, '06 55 57 05 76');
    });

    test('formats pasted text by normalizing separators', () {
      final formatter = PhoneNumber.getAsYouTypeFormatter('US');

      final output = formatter.inputDigit('202-555 0119');

      expect(output, '(202) 555-0119');
      expect(formatter.normalizedDigits, '2025550119');
    });

    test('replace resets previous input before formatting new content', () {
      final formatter = PhoneNumber.getAsYouTypeFormatter('US');

      formatter.inputDigit('2025550119');
      final output = formatter.replace('4155552671');

      expect(output, '(415) 555-2671');
      expect(formatter.normalizedDigits, '4155552671');
    });

    test('ignores digits beyond the E.164 maximum length', () {
      final formatter = PhoneNumber.getAsYouTypeFormatter('US');

      final output = formatter.inputDigit('12345678901234567890');

      expect(formatter.normalizedDigits,
          hasLength(PhoneParserTextInputFormatter.maxDigits));
      expect(output, isNotEmpty);
    });

    test('removeLastDigit updates the formatted output', () {
      final formatter = PhoneNumber.getAsYouTypeFormatter('US');

      formatter.inputDigit('2025550119');
      final output = formatter.removeLastDigit();

      expect(output, '(202) 555-011');
      expect(formatter.normalizedDigits, '202555011');
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
