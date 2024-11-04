import 'dart:io';
import 'package:colora/models.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

void showLyricsDialog(BuildContext context, Project project) {
  bool includeTimestamps = false;

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Export Lyrics'),
        content: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return SizedBox(
              width: 500,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CheckboxListTile(
                    title: const Text("Include Timestamps"),
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
                            content: Text('Lyrics copied to clipboard')),
                      );
                    },
                    child: const Text('Copy to Clipboard'),
                  ),
                  // ElevatedButton(
                  //     onPressed: () async {
                  //       final status = await Permission.storage.request();
                  //       if (status == PermissionStatus.granted) {
                  //         final lyrics = project.generateLyrics(
                  //             timestamps: includeTimestamps);
                  //         String? outputFile =
                  //             await FilePicker.platform.saveFile(
                  //           dialogTitle: 'Save Lyrics File',
                  //           fileName: '${project.name}.txt',
                  //           type: FileType.any,
                  //         );
                  //         if (outputFile != null) {
                  //           final file = File(outputFile);
                  //           await file.writeAsString(lyrics);
                  //           ScaffoldMessenger.of(context).showSnackBar(
                  //             SnackBar(
                  //               content: Text('Lyrics saved to $outputFile'),
                  //             ),
                  //           );
                  //         }
                  //       } else {
                  //         ScaffoldMessenger.of(context).showSnackBar(
                  //           const SnackBar(
                  //               content: Text(
                  //                   'Storage permission is required to save the lyrics file')),
                  //         );
                  //       }
                  //     },
                  //     child: const Text('Save to File')),
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
