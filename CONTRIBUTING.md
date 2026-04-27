# Contributing

Thanks for contributing to `phone_parser`.

## Updating Bundled Metadata

`phone_parser` ships with a generated bundled metadata snapshot as a fallback when runtime download is unavailable. Before publishing a release that should include newer upstream metadata, regenerate that snapshot from the latest Google libphonenumber and Apple PhoneNumberKit sources:

```bash
dart run tool/update_bundled_metadata.dart
```

This command:

- downloads the latest upstream metadata using the package's existing merge pipeline
- regenerates `lib/src/metadata/bundled_metadata.g.dart`
- updates the bundled fallback used when cache refresh or first-run download fails

Recommended release flow:

1. Run `dart run tool/update_bundled_metadata.dart`
2. Review the generated changes in `lib/src/metadata/bundled_metadata.g.dart`
3. Update versioning and changelog entries as needed
4. Run your usual validation checks
5. Commit the regenerated snapshot along with the release changes

## Notes

- Do not edit `lib/src/metadata/bundled_metadata.g.dart` by hand. It is generated.
- If the update command fails, check network access to the upstream metadata sources on `raw.githubusercontent.com`.
