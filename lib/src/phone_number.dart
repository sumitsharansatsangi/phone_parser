import 'package:phone_parser/src/formatting/phone_number_formatter.dart';
import 'package:phone_parser/src/metadata/metadata_finder.dart';
import 'package:phone_parser/src/parsers/_text_parser.dart';
import 'package:phone_parser/src/parsers/phone_parser.dart';
import 'package:phone_parser/src/range/phone_number_range.dart';
import 'package:phone_parser/src/validation/match_type.dart';
import 'package:phone_parser/src/validation/phone_number_type.dart';
import 'package:phone_parser/src/validation/validator.dart';

/// represents a phone number
///
/// Use [PhoneNumber.parse] to compute a phone number.
/// Use [PhoneNumber] if you know the phone number nsn and iso code
/// you can use the default constructor, this won't run any computation.
class PhoneNumber {
  /// National number in its international form
  final String nsn;

  /// country alpha2 code example: 'FR', 'US', ...
  final String isoCode;

  /// territory numerical code that precedes a phone number. Example 33 for france
  String get countryCode =>
      MetadataFinder.findMetadataForIsoCode(isoCode)["countryCode"];

  /// international version of phone number
  String get international => '+$countryCode$nsn';

  const PhoneNumber({required this.isoCode, required this.nsn});

  /// {@template phoneNumber}
  /// Parses a phone number given caller or destination information.
  ///
  /// The logic is:
  ///
  ///  1. Remove the international prefix / exit code
  ///    a. if caller is provided remove the international prefix / exit code
  ///    b. if caller is not provided be a best guess is done with a possible destination
  ///       country
  ///  2. Find destination country
  ///    a. if no destination country was provided, the destination is assumed to be the
  ///       same as the caller
  ///    b. if no caller was provided a best guess is estimated by looking at
  ///       the first digits to see if they match a country. Since multiple countries
  ///       share the same country code, pattern matching might be used when there are
  ///       multiple matches.
  ///  3. Extract the country code with the country information
  ///  4. Transform a local NSN to an international version
  ///
  /// {@endtemplate}
  static PhoneNumber parse(
    String phoneNumber, {
    String? callerCountry,
    String? destinationCountry,
  }) =>
      PhoneParser.parse(
        phoneNumber,
        callerCountry: callerCountry,
        destinationCountry: destinationCountry,
      );

  /// Returns a valid fixed-line example number for the given region when available.
  static PhoneNumber? getExampleNumber(String isoCode) =>
      getExampleNumberForType(
        isoCode: isoCode,
        type: PhoneNumberType.fixedLine,
      );

  /// Returns a valid example number for the given region and type when available.
  static PhoneNumber? getExampleNumberForType({
    required String isoCode,
    required PhoneNumberType type,
  }) {
    final normalizedIsoCode = isoCode.toUpperCase();
    if (type == PhoneNumberType.unknown) {
      return null;
    }

    try {
      final metadata = MetadataFinder.findMetadataForIsoCode(normalizedIsoCode);
      final examples = MetadataFinder.findMetadataExamplesForIsoCode(
        normalizedIsoCode,
      );
      final example = examples[_exampleKeyForType(type)];
      if (example == null || example.isEmpty) {
        return null;
      }
      return PhoneNumber(isoCode: metadata["isoCode"], nsn: example);
    } catch (_) {
      return null;
    }
  }

  /// formats the nsn, if no [isoCode] is provided the phone number region is used.
  String formatNsn({String? isoCode, NsnFormat format = NsnFormat.national}) =>
      PhoneNumberFormatter.formatNsn(nsn, isoCode ?? this.isoCode, format);
  //
  //  Validation
  //

  /// validates a phone number by first checking its length then pattern matching
  bool isValid({PhoneNumberType? type}) =>
      Validator.validateWithPattern(isoCode, nsn, type);

  /// Validates a phone number against a specific region.
  ///
  /// Returns `false` when the region code is invalid, when the region does not
  /// share this number's country calling code, or when the national number does
  /// not match the target region's metadata.
  bool isValidForRegion(String regionCode, {PhoneNumberType? type}) {
    final normalizedRegionCode = regionCode.toUpperCase();

    try {
      final regionMetadata = MetadataFinder.findMetadataForIsoCode(
        normalizedRegionCode,
      );
      if (regionMetadata["countryCode"] != countryCode) {
        return false;
      }
      return Validator.validateWithPattern(normalizedRegionCode, nsn, type);
    } catch (_) {
      return false;
    }
  }

