import 'dart:math';

import 'package:phone_parser/src/formatting/phone_number_formatter.dart';
import 'package:phone_parser/src/metadata/metadata_finder.dart';
import 'package:phone_parser/src/parsers/_national_number_parser.dart';
import 'package:phone_parser/src/regex/constants.dart';

/// Formats a phone number as digits are entered.
class AsYouTypeFormatter {
  static const int maxDigits = 15;
  final String isoCode;
  final NsnFormat format;
  final int digitLimit;

  final StringBuffer _digits = StringBuffer();
  bool _hasLeadingPlus = false;

  AsYouTypeFormatter({
    required this.isoCode,
    this.format = NsnFormat.national,
    this.digitLimit = maxDigits,
  }) : assert(digitLimit >= 0);

  /// Current normalized numeric input, excluding a leading plus sign.
  String get normalizedDigits => _digits.toString();

  /// Whether the current input started with a leading plus sign.
  bool get hasLeadingPlus => _hasLeadingPlus;

  /// Clears all previously entered input.
  void clear() {
    _digits.clear();
    _hasLeadingPlus = false;
  }

  /// Replaces all current input with [input] and returns the formatted output.
  String replace(String input) {
    clear();
    return inputDigit(input);
  }

  /// Adds one or more characters and returns the formatted output.
  ///
  /// Unsupported characters are ignored.
  String inputDigit(String input) {
    for (final rune in input.runes) {
      if (_digits.length >= digitLimit) {
        break;
      }

      final normalized = Constants.allNormalizationMappings[String.fromCharCode(
        rune,
      )];
      if (normalized == null) {
        continue;
      }

      if (normalized == '+') {
        if (!_hasLeadingPlus && _digits.isEmpty) {
          _hasLeadingPlus = true;
        }
        continue;
      }

      _digits.write(normalized);
    }

    return currentOutput;
  }

  /// Removes the last entered digit and returns the formatted output.
  String removeLastDigit() {
    if (_digits.isNotEmpty) {
      final digits = _digits.toString();
      _digits
        ..clear()
        ..write(digits.substring(0, digits.length - 1));
    } else {
      _hasLeadingPlus = false;
    }

    return currentOutput;
  }

  /// The formatted output for the digits entered so far.
  String get currentOutput {
    if (_hasLeadingPlus) {
      return _formatInternational();
    }
    return _formatNational();
  }

  String _formatNational() {
    final enteredDigits = _digits.toString();
    if (enteredDigits.isEmpty) {
      return '';
    }

    final metadata = MetadataFinder.findMetadataForIsoCode(isoCode);
    final nsn =
        NationalNumberParser.transformLocalNsnToInternationalUsingPatterns(
      enteredDigits,
      metadata,
    );
    if (nsn.isEmpty) {
      return enteredDigits;
    }

    return PhoneNumberFormatter.formatNsn(nsn, isoCode, format);
  }

  String _formatInternational() {
    final digits = _digits.toString();
    if (digits.isEmpty) {
      return '+';
    }

    final countryCode = _detectCountryCode(digits);
    if (countryCode == null) {
      return '+$digits';
    }

    final nsn = digits.substring(countryCode.length);
    if (nsn.isEmpty) {
      return '+$countryCode';
    }

    final regionCode = _resolveRegionCode(countryCode, nsn);
    final formattedNsn = PhoneNumberFormatter.formatNsn(
      nsn,
      regionCode,
      NsnFormat.international,
    );
    return '+$countryCode $formattedNsn';
  }

  String? _detectCountryCode(String digits) {
    final maxLength = min(3, digits.length);
    String? countryCode;
    for (var i = 1; i <= maxLength; i++) {
      final candidate = digits.substring(0, i);
      if (MetadataFinder.getRegionCodesForCountryCode(candidate).isNotEmpty) {
        countryCode = candidate;
      }
    }
    return countryCode;
  }

  String _resolveRegionCode(String countryCode, String nsn) {
    return MetadataFinder.getRegionCodeForNumber(countryCode, nsn) ??
        MetadataFinder.getRegionCodeForCountryCode(countryCode) ??
        isoCode;
  }
}
