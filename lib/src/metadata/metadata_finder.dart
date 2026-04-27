import 'dart:convert';
import 'dart:io';

import 'package:phone_parser/src/download_file/download_file.dart';
import 'package:phone_parser/src/metadata/bundled_metadata.g.dart';

import '../parsers/phone_number_exceptions.dart';
import '../validation/phone_number_type.dart';
import '../validation/validator.dart';

/// Helper to find metadata
abstract class MetadataFinder {
  static const List<PhoneNumberType> _supportedRegionTypes = [
    PhoneNumberType.fixedLine,
    PhoneNumberType.mobile,
    PhoneNumberType.voip,
    PhoneNumberType.tollFree,
    PhoneNumberType.premiumRate,
    PhoneNumberType.sharedCost,
    PhoneNumberType.personalNumber,
    PhoneNumberType.uan,
    PhoneNumberType.pager,
    PhoneNumberType.voiceMail,
  ];

  static Map<String, dynamic> info = {};

  /// Loads and caches parsed metadata for all supported regions.
  ///
  /// By default this downloads metadata from Google libphonenumber and Apple
  /// PhoneNumberKit, then merges them into one parsed dataset.
  static Future<void> readMetadataJson(
    String downloadDir, {
    List<MetadataSource> sources = const [
      MetadataSource.googleLibphonenumber,
      MetadataSource.applePhoneNumberKit,
    ],
  }) async {
    String? filePath = await downloadMetadata(downloadDir, sources: sources);
    if (filePath != null && await _loadMetadataFile(filePath)) {
      return;
    }

    if (_loadBundledMetadata()) {
      print("📦 Using bundled metadata snapshot packaged with phone_parser");
      return;
    }

    throw StateError(
      'Unable to load phone metadata from either downloaded cache or bundled fallback.',
    );
  }

  static Map<String, Map<String, dynamic>> getMetadata() {
    return info.map(
      (key, value) => MapEntry(
        key.toUpperCase(),
        {
          "isoCode": value["isoCode"],
          "countryCode": value['countryCode'],
          "internationalPrefix": value['internationalPrefix'],
          "nationalPrefix": value['nationalPrefix'],
          "leadingDigits": value['leadingDigits'],
          "isMainCountryForDialCode": value['isMainCountryForDialCode'],
        },
      ),
    );
  }

  /// expects a normalized iso code
  static Map<String, dynamic> findMetadataForIsoCode(String isoCode) {
    final map = info[isoCode];
    if (map == null) {
      throw PhoneNumberException(
        code: Code.invalidIsoCode,
        description: '$isoCode not found',
      );
    }
    return {
      "isoCode": map["isoCode"],
      "countryCode": map['countryCode'],
      "internationalPrefix": map['internationalPrefix'],
      "nationalPrefix": map['nationalPrefix'],
      "leadingDigits": map['leadingDigits'],
      "isMainCountryForDialCode": map['isMainCountryForDialCode'],
    };
  }

  /// expects a normalized iso code
  static Map<String, dynamic> findMetadataPatternsForIsoCode(String isoCode) {
    final map = info[isoCode]["patterns"];
    if (map == null) {
      throw PhoneNumberException(
        code: Code.invalidIsoCode,
        description: '$isoCode not found',
      );
    }
    return {
      "nationalPrefixForParsing": map['nationalPrefixForParsing'],
      "nationalPrefixTransformRule": map['nationalPrefixTransformRule'],
      "general": map['general'],
      "mobile": map['mobile'],
      "fixedLine": map['fixedLine'],
      "voip": map['voip'] ?? '',
      "tollFree": map['tollFree'] ?? '',
      "premiumRate": map['premiumRate'] ?? '',
      "sharedCost": map['sharedCost'] ?? '',
      "personalNumber": map['personalNumber'] ?? '',
      "uan": map['uan'] ?? '',
      "pager": map['pager'] ?? '',
      "voiceMail": map['voiceMail'] ?? '',
    };
  }