  /// validates a phone number by only checking its length
  bool isValidLength({PhoneNumberType? type}) =>
      Validator.validateWithLength(isoCode, nsn, type);

  /// Detects the phone number type.
  ///
  /// Returns [PhoneNumberType.unknown] when the number is invalid or when no
  /// known type matches the region metadata.
  PhoneNumberType getNumberType() => Validator.getNumberType(isoCode, nsn);

  /// Returns the best-matching region code for this phone number.
  ///
  /// For shared calling codes, this uses leading digits and per-region pattern
  /// validation to resolve the most likely region. Returns `null` when no
  /// region can be determined from the available metadata.
  String? getRegionCode() => MetadataFinder.getRegionCodeForNumber(
    countryCode,
    nsn,
  );

  //
  //  text
  //

  static Iterable<PhoneNumber> findPotentialPhoneNumbers(String text) =>
      TextParser.findPotentialPhoneNumbers(text).map((match) {
        try {
          return PhoneNumber.parse(match.group(0)!);
        } catch (e) {
          return null;
        }
      }).whereType<PhoneNumber>();

  /// Compares two phone numbers for equality at different match strengths.
  ///
  /// This supports [PhoneNumber] instances directly and can also compare raw
  /// strings. When a string does not contain an explicit country calling code,
  /// this method will infer the region from the other operand when possible.
  static MatchType isNumberMatch(Object firstNumberIn, Object secondNumberIn) {
    final first = _coerceToComparableNumber(
      firstNumberIn,
      counterpart: secondNumberIn is PhoneNumber ? secondNumberIn : null,
    );
    if (first == null) {
      return MatchType.notANumber;
    }

    final second = _coerceToComparableNumber(
      secondNumberIn,
      counterpart: first.number,
    );
    if (second == null) {
      return MatchType.notANumber;
    }

    if (first.number == second.number) {
      return first.hadExplicitCountryContext && second.hadExplicitCountryContext
          ? MatchType.exactMatch
          : MatchType.nsnMatch;
    }

    final sameCountryCode = first.number.countryCode == second.number.countryCode;
    if (sameCountryCode &&
        _isNationalNumberSuffixOfTheOther(first.number, second.number)) {
      return MatchType.shortNsnMatch;
    }

    if (!first.hadExplicitCountryContext ||
        !second.hadExplicitCountryContext) {
      if (first.number.nsn == second.number.nsn) {
        return MatchType.nsnMatch;
      }
      if (_isNationalNumberSuffixOfTheOther(first.number, second.number)) {
        return MatchType.shortNsnMatch;
      }
    }

    return MatchType.noMatch;
  }

  //
  //  inequalities
  //

