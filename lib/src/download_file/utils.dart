import 'dart:convert';
import 'dart:io';

import 'package:xml/xml.dart';

/// Validate file contents (JSON or XML)
Future<bool> isFileValid(File file) async {
  try {
    final content = await file.readAsString();

    if (file.path.endsWith(".json")) {
      jsonDecode(content); // throws if invalid
    } else if (file.path.endsWith(".xml")) {
      XmlDocument.parse(content); // throws if invalid
    } else {
      print("⚠️ Unknown file type: ${file.path}");
      return false;
    }
    return true; // ✅ valid
  } catch (_) {
    return false; // ❌ corrupted
  }
}

String changeExtensionToJson(String path) {
  if (path.toLowerCase().endsWith(".xml")) {
    return "${path.substring(0, path.length - 4)}.json";
  }
  return path; // unchanged if not .xml
}

String getOutputPath(String path) {
  if (path.toLowerCase().endsWith(".json")) {
    return "${path.substring(0, path.length - 5)}_parsed.json";
  }
  return path; // unchanged if not .xml
}
