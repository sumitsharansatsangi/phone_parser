import 'dart:math';

import 'package:phone_parser/src/metadata/metadata_finder.dart';
import 'package:phone_parser/src/parsers/_national_number_parser.dart';

enum NsnFormat { national, international }

class PhoneNumberFormatter {
  /// format national number for international use
  static String formatNsn(
    String nsn,
    String isoCode, [
    NsnFormat format = NsnFormat.national,
  ]) {
    if (nsn.isEmpty) {
      return nsn;
    }
    // since the phone number might be incomplete, fake digits
    // are temporarily added to format a complete number.
    final missingDigits = _getMissingDigits(nsn, isoCode);
    final completePhoneNumber = nsn + missingDigits;
    final formatingRules = MetadataFinder.findMetadataFormatsForIsoCode(
      isoCode,
    );
    if (formatingRules.isEmpty) {
      return nsn;
    }
    List<Map<String, dynamic>> fm =
        (formatingRules).map((e) => e as Map<String, dynamic>).toList();
    final formatingRule = _getMatchingFormatRules(
      formatingRules: fm,
      nsn: completePhoneNumber,
    );
    // for incomplete phone number

    if (formatingRule == null) {
      return nsn;
    }
    var transformRule = formatingRule["format"];
    // if there is an international format, we use it
    final intlFormat = formatingRule["intlFormat"];
    if (format == NsnFormat.international &&
        intlFormat != null &&
        intlFormat != 'NA') {
      transformRule = intlFormat;
    }

    var formatted = NationalNumberParser.applyTransformRules(
      appliedTo: completePhoneNumber,
      pattern: formatingRule["pattern"],
      transformRule: transformRule,
    );
    formatted = _removeMissingDigits(formatted, missingDigits);
    return formatted;
  }

  static String _removeMissingDigits(String formatted, String missingDigits) {
    while (missingDigits.isNotEmpty) {
      // not an ending digit
      final isEndingWithSpecialChar =
          int.tryParse(formatted[formatted.length - 1]) == null;
      if (isEndingWithSpecialChar) {
        formatted = formatted.substring(0, formatted.length - 1);
      } else {
        formatted = formatted.substring(0, formatted.length - 1);
        missingDigits = missingDigits.substring(0, missingDigits.length - 1);
      }
    }
    final isEndingWithSpecialChar =
        int.tryParse(formatted[formatted.length - 1]) == null;
    if (isEndingWithSpecialChar) {
      formatted = formatted.substring(0, formatted.length - 1);
    }
    return formatted;
  }

  /// returns 9's to have a valid length number
  static String _getMissingDigits(String nsn, String isoCode) {
    final lengthRule = MetadataFinder.findMetadataLengthForIsoCode(isoCode);

    final minLength =
        max<int>(lengthRule["fixedLine"].first, lengthRule["mobile"].first);
    // added digits so we match the pattern in case of an incomplete phone number
    var missingDigits = '';

    while ((nsn + missingDigits).length < minLength) {
      missingDigits += '9';
    }
    return missingDigits;
  }

  /// gets the matching format rule,
  /// if there is only one formatting rule return it,
  /// else finds the formatting rule that better matches the phone number
  static Map<String, dynamic>? _getMatchingFormatRules({
    required List<Map<String, dynamic>> formatingRules,
    required String nsn,
  }) {
    if (formatingRules.isEmpty) {
      return null;
    }

    if (formatingRules.length == 1) {
      return formatingRules[0];
    }

    for (var rules in formatingRules) {
      // phonenumberkit seems to be using the last leading digit pattern
      // from the list of pattern so that's what we are going to do here as well
      final matchLeading =
          RegExp(rules["leadingDigits"].last).matchAsPrefix(nsn);
      final pattern = rules["pattern"];
      final matchPattern = RegExp('^(?:$pattern)\$').firstMatch(nsn);
      if (matchLeading != null && matchPattern != null) {
        return rules;
      }
    }

    return null;
  }
}