  static PhoneNumberRange getRange(PhoneNumber start, PhoneNumber end) =>
      PhoneNumberRange(start, end);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is PhoneNumber && other.nsn == nsn && other.isoCode == isoCode;
  }

  @override
  int get hashCode => nsn.hashCode ^ isoCode.hashCode;

  ///  numerically add [operand] to this phone number
  /// e.g.
  /// ```dart
  /// PhoneParser.parseRaw('61383208100') + 1 == PhoneParser.parseRaw('61383208101');
  /// ```
  PhoneNumber operator +(int operand) {
    final nsnLength = nsn.length;
    final resultNsn = BigInt.parse(nsn) + BigInt.from(operand);
    return PhoneNumber(
      isoCode: isoCode,
      nsn: resultNsn.toString().padLeft(nsnLength, '0'),
    );
  }

  /// numerically subtract [operand] from this phone number
  /// e.g.
  /// ```dart
  /// PhoneParser.parseRaw('61383208100') - 1 == PhoneParser.parseRaw('61383208099');
  /// ```
  PhoneNumber operator -(int operand) {
    final nsnLength = nsn.length;
    final resultNsn = BigInt.parse(nsn) - BigInt.from(operand);
    return PhoneNumber(
      isoCode: isoCode,
      nsn: resultNsn.toString().padLeft(nsnLength, '0'),
    );
  }

  /// Returns true if this phone number is numerically greater
  /// than [other]
  bool operator >(PhoneNumber other) {
    var selfAsNum = BigInt.parse(international);
    var otherAsNum = BigInt.parse(other.international);

    return (selfAsNum - otherAsNum).toInt() > 0;
  }

  /// Returns true if this phone number is numerically greater
  /// than or equal to [other]
  bool operator >=(PhoneNumber other) {
    return this == other || this > other;
  }

  /// Returns true if this phone number is numerically less
  /// than [other]
  bool operator <(PhoneNumber rhs) {
    return !(this >= rhs);
  }

  /// Returns true if this phone number is numerically less
  /// than or equal to [other]
  bool operator <=(PhoneNumber rhs) {
    return this < rhs || (this == rhs);
  }

  /// We consider the PhoneNumber to be adjacent to the this PhoneNumber if it is one less or one greater than this
  ///  phone number.
  bool isAdjacentTo(PhoneNumber other) {
    return ((this + 1) == other) || ((this - 1) == other);
  }

  /// Returns true if [nextNumber] is the next number (numerically) after this number
  /// ```dart
  /// PhoneParser.parseRaw('61383208100').isSequentialTo( PhoneParser.parseRaw('61383208101')) == true;
  /// ```
  bool isSequentialTo(PhoneNumber nextNumber) {
    return ((this + 1) == nextNumber);
  }

  @override
  String toString() =>
      'PhoneNumber(isoCode: $isoCode, countryCode: $countryCode, nsn: $nsn)';

  Map<String, dynamic> toJson() {
    return {'isoCode': isoCode, 'nsn': nsn};
  }

  factory PhoneNumber.fromJson(Map<String, dynamic> map) {
    return PhoneNumber(
      isoCode: map['isoCode'],
      nsn: map['nsn'] ?? '',
    );
  }

  static String _exampleKeyForType(PhoneNumberType type) {
    switch (type) {
      case PhoneNumberType.fixedLine:
      case PhoneNumberType.fixedLineOrMobile:
        return 'fixedLine';
      case PhoneNumberType.mobile:
        return 'mobile';
      case PhoneNumberType.voip:
        return 'voip';
      case PhoneNumberType.tollFree:
        return 'tollFree';
      case PhoneNumberType.premiumRate:
        return 'premiumRate';
      case PhoneNumberType.sharedCost:
        return 'sharedCost';
      case PhoneNumberType.personalNumber:
        return 'personalNumber';
      case PhoneNumberType.uan:
        return 'uan';
      case PhoneNumberType.pager:
        return 'pager';
      case PhoneNumberType.voiceMail:
        return 'voiceMail';
      case PhoneNumberType.unknown:
        return 'general';
    }
  }

  static _ComparablePhoneNumber? _coerceToComparableNumber(
    Object input, {
    PhoneNumber? counterpart,
  }) {
    if (input is PhoneNumber) {
      return _ComparablePhoneNumber(
        number: input,
        hadExplicitCountryContext: true,
      );
    }
    if (input is! String) {
      return null;
    }

    final normalized = TextParser.normalizePhoneNumber(input);
    if (normalized.isEmpty) {
      return null;
    }

    final hasExplicitCountryContext =
        normalized.startsWith('+') ||
        normalized.startsWith('00') ||
        normalized.startsWith('011');

    try {
      if (hasExplicitCountryContext) {
        return _ComparablePhoneNumber(
          number: PhoneNumber.parse(input),
          hadExplicitCountryContext: true,
        );
      }

      if (counterpart != null) {
        return _ComparablePhoneNumber(
          number: PhoneNumber.parse(input, destinationCountry: counterpart.isoCode),
          hadExplicitCountryContext: false,
        );
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  static bool _isNationalNumberSuffixOfTheOther(
    PhoneNumber firstNumber,
    PhoneNumber secondNumber,
  ) {
    return firstNumber.nsn.endsWith(secondNumber.nsn) ||
        secondNumber.nsn.endsWith(firstNumber.nsn);
  }
}

class _ComparablePhoneNumber {
  final PhoneNumber number;
  final bool hadExplicitCountryContext;

  const _ComparablePhoneNumber({
    required this.number,
    required this.hadExplicitCountryContext,
  });
}
