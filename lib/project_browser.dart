import 'package:collection/collection.dart';
import 'package:colora/add_project.dart';
import 'package:colora/core.dart';
import 'package:colora/models.dart';
import 'package:colora/project_editor.dart';
import 'package:colora/settings.dart';
import 'package:colora/utils.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fuzzywuzzy/fuzzywuzzy.dart';
import 'package:path/path.dart' as p;

class DeletionController extends ChangeNotifier {
  bool _isDeleting = false;

  bool get isDeleting => _isDeleting;
  set isDeleting(bool value) {
    _isDeleting = value;
    notifyListeners();
  }

  final Set<Project> _toDelete = {};

  void addProject(Project project) {
    _toDelete.add(project);
    notifyListeners();
  }

  void removeProject(Project project) {
    _toDelete.remove(project);
    notifyListeners();
  }

  void clear() {
    _toDelete.clear();
    notifyListeners();
  }

  Set<Project> get toDelete => _toDelete;
}

class ProjectCard extends StatelessWidget {
  final Project project;
  final DeletionController deletionController;
  const ProjectCard(
      {super.key, required this.project, required this.deletionController});

  @override
  Widget build(BuildContext context) {
    final rad = BorderRadius.circular(18);
    final theme = Theme.of(context);
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: project),
        ChangeNotifierProvider.value(value: deletionController),
      ],
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Consumer<DeletionController>(
            builder: (context, deletionController, _) {
          return Card(
            key: ValueKey(project),
            color: deletionController.toDelete.contains(project)
                ? theme.colorScheme.errorContainer
                : theme.colorScheme.onSecondaryFixed,
            elevation: 10,
            shape: RoundedRectangleBorder(
                borderRadius: rad,
                side: BorderSide(
                  color: deletionController.isDeleting
                      ? theme.colorScheme.errorContainer
                      : theme.colorScheme.onSecondary,
                  width: 2.0,
                )),
            child: InkWell(
              borderRadius: rad,
              onTap: () {
                // Open editor route
                if (deletionController.isDeleting) {
                  if (deletionController.toDelete.contains(project)) {
                    deletionController.removeProject(project);
                  } else {
                    deletionController.addProject(project);
                  }
                } else {
                  enterProject(context);
                }
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
                        Text("upd. ${formatDateTime1(project.dateUpdated!)}",
                            style: Theme.of(context).textTheme.bodySmall),
                        const Spacer(),
                        // Duration
                        Text(
                            "dur: ${formatDuration1(Duration(milliseconds: project.durMilliseconds))}",
                            style: Theme.of(context).textTheme.bodySmall)
                      ],
                    ),
                    const Divider(),
                    const SizedBox(height: 4.0),
                    Consumer<Project>(builder: (context, project, _) {
                      return Text(
                          "instrumental: ${p.basename(project.appLocalFilePath)}",
                          style: Theme.of(context).textTheme.bodySmall);
                    }),
                    const Row()
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  void enterProject(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (context) {
      return ProjectEditor(project: project);
    }));
  }
}

class ProjectBrowser extends StatefulWidget {
  final ColoraCore core;
  const ProjectBrowser({super.key, required this.core});

  @override
  State<ProjectBrowser> createState() => _ProjectBrowserState();
}

class _ProjectBrowserState extends State<ProjectBrowser> {
  static const List<({String title, String name})> sortMethods = [
    (name: "updAsc", title: "updated (ascending)"),
    (name: "updDesc", title: "updated (descending)"),
  ];
  String sortMethod = "updDesc";
  final DeletionController _deletionController = DeletionController();
  final TextEditingController _searchController = TextEditingController();

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
                controller: _searchController,
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
        child: MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: widget.core),
            ChangeNotifierProvider.value(value: _searchController),
          ],
          child: Consumer2<ColoraCore, TextEditingController>(
              builder: (context, core, _, __) {
            return SingleChildScrollView(
              child: Column(
                children: projectCards(core),
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
            PopupMenuButton<String>(
                onSelected: (value) {
                  setState(() {
                    sortMethod = value;
                  });
                },
                itemBuilder: (context) {
                  return sortMethods
                      .map((e) => PopupMenuItem<String>(
                            value: e.name,
                            child: Text(e.title),
                          ))
                      .toList();
                },
                child: const Chip(
                    padding: EdgeInsets.all(4.0), label: Icon(Icons.sort))),
            const SizedBox(width: 16.0),
            IconButton.outlined(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(
                    builder: (context) {
                      return ChangeNotifierProvider.value(
                          value: widget.core.settings,
                          child: SettingsRoute(core: widget.core));
                    },
                  ));
                },
                icon: const Icon(
                  Icons.settings,
                )),
            const SizedBox(width: 12.0),
            IconButton.outlined(
                onPressed: () async {
                  if (_deletionController.isDeleting) {
                    if (_deletionController.toDelete.isEmpty) {
                      setState(() {
                        _deletionController.isDeleting = false;
                      });
                    } else {
                      bool? result = await deletionDialog(context);
                      if (result != null && result == true) {
                        setState(() {
                          _deletionController.isDeleting = false;
                        });
                      }
                    }
                  } else {
                    setState(() {
                      _deletionController.isDeleting = true;
                    });
                  }
                },
                icon: const Icon(
                  Icons.delete,
                ),
                color: _deletionController.isDeleting
                    ? theme.colorScheme.error
                    : null),
            const SizedBox(width: 16.0),
            IconButton.outlined(
                onPressed: () async {
                  showDialog(
                      context: context,
                      builder: (context) {
                        return AddProjectDialog(core: widget.core);
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

  Future<bool?> deletionDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: const Text('Delete selected projects?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(null);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                // Perform the delete action
                for (var project in _deletionController.toDelete) {
                  widget.core.deleteProject(project);
                }
                _deletionController.clear();
                Navigator.of(context).pop(true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  List<Widget> projectCards(ColoraCore core) {
    var l = core.projects;
    if (sortMethod == 'updAsc') {
      l = l.sorted(
        (a, b) => a.dateUpdated!.compareTo(b.dateUpdated!),
      );
    } else if (sortMethod == 'updDesc') {
      l = l.sorted(
        (a, b) => b.dateUpdated!.compareTo(a.dateUpdated!),
      );
    }

    final query = _searchController.text.trim().isNotEmpty;
    if (query) {
      final projectMap = Map<String, Project>.fromEntries(
        l.map((e) => MapEntry(e.name, e)),
      );
      final fuzzyExtract = extractAll(
          query: _searchController.text,
          choices: l.map((e) => e.name).toList(),
          cutoff: 70);
      l = fuzzyExtract.map((e) => projectMap[e.choice]!).toList();
    }
    return [
      for (final project in l)
        ProjectCard(
          project: project,
          deletionController: _deletionController,
        ),
    ];
  }
}
