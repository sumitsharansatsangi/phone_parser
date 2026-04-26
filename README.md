# 📞 Phone Parser

[![Pub Version](https://img.shields.io/pub/v/phone_parser.svg)](https://pub.dev/packages/phone_parser)
[![License](https://img.shields.io/github/license/sumitsharansatsangi/phone_parser.svg)](LICENSE)
[![GitHub stars](https://img.shields.io/github/stars/sumitsharansatsangi/phone_parser.svg?style=social)](https://github.com/sumitsharansatsangi/phone_parser)

A Dart library for parsing, validating, and formatting phone numbers — **always in sync with Google’s libphonenumber**.

Unlike traditional phone number libraries where you wait for maintainers to publish updates, **`phone_parser` auto-syncs** with Google’s libphonenumber.
That means whenever Google ships a new release, your project gets the latest intelligence instantly — no delays, no stale metadata, no headaches.

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
* Ships with **auto-synced metadata** from Google’s libphonenumber.
* A fork of [`phone_numbers_parser`](https://pub.dev/packages/phone_numbers_parser) with seamless updates built-in.

---

## ✨ Features

* ✅ **Validation** — Check if a number is valid, by type (mobile, fixed line, VoIP, etc.)
* ✅ **Formatting** — Format numbers region-specifically
* ✅ **Phone Ranges** — Expand or compare ranges of numbers
* ✅ **Number Extraction** — Find phone numbers in plain text
* ✅ **Eastern Arabic digits support**
* ✅ **Best-in-class metadata** — Always fresh from Google’s libphonenumber

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

## 📂 Platform Permissions: Download & Save Metadata

`phone_parser` auto-downloads and saves the latest phone number metadata from Google’s libphonenumber. Depending on your platform, you may need to grant permissions or configure your app to allow file downloads and writes:

### Flutter (Android & iOS)

- **Android:**
  - Add the following permission to your `android/app/src/main/AndroidManifest.xml`:
    ```xml
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
    ```
    For Android 10+ (API 29+), use app-specific storage or [request legacy storage](https://developer.android.com/training/data-storage/use-cases).
- **iOS:**
  - No extra permissions are needed for app sandbox. Make sure you use app directories (e.g., via `path_provider`).

### Flutter (Web)

- Web apps **cannot download or save files to disk** due to browser sandboxing. You must bundle the metadata JSON with your app or fetch it from a server endpoint.

### Dart CLI / Server

- No special permissions are needed. The process must have write access to the target directory (e.g., `./`).

### Desktop (macOS, Windows, Linux)

- No extra permissions are needed, but the app must have write access to the chosen directory.

**Tip:** For cross-platform compatibility, use [`path_provider`](https://pub.dev/packages/path_provider) to get a writable directory:

```dart
import 'package:path_provider/path_provider.dart';
final dir = await getApplicationSupportDirectory();
await MetadataFinder.readMetadataJson(dir.path);
```
This ensures your app can always download and save metadata safely on mobile and desktop platforms.

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
final valid = phone.validate();
final validMobile = phone.validate(type: PhoneNumberType.mobile);
final validFixed = phone.validate(type: PhoneNumberType.fixedLine);
```

---

## 🎨 Formatting

Region-specific formatting that respects local conventions:

```dart
final phoneNumber = PhoneNumber.parse('2025550119', destinationCountry: IsoCode.US);
print(phoneNumber.formatNsn()); // (202) 555-0119
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