  static Map<String, List<int>> findMetadataLengthForIsoCode(String isoCode) {
    final map = info[isoCode]["lengths"];
    if (map == null) {
      throw PhoneNumberException(
        code: Code.invalidIsoCode,
        description: 'isoCode "$isoCode" not found',
      );
    }
    return {
      "general": (map['general'] ?? []).cast<int>(),
      "fixedLine": (map['fixedLine'] ?? []).cast<int>(),
      "mobile": (map['mobile'] ?? []).cast<int>(),
      "voip": (map['voip'] ?? []).cast<int>(),
      "tollFree": (map['tollFree'] ?? []).cast<int>(),
      "premiumRate": (map['premiumRate'] ?? []).cast<int>(),
      "sharedCost": (map['sharedCost'] ?? []).cast<int>(),
      "personalNumber": (map['personalNumber'] ?? []).cast<int>(),
      "uan": (map['uan'] ?? []).cast<int>(),
      "pager": (map['pager'] ?? []).cast<int>(),
      "voiceMail": (map['voiceMail'] ?? []).cast<int>(),
    };
  }

  static List findMetadataFormatsForIsoCode(String isoCode) {
    final map = info[isoCode]["formats"];
    if (map == null) {
      throw PhoneNumberException(
        code: Code.invalidIsoCode,
        description: 'isoCode "$isoCode" not found',
      );
    }
    // print(map.runtimeType);
    if (map is! List) {
      throw PhoneNumberException(
        code: Code.invalidIsoCode,
        description: 'isoCode "$isoCode" reference not a format list: $map',
      );
    }
    return map;
  }

  static List<String> get supportedRegions {
    final regions = info.keys.map((key) => key.toUpperCase()).toList()..sort();
    return regions;
  }

  static List<String> get supportedCallingCodes {
    final callingCodes = info.values
        .map((value) => value['countryCode']?.toString())
        .whereType<String>()
        .toSet()
        .toList()
      ..sort();
    return callingCodes;
  }

  static Map<String, String> findMetadataExamplesForIsoCode(String isoCode) {
    final map = info[isoCode]["examples"];
    if (map == null) {
      throw PhoneNumberException(
        code: Code.invalidIsoCode,
        description: 'isoCode "$isoCode" not found',
      );
    }
    return (map as Map<String, dynamic>).map(
      (key, value) => MapEntry(key, value.toString()),
    );
  }

  static Map<String, dynamic>? findMetadataForCountryCode(
    String countryCode,
    String nationalNumber,
  ) {
    final isoList = countryCodeToIsoCode(countryCode);

    if (isoList.isEmpty) {
      return null;
    }
    // country code can have multiple metadata because multiple iso code
    // share the same country code.
    final allMatchingMetadata =
        isoList.map((iso) => findMetadataForIsoCode(iso)).toList();

    final match = _getMatchUsingPatterns(nationalNumber, allMatchingMetadata);
    return match;
  }

  static String? getRegionCodeForCountryCode(String countryCode) {
    final regions = countryCodeToIsoCode(countryCode);
    if (regions.isEmpty) {
      return null;
    }
    return regions.first;
  }

  static String? getRegionCodeForNumber(
    String countryCode,
    String nationalNumber,
  ) {
    final regions = countryCodeToIsoCode(countryCode);
    if (regions.isEmpty) {
      return null;
    }
    if (regions.length == 1) {
      return regions.first;
    }

    for (final regionCode in regions) {
      final metadata = findMetadataForIsoCode(regionCode);
      final leadingDigits = metadata['leadingDigits']?.toString();
      if (leadingDigits != null && leadingDigits.isNotEmpty) {
        if (nationalNumber.startsWith(leadingDigits)) {
          return regionCode;
        }
        continue;
      }

      if (Validator.getNumberType(regionCode, nationalNumber) !=
          PhoneNumberType.unknown) {
        return regionCode;
      }
    }

    return null;
  }

  static List<String> getRegionCodesForCountryCode(String countryCode) {
    return countryCodeToIsoCode(countryCode);
  }

