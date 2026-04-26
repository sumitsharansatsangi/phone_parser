## 0.0.8
- Added merged metadata support using both Google libphonenumber and Apple PhoneNumberKit.
- Made Google the primary metadata source and fill missing values from Apple when available.
- Documented the merged metadata behavior and source-selection options in the README.
- Improved README platform setup guidance for Android, iOS, macOS, Windows, Linux, Flutter Web, and Dart CLI/Server.
- Documented the macOS `com.apple.security.network.client` entitlement required for metadata download in sandboxed Flutter desktop apps.
- Fixed README usage examples to match the current API, including `isValid()` and string ISO country codes such as `'US'`.
- Updated the example macOS app entitlements so metadata download works correctly.

## 0.0.7

 - Docs update

## 0.0.6

 - Updated Read Me

## 0.0.5

 - Updated Read Me

## 0.0.4

- Fixed unnecessary download issue

## 0.0.3

- Fixed metadata length parsing

## 0.0.2

- Exported MetadataFinder to public

## 0.0.1

- Initial version, forked from [phone__numbers_parser](https://pub.dev/packages/phone__numbers_parser/versions/9.0.11)
