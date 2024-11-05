import 'dart:async';

import 'package:colora/models.dart';
import 'package:colora/section_overlay.dart';
import 'package:colora/utils.dart';
import 'package:flutter/material.dart';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:keyboard_visibility_pro/keyboard_visibility_pro.dart';
import 'dart:math';

import 'package:provider/provider.dart';

class AudioTransportController extends ChangeNotifier {
  int _currentTimeMs = 0;

  int get currentTimeMs => _currentTimeMs;
  set currentTimeMs(int value) {
    _currentTimeMs = value;
    notifyListeners();
  }
}

// Implements less janky version of the transport
class AudioTransport extends StatefulWidget {
  static const double disallowSectionMargin = 8.0;
  final Project project;
  final AudioTransportController controller;
  final SectionDragNotifier sectionDragNotifier;
  const AudioTransport({
    super.key,
    required this.project,
    required this.controller,
    required this.sectionDragNotifier,
  });

  @override
  State<AudioTransport> createState() => _AudioTransportState();
}

class _AudioTransportState extends State<AudioTransport> {
  static const double fullTransportHeight = 60.0, collapsedHeight = 20.0;
  double transportHeight = fullTransportHeight;
  //// [ RecorderController]
  PlayerController playerController = PlayerController();
  PlayerController durationController = PlayerController();
  ScrollController scrollController = ScrollController();
  ScrollController sectionScrollController = ScrollController();
  StreamController<List<double>> waveformDataController = StreamController();
  StreamSubscription? finishedExtractionSubscription;
  int noOfSamples = 120;
  double pixelsPerSecond = 4.0;
  double squeezeExponent = 2.0;
  bool _avoidUpdateTransport = false;
  bool _sectionLooping = false;
  List<double> waveformData = [];

  @override
  void initState() {
    super.initState();
    setupPlayer();
    // We can't directly interrupt the extraction from here so we'll just lift the
    // file updating logic up to the parent widget

    // "currentDurationChanged" actually refers to the playing position
    playerController.onCurrentDurationChanged.listen((durMs) async {
      if (mounted == false) {
        return;
      }
      if (_avoidUpdateTransport) {
        return; // avoid updating transport if user is jogging
      }
      Section? currentSection =
          widget.project.getSection(widget.controller.currentTimeMs);
      Section? newSection = widget.project.getSection(durMs);
      if (currentSection != null &&
          newSection != currentSection &&
          _sectionLooping) {
        _avoidUpdateTransport = true;
        int jumpToMs = currentSection.startMilliseconds + 1;
        double pixels = jumpToMs * pixelsPerSecond / 1000;
        await playerController.seekTo(jumpToMs);
        scrollController.jumpTo(pixels);
        widget.controller.currentTimeMs = jumpToMs;
        _avoidUpdateTransport = false;
      } else {
        double pixels = durMs * pixelsPerSecond / 1000;
        scrollController.jumpTo(pixels);
        widget.controller.currentTimeMs = durMs;
      }
    });

    scrollController.addListener(() {
      int ms =
          (scrollController.position.pixels * 1000 / pixelsPerSecond).round();
      sectionScrollController.jumpTo(scrollController.position.pixels);
      widget.controller.currentTimeMs = ms;
      //print("Current section: ${widget.project.getSection(ms)?.id}");
      if (!_avoidUpdateTransport) {
        return;
      }
      playerController.seekTo(ms);
    });

    playerController.onCurrentExtractedWaveformData.listen((data) {
      if (mounted == false) return;
      waveformData = data;
      waveformDataController.add(waveformData);
    });
  }

  void playerReady() async {
    playerController.seekTo(0);
    widget.controller.currentTimeMs = 0;
  }

  void setupPlayer() async {
    // Dry run to get duration
    await durationController.preparePlayer(
        path: widget.project.appLocalFilePath,
        shouldExtractWaveform: false,
        noOfSamples: 1);

    final dur = durationController.maxDuration;
    widget.project.setDurMilliseconds(dur);
    setState(() {
      noOfSamples = dur ~/ 800;
    });

    final core = widget.project.core!;
    final hash = calculateFileChecksum(widget.project.appLocalFilePath);
    final cachedWaveform =
        core.waveformCache.get(fnv1aHash: hash, noOfSamples: noOfSamples);

    // Actual run
    await playerController.preparePlayer(
        path: widget.project.appLocalFilePath,
        shouldExtractWaveform: false,
        noOfSamples: noOfSamples);
    playerController.updateFrequency = UpdateFrequency.high;

    // If it's cached, we can just set the waveform data here
    if (cachedWaveform != null && cachedWaveform.waveform.isNotEmpty) {
      waveformData = cachedWaveform.waveform;
      waveformDataController.add(waveformData);
      return;
    }

    // Otherwise, we need to extract it
    // Apparently sometimes, the future just never finishes, so we need
    // to add our own listener
    if (finishedExtractionSubscription != null) {
      finishedExtractionSubscription!.cancel();
    }
    finishedExtractionSubscription =
        playerController.onCurrentExtractedWaveformData.listen((data) {
      if (mounted == false) return;
      // print("waveform extracted len: ${data.length}");
      if (data.length >= noOfSamples - 1) {
        // print("Storing waveform: $hash $noOfSamples");
        core.waveformCache.set(
            fnv1aHash: hash, noOfSamples: noOfSamples, waveform: waveformData);
      }
    });

    waveformData = await playerController.extractWaveformData(
        path: widget.project.appLocalFilePath, noOfSamples: noOfSamples);
  }

