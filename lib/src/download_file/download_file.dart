import 'dart:convert';
import 'dart:io';

import 'package:phone_parser/src/download_file/convert_metadata.dart';
import 'package:phone_parser/src/download_file/utils.dart';
import 'package:phone_parser/src/download_file/xml_to_json.dart';

enum MetadataSource {
  googleLibphonenumber,
  applePhoneNumberKit,
}

const _defaultMetadataSources = [
  MetadataSource.googleLibphonenumber,
  MetadataSource.applePhoneNumberKit,
];

const _mergedMetadataFilename = "phone_number_metadata_parsed.json";

Future<String?> downloadMetadata(
  String dirPath, {
  List<MetadataSource> sources = _defaultMetadataSources,
}) async {
  final downloadDir = Directory(dirPath);

  if (!await downloadDir.exists()) {
    await downloadDir.create(recursive: true);
  }

  final now = DateTime.now();
  final latestFile = await getLatestFile(downloadDir);
  bool shouldDownload = false;

  if (latestFile == null) {
    // ✅ No file exists → must download
    shouldDownload = true;
  } else {
    final filename = latestFile.uri.pathSegments.last.split('.').first;
    final lastTimestamp = int.tryParse(filename.split('_').first);
    final lastDownloadDate =
        DateTime.fromMillisecondsSinceEpoch((lastTimestamp ?? 0) * 1000);
    final diff = now.difference(lastDownloadDate).inDays;

    // Rule 1: Today is Friday
    if (now.weekday == DateTime.friday) {
      shouldDownload = true;
    }

    // Rule 2: Last download older than 7 days
    if (diff > 7) {
      shouldDownload = true;
    }

    // Rule 3: File corrupted
    if (!(await isFileValid(latestFile))) {
      print("⚠️ Latest file is corrupted → re-downloading...");
      shouldDownload = true;
    }
  }

  if (shouldDownload) {
    final mergedPath = await _downloadAndMergeMetadata(downloadDir, sources);
    if (mergedPath != null) {
      await latestFile?.delete();
      return mergedPath;
    }
    return latestFile?.path;
  } else {
    print("📂 Latest file is valid and fresh enough.");
    return latestFile?.path;
  }
}

Future<String?> _downloadAndMergeMetadata(
  Directory dir,
  List<MetadataSource> sources,
) async {
  final mergedMetadata = <String, dynamic>{};

  for (final source in sources) {
    final metadata = await _downloadMetadataFromSource(dir, source: source);
    if (metadata == null) {
      print(
          "⚠️ Failed to refresh merged metadata because $source could not be loaded.");
      return null;
    }
    _mergeMetadata(mergedMetadata, metadata);
  }

  final now = DateTime.now();
  final ts = (now.millisecondsSinceEpoch / 1000).floor();
  final output = File("${dir.path}/${ts}_$_mergedMetadataFilename");
  await output.writeAsString(jsonEncode(mergedMetadata));

  if (await isFileValid(output)) {
    print("✅ Merged metadata saved as ${output.path}");
    return output.path;
  }

  print("❌ Merged metadata file appears corrupted!");
  return null;
}

Future<Map<String, dynamic>?> _downloadMetadataFromSource(
  Directory dir, {
  required MetadataSource source,
}) async {
  switch (source) {
    case MetadataSource.googleLibphonenumber:
      return _downloadAndConvertMetadata(
        dir,
        url:
            "https://raw.githubusercontent.com/google/libphonenumber/master/resources/PhoneNumberMetadata.xml",
        extension: "xml",
        sourceName: "Google libphonenumber",
        fileStem: "google_phone_number_metadata",
        converter: (file) async {
          final jsonFile = await convertXMLToJson(file.path);
          print("✅ Google metadata converted to json");
          await file.delete();
          return convertPhoneNumberMetadata(jsonFile);
        },
      );
    case MetadataSource.applePhoneNumberKit:
      return _downloadAndConvertMetadata(
        dir,
        url:
            "https://raw.githubusercontent.com/marmelroy/PhoneNumberKit/refs/heads/master/PhoneNumberKit/Resources/PhoneNumberMetadata.json",
        extension: "json",
        sourceName: "Apple PhoneNumberKit",
        fileStem: "apple_phone_number_metadata",
        converter: convertPhoneNumberMetadata,
      );
  }
}

