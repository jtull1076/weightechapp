import 'package:weightechapp/themes.dart';
import 'package:weightechapp/utils.dart';
import 'package:weightechapp/fluent_routes.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:weightechapp/extra_fluent_widgets.dart';
import 'dart:async';
import 'dart:io';
import 'package:feedback_github/feedback_github.dart';
import 'package:window_manager/window_manager.dart';
import 'package:media_kit/media_kit.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart';


//MARK: MAIN
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Initialize Flutter Bindings

  MediaKit.ensureInitialized();
  await Window.initialize();

  



  await windowManager.ensureInitialized();
  if (Platform.isWindows) {
    WindowManager.instance.setMinimumSize(const Size(850, 550));
    
  }

  await AppInfo().init();
  await AppSettings().init();
  await Log().init();
  Log.logger.i('Version: ${AppInfo.packageInfo.version}, Build: ${AppInfo.packageInfo.buildNumber}, SessionId: ${AppInfo.sessionId}');
  WeightechThemes();

  // TODO: Make effect optional solid or mica, adjust things accordingly

  await Window.setEffect(
    effect: WindowEffect.mica,
    dark: WeightechThemes.fluentTheme.brightness.isDark,
    color: WeightechThemes.fluentTheme.brightness.isDark ? Colors.white : Colors.white, // WeightechThemes.windowsLight : WeightechThemes.windowsLight
  );

  runApp(
    FluentTheme(
      data: WeightechThemes.fluentTheme,
      child: BetterFeedback(
        feedbackBuilder: (context, onSubmit, scrollController) {
          return CustomFeedbackForm(
            onSubmit: onSubmit,
            scrollController: scrollController,
          );
        },
        localeOverride: const Locale('en'),
        theme: FeedbackThemeData(
          background: Colors.transparent,
          feedbackSheetColor: Colors.white,
          sheetIsDraggable: false,
          bottomSheetDescriptionStyle: const TextStyle(color: Colors.black),
          bottomSheetTextInputStyle: const TextStyle(color: Colors.black),
          activeFeedbackModeColor: WeightechThemes.weightechBlue,
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
    Log.logger.i('Mica color: ${WeightechThemes.fluentLightTheme.micaBackgroundColor}');
    return FluentApp(
      theme: WeightechThemes.fluentLightTheme,
      // darkTheme: WeightechThemes.fluentDarkTheme,
      title: "Weightech Inc. Sales",
      //theme: WeightechThemes.lightTheme, 
      home: const StartupPage()
    );
  }
}