  @override
  void dispose() {
    super.dispose();
    playerController.dispose();
    durationController.dispose();
    scrollController.dispose();
    sectionScrollController.dispose();
    waveformDataController.close();
  }

  Widget removeSectionButton(BuildContext context) {
    Section? section =
        widget.project.getSection(widget.controller.currentTimeMs);
    return IconButton.outlined(
      icon: const Icon(Icons.delete),
      onPressed: section != null
          ? () {
              widget.project.removeSection(section);
            }
          : null,
    );
  }

  Widget addSectionButton(BuildContext context) {
    int disallowSectionMarginMs =
        AudioTransport.disallowSectionMargin ~/ pixelsPerSecond * 1000;
    final nearOtherSection = widget.project.touchesSection(
        widget.controller.currentTimeMs - disallowSectionMarginMs,
        widget.controller.currentTimeMs + disallowSectionMarginMs);
    return IconButton.outlined(
        onPressed: nearOtherSection
            ? null
            : () => widget.project.addSection(widget.controller.currentTimeMs),
        icon: const Icon(Icons.add));
  }

  Widget addSectionLoopButton(BuildContext context) {
    final theme = Theme.of(context);
    Color color = _sectionLooping ? theme.colorScheme.primary : Colors.grey;

    return ActionChip(
      onPressed: () {
        setState(() => _sectionLooping = !_sectionLooping);
      },
      visualDensity: VisualDensity.compact,
      avatar: Icon(Icons.repeat, color: color),
      label: Text("section", style: TextStyle(color: color)),
    );
  }

  Widget prevSectionButton(BuildContext context) {
    final boundaries = widget.project.getMillisecondBoundaries();
    final currentTimeMs = widget.controller.currentTimeMs;

    int? previousBoundary;
    for (var boundary in boundaries) {
      if (boundary >= currentTimeMs) break;
      previousBoundary = boundary;
    }

    return IconButton.filled(
      icon: const Icon(Icons.chevron_left),
      visualDensity: VisualDensity.compact,
      onPressed: previousBoundary != null
          ? () async {
              bool oldLooping = _sectionLooping;
              _sectionLooping = false;
              // Avoid section looping while skipping to different sections
              await playerController.seekTo(
                  min(previousBoundary!, widget.project.durMilliseconds - 1));
              _sectionLooping = oldLooping;
            }
          : null,
    );
  }

