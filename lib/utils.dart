import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

void copyFile(String sourcePath, String destinationPath) async {
  try {
    // Create a File instance for the source file
    final sourceFile = File(sourcePath);

    // Copy the file to the destination path
    final newFile = await sourceFile.copy(destinationPath);

    if (kDebugMode) {
      print('File copied to: ${newFile.path}');
    }
  } catch (e) {
    if (kDebugMode) {
      print('Error copying file: $e');
    }
  }
}

String formatDateTime1(DateTime dateTime) {
  return DateFormat('MM/dd/yy HH:mm').format(dateTime);
}

String formatDuration1(Duration duration) {
  int minutes = duration.inMinutes;
  int seconds = duration.inSeconds.remainder(60);

  return '$minutes:${seconds.toString().padLeft(2, '0')}';
}

class FilePickerInfo {
  String? targetPath;
  String? fileName;

  FilePickerInfo({this.targetPath, this.fileName});
}

Future<FilePickerInfo> filePicker1() async {
  final file = await FilePicker.platform.pickFiles();
  if (file != null) {
    final sourceFile = file.files.single.path;
    final fileName = p.basename(sourceFile!);
    final docsDir = await getApplicationDocumentsDirectory();
    final targetPath = p.join(docsDir.path, fileName);
    copyFile(sourceFile, targetPath);
    return FilePickerInfo(
      targetPath: targetPath,
      fileName: fileName,
    );
  }
  return FilePickerInfo();
}

String calculateFileChecksum(String filePath) {
  final file = File(filePath);
  final bytes = file.readAsBytesSync();
  final checksum = FNV1aHasher().hash(bytes);
  return checksum.toRadixString(16);
}

class FNV1aHasher {
  var _hash = 2166136261; // FNV-1a initial hash value

  int hash(List<int> bytes) {
    for (var byte in bytes) {
      _hash = (_hash ^ byte) & 0xFFFFFFFF;
      _hash = (_hash * 16777219) & 0xFFFFFFFF;
    }
    return _hash;
  }
}
