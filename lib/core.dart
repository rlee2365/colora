import 'package:colora/backup.dart';
import 'package:colora/models.dart';
import 'package:colora/objectbox.g.dart';
import 'package:colora/settings.dart';
import 'package:colora/waveform_cache.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class ColoraCore extends ChangeNotifier {
  static const dbDir = 'Colora';
  Store? store;
  Box<Project>? projectBox;
  Box<Section>? sectionBox;
  List<Project> projects = [];
  final waveformCache = WaveformCache();
  late final ColoraSettings settings;
  late final ColoraBackup backup;
  ColoraCore() {
    backup = ColoraBackup(this);
  }

  Future<void> setup() async {
    settings = await ColoraSettings.load();
    await setupObjectBox();
    notifyListeners();
  }

  Future<void> setupObjectBox() async {
    final docsDir = await getApplicationDocumentsDirectory();
    projects.clear();
    notifyListeners();
    if (this.store != null) {
      this.store!.close();
    }
    final store = await openStore(directory: p.join(docsDir.path, dbDir));
    this.store = store;
    projectBox = store.box<Project>();
    sectionBox = store.box<Section>();
    // if (kDebugMode) {
    // projectBox.removeAll();
    // sectionBox.removeAll();
    // }
    await waveformCache.setup(store);
    loadFromObjectBox();
  }

  void loadFromObjectBox() {
    projects = projectBox!.getAll();
    for (final project in projects) {
      project.core = this;
    }
    notifyListeners();
  }

  Project createProject(
      String name, String appLocalFilePath, int durMilliseconds) {
    final project = Project();
    project.setName(name);
    project.setAppLocalFilePath(appLocalFilePath);
    project.setDurMilliseconds(durMilliseconds);
    project.id = projectBox!.put(project);
    project.core = this;
    projects.add(project);
    notifyListeners();
    return project;
  }

  void deleteProject(Project project) {
    projects.remove(project);
    projectBox!.remove(project.id);
    notifyListeners();
  }
}
