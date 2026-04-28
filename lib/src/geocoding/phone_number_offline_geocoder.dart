import 'package:phone_parser/src/geocoding/locale.dart';
import 'package:phone_parser/src/geocoding/region_display_names.dart';
import 'package:phone_parser/src/phone_number.dart';
import 'package:phone_parser/src/validation/phone_number_type.dart';

class PhoneNumberOfflineGeocoder {
  PhoneNumberOfflineGeocoder._();

  static final PhoneNumberOfflineGeocoder instance =
      PhoneNumberOfflineGeocoder._();

  String getDescriptionForNumber(
    PhoneNumber number,
    Locale locale, [
    String? userRegion,
  ]) {
    if (locale.language != 'en') {
      return '';
    }

    if (number.getNumberType() == PhoneNumberType.unknown) {
      return '';
    }

    final regionCode = number.getRegionCode();
    if (regionCode == null || regionCode == 'ZZ') {
      return '';
    }

    final normalizedUserRegion = userRegion?.toUpperCase();
    if (normalizedUserRegion != null && normalizedUserRegion == regionCode) {
      return '';
    }

    return englishRegionDisplayNames[regionCode] ?? regionCode;
  }
}
