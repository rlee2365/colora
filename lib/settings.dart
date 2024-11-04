import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ColoraSettings extends ChangeNotifier {
  static const String _keySeedColor = 'seedColor';

  static Future<ColoraSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    final colorCode = prefs.getInt(_keySeedColor);
    final instance = ColoraSettings();
    if (colorCode != null) {
      instance._seedColor = Color(colorCode);
    }
    return instance;
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keySeedColor, _seedColor.value);
  }

  Color _seedColor = const Color(0xff82bace);

  Color get seedColor => _seedColor;
  set seedColor(Color value) {
    _seedColor = value;
    save();
    notifyListeners();
  }
}

class SettingsRoute extends StatefulWidget {
  const SettingsRoute({super.key});

  @override
  SettingsRouteState createState() => SettingsRouteState();
}

class SettingsRouteState extends State<SettingsRoute> {
  final _colorOptions = [
    const Color(0xff82bace),
    const Color(0xffe57b7b),
    const Color(0xff7bc5ae),
    const Color(0xfff2c464),
    const Color(0xffa569bd),
  ];

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<ColoraSettings>(context);
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('settings'),
        backgroundColor: colorScheme.primaryContainer,
      ),
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
            Row(
              children: [
                const Text("seed color"),
                const Spacer(),
                DropdownButton<Color>(
                  value: settings.seedColor,
                  onChanged: (newColor) {
                    settings.seedColor = newColor!;
                  },
                  items: _colorOptions
                      .map((color) => DropdownMenuItem<Color>(
                            value: color,
                            child: Container(
                              height: 24,
                              width: 24,
                              decoration: BoxDecoration(
                                  color: color, shape: BoxShape.circle),
                            ),
                          ))
                      .toList(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}