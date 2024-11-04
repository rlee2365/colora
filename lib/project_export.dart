import 'dart:io';
import 'package:colora/models.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path/path.dart' as p;

void showLyricsDialog(BuildContext context, Project project) {
  bool includeTimestamps = false;

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('export lyrics'),
        content: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return SizedBox(
              width: 500,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CheckboxListTile(
                    title: const Text("include timestamps"),
                    value: includeTimestamps,
                    onChanged: (bool? value) {
                      setState(() {
                        includeTimestamps = value ?? false;
                      });
                    },
                  ),
                  ElevatedButton(
                    onPressed: () {
                      final lyrics =
                          project.generateLyrics(timestamps: includeTimestamps);
                      Clipboard.setData(ClipboardData(text: lyrics));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('lyrics copied to clipboard')),
                      );
                    },
                    child: const Text('copy to clipboard'),
                  ),
                  // Becauase it's unlikely for us to get MANAGE_EXTERNAL_STORAGE permission
                  // We cannot save to external storage
                  // Add the "Share" button below the "Copy to Clipboard" button
                  ElevatedButton(
                    onPressed: () async {
                      final docsDir = await getApplicationDocumentsDirectory();
                      final targetPath =
                          p.join(docsDir.path, 'lyrics_${project.name}.txt');
                      final file = File(targetPath);
                      await file.writeAsString(project.generateLyrics(
                          timestamps: includeTimestamps));
                      await Share.shareXFiles([XFile(targetPath)]);
                    },
                    child: const Text('share as text file'),
                  ),
                ],
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Close'),
          ),
        ],
      );
    },
  );
}
