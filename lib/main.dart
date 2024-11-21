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
import 'package:provider/provider.dart';
import 'package:adaptive_theme_fluent_ui/adaptive_theme_fluent_ui.dart';
import 'package:adaptive_theme/adaptive_theme.dart';

//MARK: MAIN
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Initialize Flutter Bindings

  MediaKit.ensureInitialized();
  await Window.initialize();
  await windowManager.ensureInitialized();
  windowManager.setTitleBarStyle(TitleBarStyle.hidden);
  if (Platform.isWindows) {
    WindowManager.instance.setMinimumSize(const Size(850, 550));
    await Window.hideWindowControls();
  }

  await AppInfo().init();
  await AppSettings().init();
  await Log().init();
  Log.logger.i(
      'Version: ${AppInfo.packageInfo.version}, Build: ${AppInfo.packageInfo.buildNumber}, SessionId: ${AppInfo.sessionId}');
  WeightechThemes();

  runApp(FluentTheme(
      data: WeightechThemes.currentTheme,
      child: BetterFeedback(
          feedbackBuilder: (context, onSubmit, scrollController) {
            return CustomFeedbackForm(
              onSubmit: onSubmit,
              scrollController: scrollController,
            );
          },
          localeOverride: const Locale('en'),
          themeMode: WeightechThemes.themeMode,
          theme: FeedbackThemeData(
            background: Colors.transparent,
            feedbackSheetColor: Colors.transparent,
            sheetIsDraggable: false,
            bottomSheetDescriptionStyle: TextStyle(color: Colors.black),
            bottomSheetTextInputStyle: TextStyle(color: Colors.black),
            activeFeedbackModeColor: WeightechThemes.weightechBlue,
          ),
          darkTheme: FeedbackThemeData(
            background: Colors.transparent,
            feedbackSheetColor: Colors.transparent,
            sheetIsDraggable: false,
            bottomSheetDescriptionStyle: TextStyle(color: Colors.white),
            bottomSheetTextInputStyle: TextStyle(color: Colors.white),
            activeFeedbackModeColor: WeightechThemes.weightechBlue,
          ),
          child: WeightechApp())));
}

/// A class that defines the widget tree.
class WeightechApp extends StatelessWidget {
  WeightechApp() : super(key: GlobalKey());

  @override
  Widget build(BuildContext context) {
    // Listen to theme changes and update the Mica effect

    return FluentAdaptiveTheme(
        initial: AdaptiveThemeMode.system,
        light: WeightechThemes.fluentLightTheme,
        dark: WeightechThemes.fluentDarkTheme,
        builder: (theme, darkTheme) {
          // Check if the widget tree is ready
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (AppSettings.useMica ?? false) {
              if (AppSettings.isDarkMode ?? false) {
                WeightechThemes.setMicaEffect(AdaptiveThemeMode.dark);
                WeightechThemes.setCustoms(mode: AdaptiveThemeMode.dark);
              } else if (!(AppSettings.isDarkMode ?? true)) {
                WeightechThemes.setMicaEffect(AdaptiveThemeMode.light);
                WeightechThemes.setCustoms(mode: AdaptiveThemeMode.light);
              } else {
                WeightechThemes.setMicaEffect(AdaptiveThemeMode.system);
                WeightechThemes.setCustoms(mode: AdaptiveThemeMode.system);
              }
            } else {
              if (AppSettings.isDarkMode ?? false) {
                WeightechThemes.disableMicaEffect(AdaptiveThemeMode.dark);
                WeightechThemes.setCustoms(mode: AdaptiveThemeMode.dark);
              } else if (!(AppSettings.isDarkMode ?? true)) {
                WeightechThemes.disableMicaEffect(AdaptiveThemeMode.light);
                WeightechThemes.setCustoms(mode: AdaptiveThemeMode.light);
              } else {
                WeightechThemes.setMicaEffect(AdaptiveThemeMode.system);
                WeightechThemes.setCustoms(mode: AdaptiveThemeMode.system);
              }
            }
          });

          return FluentApp(
              //themeMode: WeightechThemes.mode,
              theme: theme,
              darkTheme: darkTheme,
              // darkTheme: WeightechThemes.fluentDarkTheme,
              title: "Weightech Inc. Sales",
              //theme: WeightechThemes.lightTheme,
              home: const StartupPage());
        });
  }
}
