import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class FileDialogWidget extends StatefulWidget {
  const FileDialogWidget({super.key});

  @override
  _FileDialogWidgetState createState() => _FileDialogWidgetState();
}

class _FileDialogWidgetState extends State<FileDialogWidget> {
  String _selectedFilePath = '';

  Future<void> _openFileDialog() async {
    final file = await FilePicker.platform.pickFiles();
    if (file != null) {
      setState(() {
        _selectedFilePath = file.files.single.path!;
      });
      print('Selected file path: $_selectedFilePath');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: _openFileDialog,
          child: Text('Open File'),
        ),
        Text('Selected file path: $_selectedFilePath'),
      ],
    );
  }
}
