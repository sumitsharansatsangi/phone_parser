import 'dart:isolate';
import 'dart:io';

import 'package:phone_parser/src/download_file/download_file.dart';
import 'package:phone_parser/src/metadata/bundled_metadata.dart';

Future<void> main() async {
  final outputFile = await _resolveBundledMetadataFile();
  final outputDir = outputFile.parent;

  if (!await outputDir.exists()) {
    await outputDir.create(recursive: true);
  }

  final tempDir = await Directory.systemTemp.createTemp(
    'phone_parser_metadata_',
  );

  try {
    final downloadedPath = await downloadMetadata(tempDir.path);
    if (downloadedPath == null) {
      stderr.writeln(
        'Failed to download metadata. Bundled snapshot was not updated.',
      );
      exitCode = 1;
      return;
    }

    await File(downloadedPath).copy(outputFile.path);
    stdout.writeln('Bundled metadata snapshot updated at ${outputFile.path}');
  } finally {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  }
}

Future<File> _resolveBundledMetadataFile() async {
  final bundledUri = await Isolate.resolvePackageUri(
    Uri.parse(bundledMetadataPackagePath),
  );

  if (bundledUri != null && bundledUri.scheme == 'file') {
    return File.fromUri(bundledUri);
  }

  final scriptDir = File.fromUri(Platform.script).parent;
  final repoRoot = scriptDir.parent;
  return File.fromUri(
    repoRoot.uri.resolve(
      'lib/src/metadata/bundled/phone_number_metadata_parsed.json',
    ),
  );
}
