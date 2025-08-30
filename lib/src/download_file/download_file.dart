import 'dart:io';

import 'package:phone_parser/src/download_file/convert_metadata.dart';
import 'package:phone_parser/src/download_file/utils.dart';
import 'package:phone_parser/src/download_file/xml_to_json.dart';

Future<String?> downloadMetadata(String dirPath) async {
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
    final lastTimestamp = int.tryParse(
      latestFile.uri.pathSegments.last.split('.').first,
    );
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
    final filePath = await downloadFile(downloadDir,
        "https://raw.githubusercontent.com/google/libphonenumber/master/resources/PhoneNumberMetadata.xml");
    if (filePath != null) {
      await latestFile?.delete();
      return filePath;
    } else {
      return latestFile?.path;
    }
  } else {
    print("📂 Latest file is valid and fresh enough.");
    return latestFile?.path;
  }
}

/// Download and save file with timestamp
Future<String?> downloadFile(Directory dir, String url) async {
  final now = DateTime.now();
  final ts = (now.millisecondsSinceEpoch / 1000).floor();
  final file = File("${dir.path}/${ts}_phone_number_metadata.xml");

  final client = HttpClient();
  try {
    final request = await client.getUrl(Uri.parse(url));
    final response = await request.close();

    if (response.statusCode == 200) {
      await response.pipe(file.openWrite());
      print("✅ File downloaded and saved as ${file.path}");
      // Verify immediately after download
      if (await isFileValid(file)) {
        print("✅ File is valid");
        final jsonFile = await convertXMLToJson(file.path);
        print("✅ File converted to json");
        // Delete the xml file
        await file.delete();
        return await convertPhoneNumberMetadata(jsonFile);
      } else {
        print("❌ Downloaded file appears corrupted!");
        return null;
      }
    } else {
      print("❌ Failed to download. Status: ${response.statusCode}");
      return null;
    }
  } catch (e) {
    print("⚠️ Download error: $e");
    return null;
  } finally {
    client.close();
  }
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
