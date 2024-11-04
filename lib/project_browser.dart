import 'package:colora/add_project.dart';
import 'package:colora/core.dart';
import 'package:colora/models.dart';
import 'package:colora/project_editor.dart';
import 'package:colora/utils.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path/path.dart' as p;

class ProjectCard extends StatelessWidget {
  final Project project;
  const ProjectCard({super.key, required this.project});

  @override
  Widget build(BuildContext context) {
    final rad = BorderRadius.circular(18);
    final theme = Theme.of(context);
    return ChangeNotifierProvider.value(
      value: project,
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Card(
          color: theme.colorScheme.onSecondaryFixed,
          elevation: 10,
          shape: RoundedRectangleBorder(
              borderRadius: rad,
              side: BorderSide(
                color: theme.colorScheme.onSecondary,
                width: 2.0,
              )),
          child: InkWell(
            borderRadius: rad,
            onTap: () {
              // Open editor route
              Navigator.push(context, MaterialPageRoute(builder: (context) {
                return ProjectEditor(project: project);
              }));
            },
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Consumer<Project>(builder: (context, project, _) {
                    return Text(project.name,
                        style: Theme.of(context).textTheme.headlineSmall);
                  }),
                  const SizedBox(height: 4.0),
                  Row(
                    children: [
                      // Date of updating
                      Text("Upd. ${formatDateTime1(project.dateUpdated!)}",
                          style: Theme.of(context).textTheme.bodySmall),
                      const Spacer(),
                      // Duration
                      Text(
                          "Dur: ${formatDuration1(Duration(milliseconds: project.durMilliseconds))}",
                          style: Theme.of(context).textTheme.bodySmall)
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 4.0),
                  Consumer<Project>(builder: (context, project, _) {
                    return Text(
                        "Instrumental: ${p.basename(project.appLocalFilePath)}",
                        style: Theme.of(context).textTheme.bodySmall);
                  }),
                  const Row()
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ProjectBrowser extends StatelessWidget {
  final ColoraCore core;
  const ProjectBrowser({super.key, required this.core});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text("colora"),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: SizedBox(
              width: 160.0,
              child: TextField(
                decoration: const InputDecoration(
                    isDense: true,
                    labelText: 'search',
                    border: OutlineInputBorder()),
              ),
            ),
          ),
        ],
        backgroundColor: theme.colorScheme.primaryContainer,
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 8.0),
        child: ChangeNotifierProvider.value(
          value: core,
          child: Consumer<ColoraCore>(builder: (context, core, _) {
            return SingleChildScrollView(
              child: Column(
                children: [
                  for (final project in core.projects)
                    ProjectCard(
                      project: project,
                    ),
                ],
              ),
            );
          }),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          children: [
            const Spacer(),
            const SizedBox(width: 12.0),
            IconButton.outlined(
                onPressed: () {},
                icon: const Icon(
                  Icons.import_export,
                )),
            const SizedBox(width: 12.0),
            IconButton.outlined(
                onPressed: () {},
                icon: const Icon(
                  Icons.delete,
                )),
            const SizedBox(width: 12.0),
            IconButton.outlined(
                onPressed: () {},
                icon: const Icon(
                  Icons.sort,
                )),
            const SizedBox(width: 12.0),
            IconButton.outlined(
                onPressed: () async {
                  showDialog(
                      context: context,
                      builder: (context) {
                        return AddProjectDialog(core: core);
                      });
                },
                icon: const Icon(
                  Icons.add,
                ))
          ],
        ),
      ),
    );
  }
}
