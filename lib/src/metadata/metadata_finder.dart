import 'dart:convert';
import 'dart:io';

import 'package:phone_parser/src/download_file/download_file.dart';

import '../parsers/phone_number_exceptions.dart';
import '../validation/validator.dart';

/// Helper to find metadata
abstract class MetadataFinder {
  static Map<String, dynamic> info = {};

  /// reads the json file of country names which is an array of country information
  static Future<void> readMetadataJson(String downloadDir) async {
    // final filePath = '/Users/amitsharan/phone_parser/resources/data_sources/parsed_phone_number_metadata.json';
    String? filePath = await downloadMetadata(downloadDir);
    if (filePath != null) {
      final jsonString = await File(filePath).readAsString();
      info = jsonDecode(jsonString);
    }
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
      "general": (map['general']??[]).cast<int>(),
      "fixedLine": (map['fixedLine']??[]).cast<int>(),
      "mobile": (map['mobile']??[]).cast<int>(),
      "voip": (map['voip']??[]).cast<int>(),
      "tollFree": (map['tollFree']??[]).cast<int>(),
      "premiumRate": (map['premiumRate']??[]).cast<int>(),
      "sharedCost": (map['sharedCost']??[]).cast<int>(),
      "personalNumber": (map['personalNumber']??[]).cast<int>(),
      "uan": (map['uan']??[]).cast<int>(),
      "pager": (map['pager']??[]).cast<int>(),
      "voiceMail": (map['voiceMail']??[]).cast<int>(),
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
}
