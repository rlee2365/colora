import 'dart:math';

import 'package:colora/models.dart';
import 'package:colora/transport.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SectionDragNotifier extends ChangeNotifier {
  void notify() {
    notifyListeners();
  }
}

class SectionOverlay extends StatefulWidget {
  final Project project;
  final double pixelsPerSecond;
  final double transportHeight;
  final SectionDragNotifier dragNotifier;
  const SectionOverlay(
      {super.key,
      required this.project,
      required this.pixelsPerSecond,
      required this.transportHeight,
      required this.dragNotifier});

  static const double sectionGapWidth = 2;
  static const double sectionBarHeight = 4;
  static const double dragExtraMargin = 24;
  static const double dragHandleDiameter = 48;
  static const double dragActivateExtraDiameter = 48;

  @override
  State<SectionOverlay> createState() => _SectionOverlayState();
}

class _SectionOverlayState extends State<SectionOverlay> {
  double msToPixels(int ms) => (ms / 1000) * widget.pixelsPerSecond;
  double pixelsToMs(double pixels) => (pixels / widget.pixelsPerSecond) * 1000;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
        value: widget.project,
        child: Consumer<Project>(builder: (context, project, _) {
          final sections = project.sections.toList();
          if (sections.isEmpty) {
            return Row(children: [
              SizedBox(
                width: widget.pixelsPerSecond * project.durMilliseconds / 1000,
              )
            ]);
          }

          return ChangeNotifierProvider.value(
            value: widget.dragNotifier,
            child: Consumer<SectionDragNotifier>(builder: (context, _, __) {
              final sectionBoundaries = project.getSectionBoundaries();
              // print(
              // "sb: ${sectionBoundaries.map((e) => "${e.section.id} ${e.startMs} ${e.endMs}").toList()}");
              double spacerWidth = msToPixels(sectionBoundaries[0].startMs);
              return Row(
                children: [
                  SizedBox(
                    width: spacerWidth,
                    height: widget.transportHeight,
                  ),
                  for (final sectionBoundary in sectionBoundaries)
                    ChangeNotifierProvider.value(
                      value: sectionBoundary.section,
                      child: Consumer<Section>(builder: (context, section, _) {
                        return Stack(
                          key: ValueKey(sectionBoundary.section.id),
                          clipBehavior: Clip.none,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(
                                  right: SectionOverlay.sectionGapWidth),
                              child: Container(
                                width: max(
                                    msToPixels(sectionBoundary.endMs -
                                            sectionBoundary.startMs) -
                                        SectionOverlay.sectionGapWidth,
                                    0),
                                height: SectionOverlay.sectionBarHeight,
                                color: section.getColor(),
                              ),
                            ),
                            Container(
                                width: 1,
                                height: widget.transportHeight +
                                    SectionOverlay.dragExtraMargin,
                                color: section.getColor()),
                            Positioned(
                                top: widget.transportHeight +
                                    SectionOverlay.dragExtraMargin -
                                    SectionOverlay.dragHandleDiameter / 2,
                                left: -SectionOverlay.dragHandleDiameter / 4,
                                child: Container(
                                  width: SectionOverlay.dragHandleDiameter / 2,
                                  height: SectionOverlay.dragHandleDiameter / 2,
                                  decoration: BoxDecoration(
                                      color: section.getColor(),
                                      borderRadius: BorderRadius.circular(
                                          SectionOverlay.dragHandleDiameter)),
                                )),
                            Positioned(
                              top: widget.transportHeight +
                                  SectionOverlay.dragActivateExtraDiameter -
                                  (SectionOverlay.dragHandleDiameter +
                                          SectionOverlay
                                              .dragActivateExtraDiameter) /
                                      1.5,
                              left: -(SectionOverlay.dragHandleDiameter +
                                      SectionOverlay
                                          .dragActivateExtraDiameter) /
                                  4,
                              child: Container(
                                  width: (SectionOverlay.dragHandleDiameter +
                                          SectionOverlay
                                              .dragActivateExtraDiameter) /
                                      1.8,
                                  height: (SectionOverlay.dragHandleDiameter +
                                          SectionOverlay
                                              .dragActivateExtraDiameter) /
                                      1.5,
                                  color: Colors.transparent,
                                  child: GestureDetector(
                                    onPanUpdate: (details) {
                                      final dms = pixelsToMs(details.delta.dx);

                                      int disallowSectionMarginMs =
                                          AudioTransport
                                                  .disallowSectionMargin ~/
                                              widget.pixelsPerSecond *
                                              1000;
                                      double rightEdgeMargin = (SectionOverlay
                                                      .dragHandleDiameter +
                                                  SectionOverlay
                                                      .dragActivateExtraDiameter) /
                                              4 +
                                          1;
                                      double rightEdgeMarginMs =
                                          pixelsToMs(rightEdgeMargin);
                                      double leadingMsBoundary = 0,
                                          trailingMsBoundary = project
                                                  .durMilliseconds
                                                  .toDouble() -
                                              rightEdgeMarginMs;
                                      if (sectionBoundary.leadingMs != null) {
                                        leadingMsBoundary =
                                            (sectionBoundary.leadingMs! +
                                                    disallowSectionMarginMs)
                                                .toDouble();
                                      }
                                      leadingMsBoundary = min(
                                          leadingMsBoundary,
                                          project.durMilliseconds.toDouble() -
                                              1);
                                      if (sectionBoundary.trailingMs != null) {
                                        trailingMsBoundary =
                                            (sectionBoundary.trailingMs! -
                                                    disallowSectionMarginMs)
                                                .toDouble();
                                      }
                                      trailingMsBoundary =
                                          max(trailingMsBoundary, 0);
                                      section.startMilliseconds = clampDouble(
                                              section.startMilliseconds
                                                      .toDouble() +
                                                  dms,
                                              leadingMsBoundary,
                                              trailingMsBoundary)
                                          .round();
                                      // print(
                                      // "Moved to ${section.startMilliseconds} : ${project.durMilliseconds},"
                                      // "limits ${leadingMsBoundary}, ${trailingMsBoundary}");
                                      widget.dragNotifier.notify();
                                      // We actually need to trigger an entire rebuild of the sections here

                                      //print(details.localPosition);
                                    },
                                  )),
                            )
                          ],
                        );
                      }),
                    )
                ],
              );
            }),
          );
        }));
  }
}
