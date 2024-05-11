import 'dart:convert';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:updat/updat.dart';
import 'package:weightechapp/models.dart';
import 'package:weightechapp/themes.dart';
import 'package:weightechapp/utils.dart';
import 'package:weightechapp/fluent_routes.dart';
import 'package:flutter/widgets.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:weightechapp/extra_widgets.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:async';
import 'dart:ui';
import 'dart:io';
import 'dart:math' as math;
import 'package:simple_rich_text/simple_rich_text.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:feedback_github/feedback_github.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:shortid/shortid.dart';
import 'package:path/path.dart' as p;
import 'package:string_validator/string_validator.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:file_saver/file_saver.dart';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';

//MARK: MAIN
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Initialize Flutter Bindings

  await Log().init();
  Log.logger.t("...Logger initialized...");

  Log.logger.t("...Getting app info...");
  await AppInfo().init();
  Log.logger.i('Version: ${AppInfo.packageInfo.version}, Build: ${AppInfo.packageInfo.buildNumber}');

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
        // background: fluent.Colors.grey,
        // feedbackSheetColor: fluent.Colors.white,
        // sheetIsDraggable: false,
        // bottomSheetDescriptionStyle: const TextStyle(color: fluent.Colors.black),
        // bottomSheetTextInputStyle: const TextStyle(color: fluent.Colors.black),
        activeFeedbackModeColor: const Color(0xFF224190),
        feedbackSheetColor: Colors.white
      ),
      child: 
        WeightechApp()
    )
  );
  appWindow.show();
  doWhenWindowReady(() {
    final win = appWindow;

    FlutterView view = WidgetsBinding.instance.platformDispatcher.views.first;
    
    win.maximize();
    win.alignment = Alignment.center;
    win.title = "Custom window with Flutter";
    win.show();
  });
}

/// A class that defines the widget tree.
class WeightechApp extends StatelessWidget {
  WeightechApp() : super(key: GlobalKey());

  @override
  Widget build(BuildContext context) {
    return FluentApp(
      debugShowCheckedModeBanner: false,
      title: "Weightech Inc. Sales",
      theme: WeightechThemes.fluentLightTheme, 
      home: const StartupPage(),
    );
  }
}



