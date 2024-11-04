import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:colora/core.dart';
import 'package:colora/utils.dart';
import 'package:flutter/material.dart';

class AddProjectDialog extends StatefulWidget {
  final ColoraCore core;
  const AddProjectDialog({super.key, required this.core});

  @override
  State<AddProjectDialog> createState() => _AddProjectDialogState();
}

class _AddProjectDialogState extends State<AddProjectDialog> {
  final TextEditingController _nameController = TextEditingController();
  PlayerController playerController = PlayerController();
  String _selectedFilePath = '';
  String _selectedFileName = '';
  int _selectedDuration = 0;

  @override
  void dispose() {
    super.dispose();
    _nameController.dispose();
    playerController.dispose();
  }

  @override
  void initState() {
    super.initState();
    playerController.onPlayerStateChanged.listen((event) {
      if (!mounted) return;
      setState(() {});
    });
    playerController.onCompletion.listen((_) {
      playerController.seekTo(0);
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool canAddProject =
        _selectedFilePath.isNotEmpty && _nameController.text.isNotEmpty;
    return AlertDialog(
        title: const Text('Add Project'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(labelText: 'Project Name'),
              controller: _nameController,
            ),
            const SizedBox(
              height: 16.0,
            ),
            ActionChip(
                onPressed: () async {
                  final info = await filePicker1();
                  if (info.targetPath != null) {
                    final targetPath = info.targetPath!;
                    final fileName = info.fileName!;
                    if (playerController.playerState == PlayerState.playing) {
                      await playerController.stopPlayer();
                    }
                    await playerController.seekTo(0);
                    await playerController.preparePlayer(
                        path: targetPath,
                        shouldExtractWaveform: true,
                        noOfSamples: 100,
                        volume: 1.0);
                    _selectedDuration = playerController.maxDuration;
                    setState(() {
                      // Have to copy file path to app documents to keep
                      _selectedFilePath = targetPath;
                      _selectedFileName = fileName;
                    });
                  }
                },
                label: const Text("Select Instrumental")),
            const SizedBox(
              height: 16.0,
            ),
            if (_selectedFilePath.isNotEmpty)
              Text("Selected file: $_selectedFileName"),
            _selectedFilePath.isNotEmpty
                ? AudioFileWaveforms(
                    size: Size(MediaQuery.of(context).size.width, 100.0),
                    playerController: playerController,
                  )
                : const Text("No file loaded"),
            const SizedBox(
              height: 16.0,
            ),
            if (_selectedFilePath.isNotEmpty)
              IconButton.outlined(
                  onPressed: () async {
                    playerController.playerState == PlayerState.playing
                        ? await playerController.pausePlayer()
                        : await playerController.startPlayer(
                            finishMode: FinishMode.loop);
                    setState(() {});
                  },
                  icon: Icon(playerController.playerState == PlayerState.playing
                      ? Icons.pause
                      : Icons.play_arrow)),
            const SizedBox(
              height: 8.0,
            ),
            OutlinedButton(
              onPressed: canAddProject
                  ? () {
                      final name = _nameController.text;
                      widget.core.createProject(
                          name, _selectedFilePath, _selectedDuration);
                      Navigator.of(context).pop();
                    }
                  : null,
              child: const Text("Add Project"),
            )
          ],
        ));
  }
}
