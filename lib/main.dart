import 'package:colora/core.dart';
import 'package:colora/project_browser.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final core = ColoraCore();
  await core.setupObjectBox();
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
    return MaterialApp(
      title: 'Colora Songwriter',
      theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xff82bace), brightness: Brightness.dark),
          fontFamily: GoogleFonts.sourceSerif4().fontFamily),
      home: ProjectBrowser(
        core: core,
      ),
    );
  }
}
