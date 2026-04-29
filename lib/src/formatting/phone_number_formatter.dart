import 'dart:math';

import 'package:phone_parser/src/metadata/metadata_finder.dart';
import 'package:phone_parser/src/parsers/_national_number_parser.dart';

enum NsnFormat { national, international }

class PhoneNumberFormatter {
  /// format national number for international use
  static String formatNsn(
    String nsn,
    String isoCode, [
    NsnFormat format = NsnFormat.international,
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
      final nanpaFallback = _formatNanpaSharedRegionWithoutMetadata(
        nsn: nsn,
        isoCode: isoCode,
      );
      if (nanpaFallback != null) {
        return nanpaFallback;
      }
      return nsn;
    }
    List<Map<String, dynamic>> fm =
        (formatingRules).map((e) => e as Map<String, dynamic>).toList();
    final formatingRule = _getMatchingFormatRules(
      formatingRules: fm,
      nsn: completePhoneNumber,
    );
    final fallbackRule = formatingRule ??
        _getBestPartialFormatRule(
          formatingRules: fm,
          nsn: nsn,
        );
    if (fallbackRule == null) {
      return nsn;
    }
    var transformRule = fallbackRule["format"];
    // if there is an international format, we use it
    final intlFormat = fallbackRule["intlFormat"];
    if (format == NsnFormat.international &&
        intlFormat != null &&
        intlFormat != 'NA') {
      transformRule = intlFormat;
    } else if (format == NsnFormat.national) {
      transformRule = _applyNationalPrefixFormattingRule(
        transformRule: transformRule,
        formatingRule: fallbackRule,
        isoCode: isoCode,
      );
    }

    if (missingDigits.isNotEmpty) {
      return _formatIncompleteNsn(
        nsn: nsn,
        pattern: fallbackRule["pattern"].toString(),
        transformRule: transformRule.toString(),
      );
    }

    var formatted = NationalNumberParser.applyTransformRules(
      appliedTo: completePhoneNumber,
      pattern: fallbackRule["pattern"],
      transformRule: transformRule,
    );
    formatted = _removeMissingDigits(formatted, missingDigits);
    return formatted;
  }

  static String _formatIncompleteNsn({
    required String nsn,
    required String pattern,
    required String transformRule,
  }) {
    final ranges = _extractGroupLengthRanges(pattern);
    if (ranges.isEmpty) return nsn;

    final groups = <String>[];
    var start = 0;
    for (final range in ranges) {
      if (start >= nsn.length) break;
      final end = min(start + range.max, nsn.length);
      groups.add(nsn.substring(start, end));
      start = end;
    }

    if (groups.isEmpty) {
      return nsn;
    }

    final placeholderPattern = RegExp(r'\$(\d+)');
    final matches = placeholderPattern.allMatches(transformRule).toList();
    if (matches.isEmpty) {
      return nsn;
    }

    final buffer = StringBuffer();
    var cursor = 0;
    for (final match in matches) {
      final groupIndex = int.parse(match.group(1)!);
      final literal = transformRule.substring(cursor, match.start);
      final hasGroup = groupIndex <= groups.length;
      final groupValue = hasGroup ? groups[groupIndex - 1] : '';
      final groupIsComplete = hasGroup &&
          groupIndex <= ranges.length &&
          groupValue.length == ranges[groupIndex - 1].max;

      if (literal.isNotEmpty) {
        final shouldPrintLiteral = groupIndex == 1
            ? groupIsComplete
            : (groupIndex <= groups.length && groups[groupIndex - 2].isNotEmpty);
        if (shouldPrintLiteral) buffer.write(literal);
      }

      if (hasGroup) {
        buffer.write(groupValue);
      }
      cursor = match.end;
    }

    return buffer.isEmpty ? nsn : buffer.toString();
  }

  static String _applyNationalPrefixFormattingRule({
    required String transformRule,
    required Map<String, dynamic> formatingRule,
    required String isoCode,
  }) {
    final nationalPrefixFormattingRule =
        formatingRule["nationalPrefixFormattingRule"]?.toString();
    if (nationalPrefixFormattingRule == null ||
        nationalPrefixFormattingRule.isEmpty) {
      return transformRule;
    }

    final nationalPrefix =
        MetadataFinder.findMetadataForIsoCode(isoCode)["nationalPrefix"]
            ?.toString();
    if (nationalPrefix == null || nationalPrefix.isEmpty) {
      return transformRule;
    }

    final firstGroupToken = r'$1';
    final formattedFirstGroup = nationalPrefixFormattingRule
        .replaceAll(r'$NP', nationalPrefix)
        .replaceAll(r'$FG', firstGroupToken);

    return transformRule.replaceFirst(firstGroupToken, formattedFirstGroup);
  }

  static String _removeMissingDigits(String formatted, String missingDigits) {
    var result = formatted;
    var remaining = missingDigits;

    while (remaining.isNotEmpty && result.isNotEmpty) {
      if (int.tryParse(result[result.length - 1]) == null) {
        // trailing separator — remove it but don't consume a missing digit
        result = result.substring(0, result.length - 1);
      } else {
        // real (fake) digit — consume one from both
        result = result.substring(0, result.length - 1);
        remaining = remaining.substring(0, remaining.length - 1);
      }
    }

    // strip any trailing separator left after all fake digits removed
    while (
        result.isNotEmpty && int.tryParse(result[result.length - 1]) == null) {
      result = result.substring(0, result.length - 1);
    }

    return result;
  }