  static String? getCountryCodeForRegion(String isoCode) {
    try {
      final metadata = findMetadataForIsoCode(isoCode.toUpperCase());
      return metadata['countryCode']?.toString();
    } catch (_) {
      return null;
    }
  }

  static List<PhoneNumberType> getSupportedTypesForRegion(String isoCode) {
    final normalizedIsoCode = isoCode.toUpperCase();
    final patterns = findMetadataPatternsForIsoCode(normalizedIsoCode);

    return _supportedRegionTypes.where((type) {
      final pattern = _patternForType(patterns, type);
      return pattern.isNotEmpty;
    }).toList();
  }

  static List<String> countryCodeToIsoCode(String countryCode) {
    final allMetadatas = getMetadata();
    final isoCode = List<String>.empty(growable: true);
    for (var m in allMetadatas.values) {
      // final countryCode = m['countryCode'];
      if (countryCode == m['countryCode']) {
        final isMainCountry = m['isMainCountryForDialCode'];
        // we insert the main country at the start of the array so it's easy to find
        if (isMainCountry == true) {
          isoCode.insert(0, m['isoCode']);
        } else {
          isoCode.add(m['isoCode']);
        }
      }
    }
    return isoCode;
  }

  static Map<String, dynamic> _getMatchUsingPatterns(
    String nationalNumber,
    List<Map<String, dynamic>> potentialFits,
  ) {
    if (potentialFits.length == 1) return potentialFits[0];
    // if the phone number is valid for a metadata return that metadata
    for (var fit in potentialFits) {
      final isValidForIso = Validator.validateWithPattern(
        fit["isoCode"] ?? "IN",
        nationalNumber,
      );
      if (isValidForIso) {
        return fit;
      }
    }
    // otherwise the phone number starts with leading digits of metadata
    for (var fit in potentialFits) {
      final leadingDigits = fit["leadingDigits"];
      if (leadingDigits != null && nationalNumber.startsWith(leadingDigits)) {
        return fit;
      }
    }

    // best guess here
    return potentialFits.firstWhere(
      (fit) => fit["isMainCountryForDialCode"],
      orElse: () => potentialFits[0],
    );
  }

  static Future<bool> _loadMetadataFile(String filePath) async {
    try {
      final jsonString = await File(filePath).readAsString();
      return _loadMetadataJson(jsonString);
    } catch (e) {
      print("⚠️ Failed to load metadata from $filePath: $e");
      return false;
    }
  }

  static bool _loadBundledMetadata() {
    try {
      return _loadMetadataJson(bundledMetadataJson);
    } catch (e) {
      print("⚠️ Failed to load bundled metadata snapshot: $e");
      return false;
    }
  }

  static bool _loadMetadataJson(String jsonString) {
    info = jsonDecode(jsonString) as Map<String, dynamic>;
    return true;
  }

  static String _patternForType(
    Map<String, dynamic> patternMetadatas,
    PhoneNumberType type,
  ) {
    switch (type) {
      case PhoneNumberType.fixedLine:
        return patternMetadatas['fixedLine'] ?? '';
      case PhoneNumberType.mobile:
        return patternMetadatas['mobile'] ?? '';
      case PhoneNumberType.voip:
        return patternMetadatas['voip'] ?? '';
      case PhoneNumberType.tollFree:
        return patternMetadatas['tollFree'] ?? '';
      case PhoneNumberType.premiumRate:
        return patternMetadatas['premiumRate'] ?? '';
      case PhoneNumberType.sharedCost:
        return patternMetadatas['sharedCost'] ?? '';
      case PhoneNumberType.personalNumber:
        return patternMetadatas['personalNumber'] ?? '';
      case PhoneNumberType.uan:
        return patternMetadatas['uan'] ?? '';
      case PhoneNumberType.pager:
        return patternMetadatas['pager'] ?? '';
      case PhoneNumberType.voiceMail:
        return patternMetadatas['voiceMail'] ?? '';
      case PhoneNumberType.fixedLineOrMobile:
      case PhoneNumberType.unknown:
        return '';
    }
  }
}
