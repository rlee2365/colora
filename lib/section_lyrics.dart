import 'package:colora/core.dart';
import 'package:colora/models.dart';
import 'package:colora/section_overlay.dart';
import 'package:flutter/material.dart';
import 'package:keyboard_visibility_pro/keyboard_visibility_pro.dart';
import 'package:provider/provider.dart';

class SectionLyrics extends StatefulWidget {
  const SectionLyrics({
    super.key,
    required this.theme,
    required this.section,
    required this.core,
  });

  final ThemeData theme;
  final Section section;
  final ColoraCore core;

  @override
  State<SectionLyrics> createState() => _SectionLyricsState();
}

class _SectionLyricsState extends State<SectionLyrics> {
  final TextEditingController _lyricsController = TextEditingController();
  final List<Color> colors = [
    Colors.white,
    const Color(0xff94d2bd),
    const Color(0xffee9b00),
    const Color(0xffef23cc),
    const Color(0xff3a86ff),
    const Color(0xffd62828),
  ];
  Color selectedColor = Colors.white;
  bool showHeader = true;

  @override
  void initState() {
    super.initState();
    _lyricsController.text = widget.section.lyrics;
    selectedColor = widget.section.getColor();
  }

  @override
  Widget build(BuildContext context) {
    final showHeaderActual =
        showHeader || (!widget.core.settings.collapseHeadersOnFocus);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<Section>.value(value: widget.section),
      ],
      child: Consumer<Section>(builder: (context, section, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            KeyboardVisibility(
              onChanged: (bool visible) {
                setState(() {
                  showHeader = !visible;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: showHeaderActual ? 40 : 0,
                child: Row(
                  children: [
                    Text(
                      "lyrics",
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: widget.section.getColor()),
                    ),

                    const Spacer(),

                    // Copy/paste buttons - not sure if this is necessary
                    // IconButton.outlined(
                    // icon: const Icon(Icons.copy),
                    // visualDensity: VisualDensity.compact,
                    // onPressed: () {
                    // Clipboard.setData(
                    // ClipboardData(text: _lyricsController.text));
                    // },
                    // ),
                    // const SizedBox(width: 16),
                    // IconButton.outlined(
                    // icon: const Icon(Icons.paste),
                    // visualDensity: VisualDensity.compact,
                    // onPressed: () async {
                    // _lyricsController.text =
                    // (await Clipboard.getData(Clipboard.kTextPlain))?.text ??
                    // "";
                    // section.lyrics = _lyricsController.text;
                    // },
                    // ),
                    // const SizedBox(width: 16),

                    // Dropdown menu for selecting colors
                    DropdownButton<Color>(
                      value: selectedColor, // Currently selected color
                      icon: const Icon(Icons.arrow_downward),
                      onChanged: (Color? newColor) {
                        // Update state with the new color selection
                        setState(() {
                          // Assuming additional state is needed to track selected color
                          selectedColor = newColor!;
                          section.setColor(newColor);
                        });
                      },
                      items: colors.map<DropdownMenuItem<Color>>((Color color) {
                        return DropdownMenuItem<Color>(
                          value: color,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(6)),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(
                      width: 16,
                    ),
                  ],
                ),
              ),
            ),
            if (showHeaderActual) const Divider(),
            Expanded(
              child: TextField(
                decoration: null,
                maxLines: null,
                controller: _lyricsController,
                onChanged: (value) {
                  section.lyrics = value;
                },
                style: widget.theme.textTheme.bodyMedium,
              ),
            ),
          ],
        );
      }),
    );
  }
}
