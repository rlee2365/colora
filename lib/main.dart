import 'package:colora/core.dart';
import 'package:colora/project_browser.dart';
import 'package:colora/settings.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final core = ColoraCore();
  await core.setup();
  runApp(ColoraApp(
    core: core,
  ));
}

class ColoraApp extends StatelessWidget {
  final ColoraCore core;
  ColoraApp({super.key, required this.core}) {
    final audioPermission = Permission.audio.isDenied;
    audioPermission.then((value) {
      if (value) {
        Permission.audio.request();
      }
    });
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: core.settings,
      child: Consumer<ColoraSettings>(builder: (context, settings, _) {
        return MaterialApp(
          title: 'Colora Songwriter',
          theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                  seedColor: settings.seedColor, brightness: Brightness.dark),
              fontFamily: 'serif'),
          home: ProjectBrowser(
            core: core,
          ),
        );
      }),
    );
  }
}
