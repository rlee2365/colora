import 'package:colora/core.dart';
import 'package:flutter/material.dart';
import 'package:objectbox/objectbox.dart';
import 'package:collection/collection.dart';

@Entity()
class CachedWaveform {
  @Id()
  int id = 0;

  String fnv1aHash = "";
  int noOfSamples = 0;
  List<double> waveform = [];
}

class SectionBoundary {
  int startMs, endMs;
  int? leadingMs, trailingMs;
  Section section;
  SectionBoundary(
      {required this.startMs,
      required this.endMs,
      required this.leadingMs,
      required this.trailingMs,
      required this.section});
}

@Entity()
class Section extends ChangeNotifier {
  @Id()
  int id = 0;
  String _lyrics = "";
  int _startMilliseconds = 0;
  Color _color = Colors.white;

  Section();

  int get startMilliseconds => _startMilliseconds;
  set startMilliseconds(int value) {
    _startMilliseconds = value;
    notifyListeners();
  }

  String get lyrics => _lyrics;
  set lyrics(String value) {
    _lyrics = value;
    notifyListeners();
  }

  @override
  void notifyListeners() {
    project.target?.core?.sectionBox.put(this);
    super.notifyListeners();
  }

  Color get color => _color;
  set color(Color value) {
    _color = value;
    notifyListeners();
  }

  final project = ToOne<Project>();

  Map<String, dynamic> toCopyJson() {
    return {
      'lyrics': lyrics,
      'color': color.value,
    };
  }

  void fromCopyJson(Map<String, dynamic> json) {
    lyrics = json['lyrics'];
    color = Color(json['color']);
  }
}

class UpdatePathNotifier extends ChangeNotifier {}

@Entity()
class Project extends ChangeNotifier {
  @Id()
  int id = 0;
  String name = "";
  String appLocalFilePath = "";
  int durMilliseconds = 0;
  @Property(type: PropertyType.date)
  DateTime? dateUpdated;
  @Transient()
  ColoraCore? core;

  @Transient()
  final updatePathNotifier = UpdatePathNotifier();

  @Backlink('project')
  final sections = ToMany<Section>();

  Project();

  Section? addSection(int startMilliseconds) {
    // behavior:
    // If we happen to be at the exact same startMilliseconds as another, we disallow adding
    // If there are no sections, then we just add the section
    // If there are sections, then if there is a section with start time
    // before this one, we will inherit the lyrics from the previous section
    // (i.e. appending inherits, prepending doesn't)
    if (sections.isEmpty) {
      return _addSection(startMilliseconds);
    }
    Section? sameStart = sections
        .firstWhereOrNull((s) => s.startMilliseconds == startMilliseconds);
    if (sameStart != null) {
      return null;
    }
    Section? sectionBefore = sections.firstWhereOrNull(
        (element) => element.startMilliseconds < startMilliseconds);
    if (sectionBefore == null) {
      return _addSection(startMilliseconds);
    } else {
      final section = _addSection(startMilliseconds);
      section.lyrics = sectionBefore.lyrics;
      return section;
    }
  }

  List<SectionBoundary> getSectionBoundaries({int? durMillisecondsOverride}) {
    int durMilliseconds = durMillisecondsOverride ?? this.durMilliseconds;
    final s = sections.toList();
    s.sort((a, b) => a.startMilliseconds.compareTo(b.startMilliseconds));

    // print("Sections: ${s.map((s) => "${s.startMilliseconds}").toList()}");

    return s
        .map((section) => SectionBoundary(
            startMs: section.startMilliseconds,
            endMs: s.indexOf(section) == s.length - 1
                ? durMilliseconds
                : s[s.indexOf(section) + 1].startMilliseconds,
            leadingMs: s.indexOf(section) > 0
                ? s[s.indexOf(section) - 1].startMilliseconds
                : null,
            trailingMs: s.indexOf(section) < s.length - 1
                ? s[s.indexOf(section) + 1].startMilliseconds
                : null,
            section: section))
        .toList();
  }

  List<int> getMillisecondBoundaries() {
    final boundaries =
        sections.map((section) => section.startMilliseconds).toList();
    boundaries.insert(0, 0);
    if (!boundaries.contains(durMilliseconds)) {
      boundaries.add(durMilliseconds);
    }
    boundaries.sort();
    return boundaries;
  }

  SectionBoundary? getSectionBoundary(int ms) {
    final bounds = getSectionBoundaries();
    return bounds.firstWhereOrNull((b) => b.startMs <= ms && b.endMs > ms);
  }

  Section? getSection(int ms) {
    final bounds = getSectionBoundaries();
    return bounds
        .firstWhereOrNull((b) => b.startMs <= ms && b.endMs > ms)
        ?.section;
  }

  void removeSection(Section section) {
    sections.remove(section);
    core!.sectionBox.remove(section.id);
    notifyListeners();
  }

  bool touchesSection(int startMilliseconds, int endMilliseconds) {
    return sections.any((section) =>
        section.startMilliseconds >= startMilliseconds &&
        section.startMilliseconds <= endMilliseconds);
  }

  Section _addSection(int startMilliseconds) {
    final section = Section();

    section.startMilliseconds = startMilliseconds;
    section.id = core!.sectionBox.put(section);
    section.project.target = this;
    sections.add(section);
    notifyListeners();
    return section;
  }

  @override
  void notifyListeners() {
    dateUpdated = DateTime.now();
    super.notifyListeners();
    if (id == 0) return;
    core?.projectBox.put(this);
  }

  void setName(String name) {
    this.name = name;
    notifyListeners();
  }

  void setAppLocalFilePath(String appLocalFilePath) {
    this.appLocalFilePath = appLocalFilePath;
    updatePathNotifier.notifyListeners();
    notifyListeners();
  }

  void setDurMilliseconds(int durMilliseconds) {
    this.durMilliseconds = durMilliseconds;
    notifyListeners();
  }

  String generateLyrics({bool timestamps = false}) {
    final sb = StringBuffer();
    final sections = this.sections.toList();
    sections.sort((a, b) => a.startMilliseconds.compareTo(b.startMilliseconds));
    for (final section in sections) {
      if (timestamps) {
        final ms = section.startMilliseconds;
        final dur = Duration(milliseconds: ms);
        final h = dur.inHours.toString().padLeft(2, '0');
        final m = dur.inMinutes.remainder(60).toString().padLeft(2, '0');
        final s = dur.inSeconds.remainder(60).toString().padLeft(2, '0');
        final ddd =
            dur.inMilliseconds.remainder(1000).toString().padLeft(3, '0');
        sb.write('$h:$m:$s:$ddd\n');
      }
      sb.write('${section.lyrics}\n');
    }
    return sb.toString();
  }
}
