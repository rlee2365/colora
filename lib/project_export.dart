import 'package:colora/models.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

                  // We can't access directories outside the app document directory
                  // so saving to a file is out
                  // ElevatedButton(
                  //   onPressed: () async {
                  //     final lyrics =
                  //         project.generateLyrics(timestamps: includeTimestamps);
                  //     String? outputFile = await FilePicker.platform.saveFile(
                  //       dialogTitle: 'Save Lyrics',
                  //       fileName: 'lyrics.txt',
                  //     );

                  //     if (outputFile != null) {
                  //       File(outputFile).writeAsString(lyrics);
                  //       ScaffoldMessenger.of(context).showSnackBar(
                  //         const SnackBar(content: Text('Lyrics saved to file')),
                  //       );
                  //     }
                  //   },
                  //   child: const Text('Save to File'),
                  // ),
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
