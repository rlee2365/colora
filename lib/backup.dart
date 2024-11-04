import 'package:colora/core.dart';
import 'package:flutter_archive/flutter_archive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';

class ColoraBackup {
  final ColoraCore _core;

  ColoraBackup(this._core);

  Future<String> createBackup(String backupFilePath) async {
    final docsDir = await getApplicationDocumentsDirectory();
    final dbDirPath = p.join(docsDir.path, ColoraCore.dbDir);

    // Create a list of files to include in the backup
    final filesToBackup = [
      ..._core.projects.map((project) => File(project.appLocalFilePath)),
      ...Directory(dbDirPath).listSync().map((file) => File(file.path)),
    ];

    // Create the backup zip file
    await ZipFile.createFromFiles(
      sourceDir: docsDir,
      files: filesToBackup,
      zipFile: File(backupFilePath),
    );
    return backupFilePath;
  }

  Future<void> loadBackup(String backupFilePath) async {
    final docsDir = await getApplicationDocumentsDirectory();

    // Extract the backup zip file
    await ZipFile.extractToDirectory(
      zipFile: File(backupFilePath),
      destinationDir: docsDir,
    );

    // Reload the projects from the database
    await _core.setupObjectBox();
  }
}
