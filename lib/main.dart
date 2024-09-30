import 'package:weightechapp/themes.dart';
import 'package:weightechapp/android_routes.dart';
import 'package:weightechapp/utils.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:media_kit/media_kit.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:flutter/services.dart';

//MARK: MAIN
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Initialize Flutter Bindings

  MediaKit.ensureInitialized(); // for video
  WakelockPlus.enable(); // disable screen lock
  //SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: [SystemUiOverlay.top]); // set fullscreen
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);

  await AppInfo().init();
  await Log().init();
  Log.logger.i('Version: ${AppInfo.packageInfo.version}, Build: ${AppInfo.packageInfo.buildNumber}, SessionId: ${AppInfo.sessionId}');

  runApp(
    WeightechApp()
  );
}

/// A class that defines the widget tree.
class WeightechApp extends StatelessWidget {
  WeightechApp() : super(key: GlobalKey());

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Weightech Inc. Sales",
      theme: WeightechThemes.materialLightTheme, 
      home: const StartupPage()
    );
  }
}