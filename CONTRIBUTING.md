# Contributing

## MetaData
phone_numbers_parser is using metadata from [Google's libphonenumber](https://github.com/googlei18n/libphonenumber).
We try to keep the metadata of phone_numbers_parser up to date and making sure you are running on the latest release will be sufficient for most apps. However, you can also update the metadata youself by following these 3 steps:

1. Download and Process the Metadata
2. Generate the Dart files

## 1. Download and Process the Metadata

This will change the metadata to a format the library can understand easier

```
dart resources/data_sources/convert_metadata.dart
```

## 2. Generate Files

This is the final step to turn the Metadata into Dart Files.

```
dart pub get
dart resources/generate_files.dart && dart format lib/src && dart fix --apply
```