  Widget nextSectionButton(BuildContext context) {
    final boundaries = widget.project.getMillisecondBoundaries();
    final currentTimeMs = widget.controller.currentTimeMs;

    int? nextBoundary;
    for (var boundary in boundaries) {
      if (boundary > currentTimeMs) {
        nextBoundary = boundary;
        break;
      }
    }

    return IconButton.filled(
      icon: const Icon(Icons.chevron_right),
      visualDensity: VisualDensity.compact,
      onPressed: nextBoundary != null
          ? () async {
              bool oldLooping = _sectionLooping;
              _sectionLooping = false;
              await playerController.seekTo(
                min(nextBoundary! + 10, widget.project.durMilliseconds - 1),
              );
              _sectionLooping = oldLooping;
            }
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Math
    // n = number of samples as specified in preparePlayer
    // snapshot.data will fill up to (n-1) samples.
    // d = duration of the song in milliseconds
    // so each sample is (d / n) milliseconds
    // so the number of pixels per sample is (d / n) * pixelsPerSecond / 1000
    int n = noOfSamples - 1;
    int d = widget.project.durMilliseconds;
    double pixelsPerSample = (d / n) * pixelsPerSecond / 1000;
    double pixelsPerBox = pixelsPerSample * 0.7;
    double paddingSide = (pixelsPerSample - pixelsPerBox) / 2;

    //final playMarker
    final theme = Theme.of(context);

    trackPadding(constraints) {
      return EdgeInsets.fromLTRB(
          constraints.maxWidth / 2 - 1, // left padding for start of song
          0,
          constraints.maxWidth / 2, // right padding to allow scroll to end
          0);
    }

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: KeyboardVisibility(
              onChanged: (visible) {
                setState(() {
                  transportHeight =
                      visible ? collapsedHeight : fullTransportHeight;
                });
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LayoutBuilder(builder: (context, constraints) {
                    final trackPad = trackPadding(constraints);
                    return Stack(
                      children: [
                        AnimatedContainer(
                          width: pixelsPerSecond * d * 1000,
                          height: transportHeight,
                          duration: Duration(milliseconds: 100),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.onSecondaryFixed,
                          ),
                        ),
                        Center(
                          // play marker
                          child: AnimatedContainer(
                            width: 1,
                            height: transportHeight,
                            duration: Duration(milliseconds: 100),
                            color: Colors.red,
                          ),
                        ),
                        SingleChildScrollView(
                          controller: sectionScrollController,
                          physics: const NeverScrollableScrollPhysics(),
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              Padding(
                                padding: trackPad,
                                child: SectionOverlay(
                                  pixelsPerSecond: pixelsPerSecond,
                                  project: widget.project,
                                  transportHeight: transportHeight,
                                  dragNotifier: widget.sectionDragNotifier,
                                ),
                              ),
                            ],
                          ),
                        ),
                        AnimatedContainer(
                          height: transportHeight,
                          duration: Duration(milliseconds: 100),
                          child: NotificationListener<ScrollNotification>(
                            onNotification: (n) {
                              if (n is ScrollStartNotification) {
                                _avoidUpdateTransport = true;
                              } else if (n is ScrollEndNotification) {
                                _avoidUpdateTransport = false;
                              }
                              return false;
                            },
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              controller: scrollController,
                              child: StreamBuilder<List<double>>(
                                  stream: waveformDataController.stream,
                                  builder: (context, snapshot) {
                                    if (snapshot.data != null) {
                                      waveformData = snapshot.data!;
                                    }
                                    //print("Building with $waveformData");
                                    return Padding(
                                      padding: trackPad,
                                      child: Stack(
                                        children: [
                                          Center(
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              children: [
                                                for (final value
                                                    in waveformData)
                                                  Padding(
                                                    padding:
                                                        EdgeInsets.fromLTRB(
                                                      paddingSide,
                                                      0,
                                                      paddingSide,
                                                      0,
                                                    ),
                                                    child: Container(
                                                      width: pixelsPerBox,
                                                      decoration: BoxDecoration(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                                pixelsPerSample /
                                                                    2),
                                                        color: theme.colorScheme
                                                            .secondary,
                                                      ),
                                                      height: (pow(value,
                                                              1 / squeezeExponent)) *
                                                          transportHeight,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                  const SizedBox(height: 8.0),
                  Row(
                    children: [
                      const Spacer(),
                      MultiProvider(
                          providers: [
                            ChangeNotifierProvider.value(
                                value: widget.sectionDragNotifier),
                            ChangeNotifierProvider.value(
                                value: scrollController),
                          ],
                          child: Consumer3<ScrollController, Project,
                                  SectionDragNotifier>(
                              builder: (context, _, __, ___, ____) =>
                                  prevSectionButton(context))),
                      const SizedBox(width: 4.0),
                      IconButton.outlined(
                          onPressed: () async {
                            playerController.playerState == PlayerState.playing
                                ? await playerController.pausePlayer()
                                : await playerController.startPlayer(
                                    finishMode: FinishMode.loop);
                            setState(() {});
                          },
                          icon: Icon(playerController.playerState ==
                                  PlayerState.playing
                              ? Icons.pause
                              : Icons.play_arrow)),
                      const SizedBox(width: 4.0),
                      ChangeNotifierProvider.value(
                        value: widget.sectionDragNotifier,
                        child: ChangeNotifierProvider.value(
                            value: scrollController,
                            child: Consumer3<ScrollController, Project,
                                    SectionDragNotifier>(
                                builder: (context, _, __, ___, ____) {
                              return addSectionButton(context);
                            })),
                      ),
                      const SizedBox(width: 4.0),
                      ChangeNotifierProvider.value(
                        value: widget.sectionDragNotifier,
                        child: ChangeNotifierProvider.value(
                            value: scrollController,
                            child: StreamBuilder(
                                stream:
                                    playerController.onCurrentDurationChanged,
                                builder: (context, snapshot) {
                                  return Consumer3<ScrollController, Project,
                                          SectionDragNotifier>(
                                      builder: (context, _, __, ___, ____) {
                                    return removeSectionButton(context);
                                  });
                                })),
                      ),
                      const SizedBox(width: 4.0),
                      addSectionLoopButton(context),
                      const SizedBox(width: 8.0),
                      MultiProvider(
                          providers: [
                            ChangeNotifierProvider.value(
                                value: widget.sectionDragNotifier),
                            ChangeNotifierProvider.value(
                                value: scrollController),
                          ],
                          child: Consumer3<ScrollController, Project,
                                  SectionDragNotifier>(
                              builder: (context, _, __, ___, ____) =>
                                  nextSectionButton(context))),
                      const Spacer(),
                    ],
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
