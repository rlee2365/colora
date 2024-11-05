import 'package:colora/models.dart';
import 'package:colora/project_export.dart';
import 'package:colora/section_lyrics.dart';
import 'package:colora/section_overlay.dart';
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
  final SectionDragNotifier sectionDragNotifier = SectionDragNotifier();
  final TextEditingController scratchpadController = TextEditingController();
  bool showHeader = true;

  @override
  void dispose() {
    super.dispose();
    titleController.dispose();
    scratchpadController.dispose();
  }

  @override
  void initState() {
    super.initState();
    titleController.text = widget.project.name;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final showHeaderActual =
        showHeader || (!widget.project.core!.settings.collapseHeadersOnFocus);
    return ChangeNotifierProvider.value(
      value: widget.project,
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 40,
          title: TextField(
            decoration: null,
            controller: titleController,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontSize: 16,
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
                  height: showHeaderActual ? 40 : 0,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        ActionChip(
                          label: const Text("export"),
                          onPressed: () {
                            showLyricsDialog(context, widget.project);
                          },
                          avatar:
                              showHeaderActual ? const Icon(Icons.share) : null,
                        ),
                        const SizedBox(width: 16.0),
                        Expanded(
                          child: ActionChip(
                              avatar: showHeaderActual
                                  ? const Icon(Icons.file_open)
                                  : null,
                              label: Consumer<Project>(
                                  builder: (context, project, _) {
                                return Text(
                                    "file: ${p.basename(project.appLocalFilePath)}",
                                    overflow: TextOverflow.ellipsis,
                                    softWrap: false);
                              }),
                              onPressed: () async {
                                final info = await filePicker1();
                                if (info.targetPath != null) {
                                  final targetPath = info.targetPath!;
                                  //final fileName = info.fileName!;
                                  widget.project
                                      .setAppLocalFilePath(targetPath);
                                }
                              }),
                        ),
                        const SizedBox(width: 16),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(
                height: 8.0,
              ),
              // Audio waveform
              ChangeNotifierProvider.value(
                value: widget.project.updatePathNotifier,
                child: Consumer<UpdatePathNotifier>(builder: (context, _, __) {
                  return AudioTransport(
                    key: ValueKey(widget.project.appLocalFilePath),
                    project: widget.project,
                    controller: transportController,
                    sectionDragNotifier: sectionDragNotifier,
                  );
                }),
              ),
              // Text editor
              Expanded(
                child: Card(
                  color: theme.colorScheme.onSecondaryFixed,
                  elevation: 10,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                        color: theme.colorScheme.onSecondary,
                        width: 2.0,
                      )),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: PageView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        MultiProvider(
                          providers: [
                            ChangeNotifierProvider.value(value: widget.project),
                            ChangeNotifierProvider.value(
                                value: transportController),
                            ChangeNotifierProvider.value(
                                value: sectionDragNotifier),
                          ],
                          child: Consumer3<AudioTransportController, Project,
                                  SectionDragNotifier>(
                              builder: (context, controller, project, _, __) {
                            final project = widget.project;
                            final section =
                                project.getSection(controller.currentTimeMs);
                            if (section != null) {
                              return SectionLyrics(
                                key: ValueKey(section.id),
                                theme: theme,
                                section: section,
                                core: project.core!,
                              );
                            } else {
                              return const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("create a section to edit lyrics"),
                                  ],
                                ),
                              );
                            }
                          }),
                        ),
                      ],
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