/// Download, convert, and load one metadata source.
Future<Map<String, dynamic>?> _downloadAndConvertMetadata(
  Directory dir, {
  required String url,
  required String extension,
  required String sourceName,
  required String fileStem,
  required Future<String?> Function(File file) converter,
}) async {
  final now = DateTime.now();
  final ts = (now.millisecondsSinceEpoch / 1000).floor();
  final file = File("${dir.path}/${ts}_$fileStem.$extension");
  final client = HttpClient();
  try {
    final request = await client.getUrl(Uri.parse(url));
    final response = await request.close();

    if (response.statusCode == 200) {
      await response.pipe(file.openWrite());
      print("✅ $sourceName metadata downloaded and saved as ${file.path}");
      // Verify immediately after download
      if (await isFileValid(file)) {
        print("✅ $sourceName metadata file is valid");
        final parsedFilePath = await converter(file);
        if (parsedFilePath == null) {
          return null;
        }

        final parsedFile = File(parsedFilePath);
        final jsonString = await parsedFile.readAsString();
        final metadata = jsonDecode(jsonString) as Map<String, dynamic>;
        await parsedFile.delete();
        return metadata;
      } else {
        print("❌ $sourceName metadata appears corrupted!");
        return null;
      }
    } else {
      print(
        "❌ Failed to download $sourceName metadata. Status: ${response.statusCode}",
      );
      return null;
    }
  } catch (e) {
    print("⚠️ $sourceName download error: $e");
    return null;
  } finally {
    client.close();
  }
}

void _mergeMetadata(
  Map<String, dynamic> base,
  Map<String, dynamic> incoming,
) {
  incoming.forEach((isoCode, value) {
    final incomingTerritory = Map<String, dynamic>.from(value as Map);
    final currentValue = base[isoCode];

    if (currentValue is Map<String, dynamic>) {
      base[isoCode] = _deepMergeMaps(currentValue, incomingTerritory);
    } else if (currentValue is Map) {
      base[isoCode] = _deepMergeMaps(
        Map<String, dynamic>.from(currentValue),
        incomingTerritory,
      );
    } else {
      base[isoCode] = incomingTerritory;
    }
  });
}

Map<String, dynamic> _deepMergeMaps(
  Map<String, dynamic> base,
  Map<String, dynamic> incoming,
) {
  final merged = Map<String, dynamic>.from(base);

  incoming.forEach((key, value) {
    final currentValue = merged[key];
    if (currentValue is Map && value is Map) {
      merged[key] = _deepMergeMaps(
        Map<String, dynamic>.from(currentValue),
        Map<String, dynamic>.from(value),
      );
    } else if (!merged.containsKey(key) || currentValue == null) {
      merged[key] = value;
    } else if (value == null) {
      merged.putIfAbsent(key, () => value);
    }
  });

  return merged;
}

/// Find latest file by timestamp in name
Future<File?> getLatestFile(Directory dir) async {
  File? latestFile;
  int? latestTimestamp;

  await for (var entity in dir.list()) {
    if (entity is File &&
        entity.path.endsWith("_phone_number_metadata_parsed.json")) {
      final name = entity.uri.pathSegments.last.split('.').first;
      final parts = name.split("_");
      if (parts.isNotEmpty) {
        final ts = int.tryParse(parts.first);
        if (ts != null) {
          if (latestTimestamp == null || ts > latestTimestamp) {
            latestTimestamp = ts;
            latestFile = entity;
          }
        }
      }
    }
  }
  return latestFile;
}
