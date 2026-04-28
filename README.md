# 📞 Phone Parser

[![Pub Version](https://img.shields.io/pub/v/phone_parser.svg)](https://pub.dev/packages/phone_parser)
[![License](https://img.shields.io/github/license/sumitsharansatsangi/phone_parser.svg)](LICENSE)
[![GitHub stars](https://img.shields.io/github/stars/sumitsharansatsangi/phone_parser.svg?style=social)](https://github.com/sumitsharansatsangi/phone_parser)

A Dart library for parsing, validating, and formatting phone numbers — **powered by merged metadata from Google’s libphonenumber and Apple’s PhoneNumberKit**.

Unlike traditional phone number libraries where you wait for maintainers to publish updates, **`phone_parser` auto-syncs** its metadata directly from upstream sources.
That means your project can refresh from Google’s libphonenumber and Apple’s PhoneNumberKit together — using Google as the primary source and filling missing values from Apple when available.

✨ Whether you’re building a shiny new Flutter app or running a Dart backend server, `phone_parser` is **smart, reliable, and always up-to-date**.

So you can focus on building while `phone_parser` takes care of keeping things current. 💡

---

## 🚀 Why `phone_parser`?

Google’s libphonenumber is fantastic, but:

* ❌ It isn’t natively available for all platforms.
* ❌ You often need channels or bindings to use it.
* ❌ Updates depend on maintainers.

✅ `phone_parser` solves this:

* Works across **all Dart platforms** (Flutter, backend, CLI).
* Ships with **auto-synced metadata** merged from Google’s libphonenumber and Apple PhoneNumberKit.
* A fork of [`phone_numbers_parser`](https://pub.dev/packages/phone_numbers_parser) with seamless updates built-in.

---

## ✨ Features

* ✅ **Validation** — Check if a number is valid, by type (mobile, fixed line, VoIP, etc.)
* ✅ **Formatting** — Format numbers region-specifically
* ✅ **Phone Ranges** — Expand or compare ranges of numbers
* ✅ **Number Extraction** — Find phone numbers in plain text
* ✅ **As-you-type formatting** — Format user input live as each digit is entered
* ✅ **Geocoding** — Resolve a parsed number to its territory or country
* ✅ **Eastern Arabic digits support**
* ✅ **Best-in-class metadata** — Google-first metadata with Apple filling gaps

---

## 🔍 Demo

Try it out: [Live Demo](https://cedvdb.github.io/phone_numbers_parser/)

---

## 📦 Installation

```yaml
dependencies:
  phone_parser: ^latest
```

---

## 📂 Platform Setup: Download & Save Metadata

`phone_parser` downloads metadata and saves it locally before parsing numbers. By default it fetches Google’s libphonenumber and Apple’s PhoneNumberKit metadata, then merges them into one parsed file.

The package also ships with a generated bundled metadata snapshot. If runtime download fails on first launch because the device is offline or upstream is temporarily unavailable, `phone_parser` falls back to that packaged snapshot instead of leaving metadata empty.

Merge behavior:

* Google values are kept when present
* Apple values are used only when Google is missing a value
* If Apple is missing a value, the Google value remains

Fallback behavior:

* A generated bundled metadata snapshot is packaged with the library
* This fallback does not rely on reading a bundled JSON file from disk at runtime
* It works as a safety net when a fresh metadata download is not possible

Load order:

* Use the freshest downloaded local metadata when available
* Refresh from upstream based on the package refresh policy
* Fall back to the generated bundled metadata snapshot if download or cache loading fails

On every platform you need two things:

* Outbound network access to download the metadata
* Write access to the directory where the metadata file will be stored

### Recommended directory

The app decides where the downloaded metadata is stored. The safest default is an app-specific, user-scoped directory managed by the OS. That keeps the file inside the app's own storage area, avoids writing into shared public folders, and usually does not require any extra storage permission.

For Flutter apps, prefer [`path_provider`](https://pub.dev/packages/path_provider) and store the metadata in your app support directory:

```dart
import 'package:path_provider/path_provider.dart';

final dir = await getApplicationSupportDirectory();
await MetadataFinder.readMetadataJson(dir.path);
```

That maps to a user-restricted app area on each platform:

* Android: app-specific internal storage
* iOS: app sandbox `Application Support`
* macOS: app sandbox or user `Application Support`
* Windows: user `AppData`
* Linux: user data directory such as `~/.local/share/<app>`

If you want to force a specific upstream source instead of using the default merged behavior:

```dart
await MetadataFinder.readMetadataJson(
  dir.path,
  sources: const [MetadataSource.applePhoneNumberKit],
);
```

For Dart CLI or server apps, `./` or another writable app-managed directory is usually fine.

Avoid public locations such as Downloads, Documents, shared external storage, or install directories unless your app explicitly wants user-visible files. Those locations are more likely to need extra permissions, user prompts, or platform-specific handling.

### Android

* Add internet access to `android/app/src/main/AndroidManifest.xml`:
  ```xml
  <uses-permission android:name="android.permission.INTERNET" />
  ```
* Save metadata in the app-specific directory returned by `getApplicationSupportDirectory()`.
* Avoid `WRITE_EXTERNAL_STORAGE` and avoid shared external folders unless you intentionally want the file outside the app sandbox.
* If you use `path_provider` and write into the app sandbox, no extra storage permission is usually required.

### iOS

* No extra network entitlement is typically required for standard HTTPS requests.
* Save metadata in the app sandbox, preferably `getApplicationSupportDirectory()`.
* This keeps the file in a user-scoped location owned by the app and does not require extra file access permission.
* If you customize App Transport Security and block standard HTTPS traffic, downloads may fail.

### macOS

* If your Flutter macOS app uses the app sandbox, you must allow outbound network access.
* Add this entitlement to both `macos/Runner/DebugProfile.entitlements` and `macos/Runner/Release.entitlements`:
  ```xml
  <key>com.apple.security.network.client</key>
  <true/>
  ```
* Without it, metadata download can fail with errors like:
  ```text
  SocketException: Connection failed (OS Error: Operation not permitted)
  ```
* Save metadata in `getApplicationSupportDirectory()` so it stays in a user-scoped app data location and does not need broader filesystem permission.
* Your app also needs write access to the directory you pass to `MetadataFinder.readMetadataJson(...)`.

### Windows

* No special entitlement is usually required for outbound HTTPS requests.
* Save metadata in a user-writable app data directory such as the path from `getApplicationSupportDirectory()`.
* Avoid writing beside the executable or inside `Program Files`, because those are protected install locations.

### Linux

* No special package-level permission is usually required for outbound HTTPS requests.
* Save metadata in a user data directory such as the path from `getApplicationSupportDirectory()`.
* Avoid system directories or package install directories.
* If you distribute the app through a sandboxed system such as Snap or Flatpak, you may need to grant filesystem or network access in that packaging configuration.

### Flutter Web

* Browsers do not let Flutter web apps write arbitrary files to local disk.
* The current metadata download flow is therefore not suitable for web as-is.
* For web, bundle pre-generated metadata with your app or serve it from your backend.

### Dart CLI / Server

* The process needs outbound internet access and write access to the target directory.
* In locked-down environments such as CI, containers, or serverless platforms, make sure egress to `raw.githubusercontent.com` is allowed.

### Common issues

* `SocketException: Connection failed (OS Error: Operation not permitted)` usually means the app is sandboxed and missing network permission.
* `SocketException: Failed host lookup` usually points to DNS or general network connectivity problems.
* Download succeeds but parsing still fails: make sure metadata was loaded before calling `PhoneNumber.parse(...)`.

---

## 🛠 Usage

Start with the `PhoneNumber` class:

```dart
import 'package:phone_parser/phone_parser.dart';

void main() async {
  // Load metadata before parsing numbers
  await MetadataFinder.readMetadataJson("./");

  final frPhone0 = PhoneNumber.parse('+33 655 5705 76');

  // Parsing in different contexts
  final frPhone1 = PhoneNumber.parse('0 655 5705 76', callerCountry: "FR");
  final frPhone2 = PhoneNumber.parse('011 33 655-5705-76', callerCountry: "US");
  final frPhone3 = PhoneNumber.parse('011 33 655 5705 76', destinationCountry: "FR");

  final isAllEqual = frPhone0 == frPhone1 && frPhone0 == frPhone2 && frPhone0 == frPhone3;
  print(frPhone1);
  print('All representations equal: $isAllEqual');

  // ✅ Validation
  print('valid: ${frPhone1.isValid()}'); 
  print('valid mobile: ${frPhone1.isValid(type: PhoneNumberType.mobile)}');
  print('valid fixed line: ${frPhone1.isValid(type: PhoneNumberType.fixedLine)}');

  // ✅ Extract numbers from text
  final text = 'hey my number is: +33 939 876 218, or call me on +33 939 876 999';
  final found = PhoneNumber.findPotentialPhoneNumbers(text);
  print('Found: $found');
}
```

---

## ✅ Validation

```dart
final valid = phone.isValid();
final validMobile = phone.isValid(type: PhoneNumberType.mobile);
final validFixed = phone.isValid(type: PhoneNumberType.fixedLine);
final detectedType = phone.getNumberType();
final isKnownType = detectedType != PhoneNumberType.unknown;
final validForRegion = phone.isValidForRegion('FR');
final match = PhoneNumber.isNumberMatch(
  '+33 655 5705 76',
  PhoneNumber.parse('0 655 5705 76', callerCountry: 'FR'),
);
final supportedRegions = MetadataFinder.supportedRegions;
final supportedCallingCodes = MetadataFinder.supportedCallingCodes;
final mainNanpaRegion = MetadataFinder.getRegionCodeForCountryCode('1');
final zaTypes = MetadataFinder.getSupportedTypesForRegion('ZA');
final region = PhoneNumber.parse('+1 268 460 1234').getRegionCode();
```

---

## 🎨 Formatting

Region-specific formatting that respects local conventions:

```dart
final phoneNumber = PhoneNumber.parse('2025550119', destinationCountry: 'US');
print(phoneNumber.formatNsn()); // (202) 555-0119
```

### As-you-type formatting

```dart
final formatter = PhoneNumber.getAsYouTypeFormatter('US');

for (final digit in '2025550119'.split('')) {
  print(formatter.inputDigit(digit));
}
// 2
// 20
// (202
// (202) 5
// ...
// (202) 555-0119
```

If you prefer a `dlibphonenumber`-style entry point, the same formatter is also available through `PhoneNumberUtil`:

```dart
final phoneUtil = PhoneNumberUtil.instance;
final formatter = phoneUtil.getAsYouTypeFormatter('US');
```

### Geocoding

```dart
final phone = PhoneNumber.parse('+33 655 5705 76');
final description = phone.getDescription();
print(description); // France

final phoneUtil = PhoneNumberUtil.instance;
print(phoneUtil.getDescriptionForNumber(phone, Locale.english)); // France
```

---

## 💡 Example Numbers

```dart
final example = PhoneNumber.getExampleNumber('ZA');
final mobileExample = PhoneNumber.getExampleNumberForType(
  isoCode: 'ZA',
  type: PhoneNumberType.mobile,
);
```

---

## 🔢 Ranges

Work with phone numbers like numbers:

```dart
final first = PhoneNumber.parse('+33 655 5705 00');
final last = PhoneNumber.parse('+33 655 5705 03');

final range = PhoneNumber.getRange(first, last);
print('Count: ${range.count}');
print('Expanded: ${range.expandRange()}');

final one = PhoneNumber.parse('+33 655 5705 01');
final two = PhoneNumber.parse('+33 655 5705 02');

if (one.isAdjacentTo(two)) print('We are adjacent');
if (one.isSequentialTo(two)) print('$two comes after $one');

final three = two + 1;
print('Still a phone number: $three'); // +33 655 5705 03
```

---

## 🤝 Contributing

Contributions are welcome! 🎉
If you’d like to improve `phone_parser`:

1. Fork the repo
2. Create a new branch: `git checkout -b feature/my-feature`
3. Commit your changes: `git commit -m 'Add my feature'`
4. Push to the branch: `git push origin feature/my-feature`
5. Open a Pull Request 🚀

---

## 📜 License

This project is licensed under the [MIT License](LICENSE).

---

💡 **Summary:**

* 🌍 Works everywhere (Flutter, CLI, Server)
* ⚡ Auto-syncs with Google’s libphonenumber
* 🔒 Reliable, consistent, always up-to-date

---
## 👨‍💻 Author

[![Sumit Kumar](https://github.com/sumitsharansatsangi.png?size=100)](https://github.com/sumitsharansatsangi)  
**[Sumit Kumar](https://github.com/sumitsharansatsangi)**  
