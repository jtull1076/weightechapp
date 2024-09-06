import 'package:weightechapp/themes.dart';
import 'package:weightechapp/utils.dart';
import 'package:weightechapp/universal_routes.dart';
import 'package:weightechapp/fluent_routes.dart';
import 'package:flutter/material.dart' as material;
import 'package:fluent_ui/fluent_ui.dart';
import 'package:weightechapp/extra_widgets.dart';
import 'dart:async';
import 'dart:io';
import 'package:feedback_github/feedback_github.dart';
import 'package:window_manager/window_manager.dart';
import 'package:media_kit/media_kit.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';


//MARK: MAIN
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Initialize Flutter Bindings

  MediaKit.ensureInitialized();

  await windowManager.ensureInitialized();
  if (Platform.isWindows) {
    WindowManager.instance.setMinimumSize(const Size(850, 550));
  }

  await AppInfo().init();
  await Log().init();
  Log.logger.i('Version: ${AppInfo.packageInfo.version}, Build: ${AppInfo.packageInfo.buildNumber}, SessionId: ${AppInfo.sessionId}');

  runApp(
    FluentTheme(
      data: FluentThemeData(),
      child: BetterFeedback(
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
          colorScheme: WeightechThemes.materialLightTheme.colorScheme,
        ),
        child: 
          WeightechApp()
      )
    )
  );
}

/// A class that defines the widget tree.
class WeightechApp extends StatelessWidget {
  WeightechApp() : super(key: GlobalKey());

  @override
  Widget build(BuildContext context) {
    return FluentApp(
      theme: WeightechThemes.fluentLightTheme,
      // darkTheme: WeightechThemes.fluentDarkTheme,
      title: "Weightech Inc. Sales",
      //theme: WeightechThemes.lightTheme, 
      home: const StartupPage()
    );
  }
}