  /// returns 9's to have a valid length number
  static String _getMissingDigits(String nsn, String isoCode) {
    final lengthRule = MetadataFinder.findMetadataLengthForIsoCode(isoCode);
    var missingDigits = '';
    final minLengths = lengthRule.entries
        .where((entry) => entry.key != "general" && entry.value.isNotEmpty)
        .map((entry) => entry.value.first);
    if (minLengths.isNotEmpty) {
      final minLength = minLengths.reduce(min<int>);
      while ((nsn + missingDigits).length < minLength) {
        missingDigits += '9';
      }
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
      final dynamic rawLeading = rules["leadingDigits"];
      final leadingDigits = rawLeading is List ? rawLeading : const [];
      final matchLeading = leadingDigits.isEmpty ||
          leadingDigits.every(
            (p) => RegExp(p.toString()).matchAsPrefix(nsn) != null,
          );
      final pattern = rules["pattern"];
      final matchPattern = RegExp('^(?:$pattern)\$').firstMatch(nsn);
      if (matchLeading && matchPattern != null) {
        return rules;
      }
    }

    return null;
  }

  static Map<String, dynamic>? _getBestPartialFormatRule({
    required List<Map<String, dynamic>> formatingRules,
    required String nsn,
  }) {
    Map<String, dynamic>? bestRule;
    int bestCapacity = 0;

    for (final rules in formatingRules) {
      if (!_matchesLeadingDigits(rules, nsn)) continue;

      final groupLengths = _extractGroupLengths(rules["pattern"].toString());
      final capacity = groupLengths.fold<int>(0, (s, v) => s + v);
      if (capacity < nsn.length) continue;

      // prefer tightest fit (smallest capacity that still covers the NSN)
      if (bestRule == null || capacity < bestCapacity) {
        bestRule = rules;
        bestCapacity = capacity;
      }
    }

    return bestRule;
  }

  static bool _matchesLeadingDigits(Map<String, dynamic> rules, String nsn) {
    final dynamic leadingDigits = rules["leadingDigits"];
    if (leadingDigits == null) {
      return true;
    }

    if (leadingDigits is List && leadingDigits.isNotEmpty) {
      return leadingDigits.every(
        (p) => RegExp(p.toString()).matchAsPrefix(nsn) != null,
      );
    }

    if (leadingDigits is String && leadingDigits.isNotEmpty) {
      return RegExp(leadingDigits).matchAsPrefix(nsn) != null;
    }

    return true;
  }

  // Returns (min, max) per group so callers can decide
  static List<({int min, int max})> _extractGroupLengthRanges(String pattern) {
    final matches = RegExp(r'\\d\{(\d+)(?:,(\d+))?\}').allMatches(pattern);
    return matches.map((m) {
      final lo = int.parse(m.group(1)!);
      final hi = m.group(2) != null ? int.parse(m.group(2)!) : lo;
      return (min: lo, max: hi);
    }).toList();
  }

// Keep the old signature for callers that only need max (complete number path)
  static List<int> _extractGroupLengths(String pattern) =>
      _extractGroupLengthRanges(pattern).map((r) => r.max).toList();

  static String? _formatNanpaSharedRegionWithoutMetadata({
    required String nsn,
    required String isoCode,
  }) {
    try {
      final metadata = MetadataFinder.findMetadataForIsoCode(isoCode);
      final countryCode = metadata['countryCode']?.toString();
      final leadingDigits = metadata['leadingDigits']?.toString();
      final isMainCountry = metadata['isMainCountryForDialCode'] == true;
      final regions = countryCode == null
          ? const <String>[]
          : MetadataFinder.getRegionCodesForCountryCode(countryCode);

      final isSharedNanpaRegion = countryCode == '1' &&
          regions.length > 1 &&
          !isMainCountry &&
          leadingDigits != null &&
          leadingDigits.isNotEmpty;
      if (!isSharedNanpaRegion) {
        return null;
      }

      return _formatGroupedDigits(
        nsn: nsn,
        groupLengths: const [3, 3, 4],
        separator: '-',
      );
    } catch (_) {
      return null;
    }
  }

  static String _formatGroupedDigits({
    required String nsn,
    required List<int> groupLengths,
    required String separator,
  }) {
    final buffer = StringBuffer();
    var start = 0;

    for (var i = 0; i < groupLengths.length; i++) {
      if (start >= nsn.length) {
        break;
      }

      final end = min(start + groupLengths[i], nsn.length);
      final group = nsn.substring(start, end);
      final isCompleteGroup = group.length == groupLengths[i];

      if (i > 0 && (isCompleteGroup || start < nsn.length)) {
        buffer.write(separator);
      }

      buffer.write(group);
      start = end;
    }

    if (start < nsn.length) {
      buffer.write(separator);
      buffer.write(nsn.substring(start));
    }

    return buffer.toString();
  }
}
