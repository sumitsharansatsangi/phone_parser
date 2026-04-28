import 'package:phone_parser/src/formatting/as_you_type_formatter.dart';
import 'package:phone_parser/src/formatting/phone_number_formatter.dart';
import 'package:phone_parser/src/geocoding/locale.dart';
import 'package:phone_parser/src/geocoding/phone_number_offline_geocoder.dart';
import 'package:phone_parser/src/phone_number.dart';
import 'package:phone_parser/src/validation/match_type.dart';
import 'package:phone_parser/src/validation/phone_number_type.dart';

/// Utility facade for callers who prefer a libphonenumber-style API surface.
class PhoneNumberUtil {
  PhoneNumberUtil._();

  static final PhoneNumberUtil instance = PhoneNumberUtil._();

  PhoneNumber parse(
    String phoneNumber, {
    String? callerCountry,
    String? destinationCountry,
  }) =>
      PhoneNumber.parse(
        phoneNumber,
        callerCountry: callerCountry,
        destinationCountry: destinationCountry,
      );

  String format(
    PhoneNumber phoneNumber, {
    String? isoCode,
    NsnFormat format = NsnFormat.national,
  }) =>
      phoneNumber.formatNsn(isoCode: isoCode, format: format);

  bool isValidNumber(PhoneNumber phoneNumber, {PhoneNumberType? type}) =>
      phoneNumber.isValid(type: type);

  bool isPossibleNumber(PhoneNumber phoneNumber, {PhoneNumberType? type}) =>
      phoneNumber.isValidLength(type: type);

  bool isValidNumberForRegion(
    PhoneNumber phoneNumber,
    String regionCode, {
    PhoneNumberType? type,
  }) =>
      phoneNumber.isValidForRegion(regionCode, type: type);

  PhoneNumberType getNumberType(PhoneNumber phoneNumber) =>
      phoneNumber.getNumberType();

  MatchType isNumberMatch(Object firstNumber, Object secondNumber) =>
      PhoneNumber.isNumberMatch(firstNumber, secondNumber);

  Iterable<PhoneNumber> findNumbers(String text) =>
      PhoneNumber.findPotentialPhoneNumbers(text);

  AsYouTypeFormatter getAsYouTypeFormatter(
    String isoCode, {
    NsnFormat format = NsnFormat.national,
  }) =>
      PhoneNumber.getAsYouTypeFormatter(isoCode, format: format);

  String getDescriptionForNumber(
    PhoneNumber phoneNumber,
    Locale locale, [
    String? userRegion,
  ]) =>
      PhoneNumberOfflineGeocoder.instance.getDescriptionForNumber(
        phoneNumber,
        locale,
        userRegion,
      );
}
