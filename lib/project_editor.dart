import 'package:colora/models.dart';
import 'package:colora/section_lyrics.dart';
import 'package:colora/utils.dart';
import 'package:colora/transport.dart';
import 'package:flutter/material.dart';
import 'package:keyboard_visibility_pro/keyboard_visibility_pro.dart';
import 'package:provider/provider.dart';
import 'package:path/path.dart' as p;

class ProjectEditor extends StatefulWidget {
  final Project project;
  const ProjectEditor({
    super.key,
    required this.project,
  });

  @override
  State<ProjectEditor> createState() => _ProjectEditorState();
}

class _ProjectEditorState extends State<ProjectEditor> {
  final titleController = TextEditingController(text: "");
  final AudioTransportController transportController =
      AudioTransportController();
  bool showHeader = true;

  @override
  void dispose() {
    super.dispose();
    titleController.dispose();
  }

  @override
  void initState() {
    super.initState();
    titleController.text = widget.project.name;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ChangeNotifierProvider.value(
      value: widget.project,
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 50,
          title: TextField(
            decoration: null,
            controller: titleController,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontSize: 24,
            ),
            onChanged: (text) {
              widget.project.setName(text);
            },
          ),
          backgroundColor: theme.colorScheme.primaryContainer,
          // actions : Change file
        ),
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              KeyboardVisibility(
                onChanged: (state) => setState(() {
                  showHeader = !state;
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 100),
                  height: showHeader ? 40 : 0,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                    child: Row(
                      children: [
                        ActionChip(
                            label: const Text("Change file"),
                            onPressed: () async {
                              final info = await filePicker1();
                              if (info.targetPath != null) {
                                final targetPath = info.targetPath!;
                                //final fileName = info.fileName!;
                                widget.project.setAppLocalFilePath(targetPath);
                              }
                            }),
                        const SizedBox(width: 16),
                        Expanded(child:
                            Consumer<Project>(builder: (context, project, _) {
                          return Text(
                            p.basename(project.appLocalFilePath),
                            overflow: TextOverflow.ellipsis,
                            softWrap: false,
                          );
                        })),
                      ],
                    ),
                  ),
                ),
              ),
              // Audio waveform
              ChangeNotifierProvider.value(
                value: widget.project.updatePathNotifier,
                child: Consumer<UpdatePathNotifier>(builder: (context, _, __) {
                  return AudioTransport(
                    key: ValueKey(widget.project.appLocalFilePath),
                    project: widget.project,
                    controller: transportController,
                  );
                }),
              ),
              const SizedBox(height: 8),
              // Text editor
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ChangeNotifierProvider.value(
                      value: widget.project,
                      child: ChangeNotifierProvider.value(
                        value: transportController,
                        child: Consumer2<AudioTransportController, Project>(
                            builder: (context, controller, project, _) {
                          final project = widget.project;
                          final section =
                              project.getSection(controller.currentTimeMs);
                          if (section != null) {
                            return SectionLyrics(
                              key: ValueKey(section.id),
                              theme: theme,
                              section: section,
                            );
                          } else {
                            return const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                      "No section. Create a section to edit lyrics."),
                                ],
                              ),
                            );
                          }
                        }),
                      ),
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
