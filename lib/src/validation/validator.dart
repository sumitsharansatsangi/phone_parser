import 'package:phone_parser/src/metadata/metadata_finder.dart';

import '../regex/constants.dart';
import 'phone_number_type.dart';

/// Validates phone numbers
abstract class Validator {
  static const List<PhoneNumberType> _detectableTypes = [
    PhoneNumberType.premiumRate,
    PhoneNumberType.tollFree,
    PhoneNumberType.sharedCost,
    PhoneNumberType.voip,
    PhoneNumberType.personalNumber,
    PhoneNumberType.pager,
    PhoneNumberType.uan,
    PhoneNumberType.voiceMail,
    PhoneNumberType.fixedLine,
    PhoneNumberType.mobile,
  ];

  /// Returns whether or not a national number is viable using pattern matching
  ///
  /// [nsn] national number without country code,
  /// international prefix, or national prefix
  static bool validateWithPattern(
    String isoCode,
    String national, [
    PhoneNumberType? type,
  ]) {
    // final metadata = MetadataFinder.findMetadataForIsoCode(isoCode);
    final patternMetadatas =
        MetadataFinder.findMetadataPatternsForIsoCode(isoCode);
    // if it's not matching the length it won't match the pattern
    if (!validateWithLength(isoCode, national)) {
      return false;
    }
    final patterns = type == null
        ? _detectableTypes
            .map((candidate) => _getPatterns(patternMetadatas, candidate))
            .where((pattern) => pattern.isNotEmpty)
            .toList()
        : [_getPatterns(patternMetadatas, type)];
    return patterns
        .any((r) => RegExp('^(?:$r)\$').firstMatch(national) != null);
  }

  /// Returns the detected phone number type.
  ///
  /// Returns [PhoneNumberType.unknown] when the number is invalid or does not
  /// match a known pattern for the region.
  static PhoneNumberType getNumberType(String isoCode, String national) {
    if (!validateWithLength(isoCode, national)) {
      return PhoneNumberType.unknown;
    }

    final patternMetadatas =
        MetadataFinder.findMetadataPatternsForIsoCode(isoCode);
    final generalPattern = patternMetadatas["general"];
    if (generalPattern.isEmpty ||
        RegExp('^(?:$generalPattern)\$').firstMatch(national) == null) {
      return PhoneNumberType.unknown;
    }

    for (final type in _detectableTypes) {
      if (type == PhoneNumberType.fixedLine || type == PhoneNumberType.mobile) {
        continue;
      }
      if (validateWithPattern(isoCode, national, type)) {
        return type;
      }
    }

    final isFixedLine = validateWithPattern(
      isoCode,
      national,
      PhoneNumberType.fixedLine,
    );
    final isMobile = validateWithPattern(
      isoCode,
      national,
      PhoneNumberType.mobile,
    );

    if (isFixedLine && isMobile) {
      return PhoneNumberType.fixedLineOrMobile;
    }
    if (isFixedLine) {
      return PhoneNumberType.fixedLine;
    }
    if (isMobile) {
      return PhoneNumberType.mobile;
    }

    return PhoneNumberType.unknown;
  }

  /// Returns whether or not a national number is viable using length
  ///
  /// [nsn] national number without country code,
  /// international prefix, or national prefix
  static bool validateWithLength(
    String isoCode,
    String national, [
    PhoneNumberType? type,
  ]) {
    final lengthMetadatas = MetadataFinder.findMetadataLengthForIsoCode(
      isoCode,
    );
    if (national.length < Constants.minLengthNsn) {
      return false;
    }
    final lengths = _getPossibleLengths(lengthMetadatas, type);
    final isRightLength = lengths.contains(national.length);
    // if we don't have length information we will do pattern matching
    // or if the length is correct we do pattern matching too
    if (isRightLength) {
      return true;
    }
    return false;
  }

  static Set<int> _getPossibleLengths(
    Map<String, dynamic> lengthMetadatas,
    PhoneNumberType? type,
  ) {
    if (type != null) {
      final lengths = _getLengths(lengthMetadatas, type);
      return Set.from(lengths);
    } else {
      // if the type is not specified it can be any of them
      // so we return a set containing all their possible lengths
      return {
        ..._getLengths(lengthMetadatas, PhoneNumberType.fixedLine),
        ..._getLengths(lengthMetadatas, PhoneNumberType.mobile),
        ..._getLengths(lengthMetadatas, PhoneNumberType.voip),
        ..._getLengths(lengthMetadatas, PhoneNumberType.tollFree),
        ..._getLengths(lengthMetadatas, PhoneNumberType.premiumRate),
        ..._getLengths(lengthMetadatas, PhoneNumberType.sharedCost),
        ..._getLengths(lengthMetadatas, PhoneNumberType.personalNumber),
        ..._getLengths(lengthMetadatas, PhoneNumberType.uan),
        ..._getLengths(lengthMetadatas, PhoneNumberType.pager),
        ..._getLengths(lengthMetadatas, PhoneNumberType.voiceMail),
      };
    }
  }

  static List<int> _getLengths(
    Map<String, dynamic> lengthMetadatas,
    PhoneNumberType? type,
  ) {
    String key;
    switch (type) {
      case PhoneNumberType.mobile:
        key = "mobile";
        break;
      case PhoneNumberType.fixedLine:
        key = "fixedLine";
        break;
      case PhoneNumberType.fixedLineOrMobile:
        return {
          ..._getLengths(lengthMetadatas, PhoneNumberType.fixedLine),
          ..._getLengths(lengthMetadatas, PhoneNumberType.mobile),
        }.toList();
      case PhoneNumberType.voip:
        key = "voip";
        break;
      case PhoneNumberType.tollFree:
        key = "tollFree";
        break;
      case PhoneNumberType.premiumRate:
        key = "premiumRate";
        break;
      case PhoneNumberType.sharedCost:
        key = "sharedCost";
        break;
      case PhoneNumberType.personalNumber:
        key = "personalNumber";
        break;
      case PhoneNumberType.uan:
        key = "uan";
        break;
      case PhoneNumberType.pager:
        key = "pager";
        break;
      case PhoneNumberType.voiceMail:
        key = "voiceMail";
        break;
      case PhoneNumberType.unknown:
      default:
        key = "general";
    }
    return (lengthMetadatas[key] as List<dynamic>?)
            ?.map((e) => e as int)
            .toList() ??
        [];
  }

  static String _getPatterns(
    Map<String, dynamic> patternMetadatas,
    PhoneNumberType? type,
  ) {
    switch (type) {
      case PhoneNumberType.mobile:
        return patternMetadatas["mobile"];
      case PhoneNumberType.fixedLine:
        return patternMetadatas["fixedLine"];
      case PhoneNumberType.fixedLineOrMobile:
        return '';
      case PhoneNumberType.voip:
        return patternMetadatas["voip"];
      case PhoneNumberType.tollFree:
        return patternMetadatas["tollFree"];
      case PhoneNumberType.premiumRate:
        return patternMetadatas["premiumRate"];
      case PhoneNumberType.sharedCost:
        return patternMetadatas["sharedCost"];
      case PhoneNumberType.personalNumber:
        return patternMetadatas["personalNumber"];
      case PhoneNumberType.uan:
        return patternMetadatas["uan"];
      case PhoneNumberType.pager:
        return patternMetadatas["pager"];
      case PhoneNumberType.voiceMail:
        return patternMetadatas["voiceMail"];
      case PhoneNumberType.unknown:
      default:
        return patternMetadatas["general"];
    }
  }
}
