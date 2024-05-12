import 'package:weightechapp/fluent_routes.dart';
import 'package:weightechapp/utils.dart';
import 'package:weightechapp/themes.dart';
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart' as material;
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:window_manager/window_manager.dart';
import 'package:weightechapp/extra_widgets.dart';
import 'dart:math' as math;
import 'package:feedback_github/feedback_github.dart';


//MARK: MAIN
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Initialize Flutter Bindings

  // await windowManager.ensureInitialized();
  // if (Platform.isWindows) {
  //   WindowManager.instance.setMinimumSize(const Size(850, 550));
  // }

  await Log().init();
  Log.logger.t("...Logger initialized...");

  Log.logger.t("...Getting app info...");
  await AppInfo().init();
  Log.logger.i('Version: ${AppInfo.packageInfo.version}, Build: ${AppInfo.packageInfo.buildNumber}');

  WeightechThemes();

  runApp(
    BetterFeedback(
      feedbackBuilder: (context, onSubmit, scrollController) {
        return CustomFeedbackForm(
          onSubmit: onSubmit,
          scrollController: scrollController,
        );
      },
      localeOverride: const Locale('en'),
      theme: FeedbackThemeData(
        background: Colors.grey,
        feedbackSheetColor: Colors.white,
        sheetIsDraggable: false,
        bottomSheetDescriptionStyle: const TextStyle(color: Colors.black),
        bottomSheetTextInputStyle: const TextStyle(color: Colors.black),
        activeFeedbackModeColor: const Color(0xFF224190),
      ),
      child: 
        WeightechApp()
    )
  );
}

/// A class that defines the widget tree.
class WeightechApp extends StatelessWidget {
  WeightechApp() : super(key: GlobalKey());

  @override
  Widget build(BuildContext context) {
    return FluentApp(
      debugShowCheckedModeBanner: false,
      title: "Weightech Inc. Sales",
      theme: (WidgetsBinding.instance.platformDispatcher.platformBrightness.isDark) ? WeightechThemes.fluentDarkTheme : WeightechThemes.fluentLightTheme,
      home: const StartupPage()
    );
  }
}

