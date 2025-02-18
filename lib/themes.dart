import 'dart:ui';
import 'package:flutter/material.dart' as material;
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart';
import 'package:provider/provider.dart';
import 'package:weightechapp/utils.dart';
import 'package:adaptive_theme_fluent_ui/adaptive_theme_fluent_ui.dart';
import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:window_manager/window_manager.dart';

class WeightechTheme extends ChangeNotifier {
  static late AdaptiveThemeMode? startupTheme;
  static late fluent.FluentThemeData currentTheme;
  static late fluent.ThemeMode themeMode;
  static late bool isDarkMode;
  // static late fluent.Color defaultBackgroundColor;
  // static late fluent.Color commandBarColor;
  // static late fluent.Color startupScaffoldColor;
  static late fluent.Color infoWidgetColor;
  static late fluent.Color loadingAnimationColor;
  static late fluent.Color fileDropColor;
  static late fluent.TextStyle dialogTitleStyle;
  static const fluent.Color weightechBlue = Color(0xFF224190);
  static const fluent.Color weightechGray = Color(0xFFC9C9CC);
  static const fluent.Color weightechOrange = Color(0xFFF48128);
  static const fluent.Color windowsLight = Color(0xFFF3F3F3);
  static const fluent.Color windowsDark = Color(0xFF202020);
  static final fluent.AccentColor wtBlue = fluent.AccentColor.swatch(const {
    'darkest': Color(0xff0a142b),
    'darker': Color(0xff0f1d40),
    'dark': Color(0xff152959),
    'normal': weightechBlue,
    'light': Color(0xff2d55bb),
    'lighter': Color(0xff3666df),
    'lightest': Color(0xff3d74ff),
  });
  static final fluent.AccentColor wtGray = fluent.AccentColor.swatch(const {
    'darkest': Color(0xFF3b3b3c),
    'darker': Color(0xFF5c5c5d),
    'dark': Color(0xFF808081),
    'normal': weightechGray,
    'light': Color(0xffd9d9dB),
    'lighter': Color(0xffe9e9eB),
    'lightest': Color(0xfff4f4f9),
  });
  WeightechTheme();

  Future<void> initializeTheme() async {
    // Default to light theme if AppSettings.isDarkMode is null

    if (AppSettings.isDarkMode != null) {
      if (AppSettings.isDarkMode!) {
        themeMode = fluent.ThemeMode.dark;
      }
      else {
        themeMode = fluent.ThemeMode.light;
      }
    }
    else {
      themeMode = fluent.ThemeMode.system;
    }


    if (themeMode == fluent.ThemeMode.system) {
      var brightness = SchedulerBinding.instance.platformDispatcher.platformBrightness;
      isDarkMode = brightness == Brightness.dark;
      var dark = isDarkMode;
      debugPrint(dark.toString());
    }
    else {
      isDarkMode = themeMode == fluent.ThemeMode.dark;
    }

    currentTheme = isDarkMode ? fluentDarkTheme : fluentLightTheme;

    _applyThemeCustoms();
    
  }

  // Set properties dynamically based on theme
  void _applyThemeCustoms() {
    infoWidgetColor = isDarkMode ? wtGray.darkest : wtGray.lightest;
    loadingAnimationColor = isDarkMode ? weightechOrange : weightechBlue;
    fileDropColor = isDarkMode ? weightechOrange : weightechBlue;
    dialogTitleStyle = TextStyle(
      color: isDarkMode ? weightechGray : weightechBlue,
      fontSize: 18,
    );

    if (AppSettings.useMica ?? false) {
      if (WeightechTheme.isDarkMode) {
        WeightechTheme.setMicaEffect(fluent.ThemeMode.dark);
        WeightechTheme.setCustoms(mode: fluent.ThemeMode.dark);
      } else {
        WeightechTheme.setMicaEffect(fluent.ThemeMode.light);
        WeightechTheme.setCustoms(mode: fluent.ThemeMode.light);
      }
    } else {
      if (WeightechTheme.isDarkMode) {
        WeightechTheme.disableMicaEffect(fluent.ThemeMode.dark);
        WeightechTheme.setCustoms(mode: fluent.ThemeMode.dark);
      } else {
        WeightechTheme.disableMicaEffect(fluent.ThemeMode.light);
        WeightechTheme.setCustoms(mode: fluent.ThemeMode.light);
      }
    }

    notifyListeners();
  }

  static Future<void> setCustoms({fluent.ThemeMode? mode}) async {
    if (mode == fluent.ThemeMode.light) {
      infoWidgetColor = wtGray.lightest;
      loadingAnimationColor = wtBlue.normal;
      fileDropColor = weightechBlue;
      dialogTitleStyle = const TextStyle(color: weightechBlue, fontSize: 18);
    } else if (mode == fluent.ThemeMode.dark) {
      infoWidgetColor = wtGray.darkest;
      loadingAnimationColor = weightechOrange;
      fileDropColor = weightechOrange;
    } else {
      if (isDarkMode) {
        infoWidgetColor = wtGray.darkest;
        loadingAnimationColor = weightechOrange;
        fileDropColor = weightechOrange;
        currentTheme = fluentDarkTheme;
      } else {
        infoWidgetColor = wtGray.lightest;
        loadingAnimationColor = wtBlue.normal;
        fileDropColor = weightechBlue;
        dialogTitleStyle = const TextStyle(color: weightechBlue, fontSize: 18);
        currentTheme = fluentLightTheme;
      }
    }
  }

  // Function to set the Mica effect based on the current theme mode
  static Future<void> setMicaEffect(fluent.ThemeMode mode) async {
    AppSettings.useMica = true;
    var dark = isDarkMode;
    if (mode == fluent.ThemeMode.light) {
      await Window.setEffect(effect: WindowEffect.mica, dark: false);
    } else if (mode == fluent.ThemeMode.dark) {
      await Window.setEffect(effect: WindowEffect.mica, dark: true);
    } else {
      await Window.setEffect(effect: WindowEffect.mica, dark: isDarkMode);
    }
  }

  // Function to set the Mica effect based on the current theme mode
  static Future<void> disableMicaEffect(fluent.ThemeMode mode) async {
    AppSettings.useMica = false;
    if (mode == fluent.ThemeMode.light) {
      await Window.setEffect(effect: WindowEffect.solid, color: windowsLight);
    } else if (mode == fluent.ThemeMode.dark) {
      await Window.setEffect(effect: WindowEffect.solid, color: windowsDark);
    } else {
      await Window.setEffect(
          effect: WindowEffect.solid,
          color: (isDarkMode) ? windowsDark : windowsLight);
    }
  }

  static Future<void> setWindowEffect({effect, darkMode, color}) async {
    final isDark = isDarkMode;
    await Window.setEffect(
      effect: effect ??
          ((AppSettings.useMica ?? false)
              ? WindowEffect.mica
              : WindowEffect.solid),
      dark: darkMode ?? isDarkMode,
      color: color ??
          (fluent.Colors
              .transparent), // WeightechThemes.windowsLight : WeightechThemes.windowsLight
    );
  }

  static Future<void> setMica(useMica) async {
    await setWindowEffect(
      effect: (useMica ? WindowEffect.mica : WindowEffect.solid)
    );
  }

  static Future<void> setColorMode(BuildContext context, fluent.ThemeMode colorMode) async {
    switch (colorMode) {
      case (fluent.ThemeMode.dark):
        {
          await setDarkMode(context);
        }
      case (fluent.ThemeMode.light):
        {
          await setLightMode(context);
        }
      case (fluent.ThemeMode.system):
        {
          await setSystemMode(context);
        }
    }
    
    
  }

  static Future<void> setDarkMode(BuildContext context) async {
    isDarkMode = true;
    themeMode = fluent.ThemeMode.dark;
    AppSettings.isDarkMode = true;
    // FluentAdaptiveTheme.of(context).setDark();
    // FluentAdaptiveTheme.of(context).persist();
  }

  static Future<void> setLightMode(BuildContext context) async {
    isDarkMode = false;
    AppSettings.isDarkMode = false;
    themeMode = fluent.ThemeMode.light;
    // FluentAdaptiveTheme.of(context).setLight();
    // FluentAdaptiveTheme.of(context).persist();
  }

  static Future<void> setSystemMode(BuildContext context) async {
    // FluentAdaptiveTheme.of(context).setSystem();
    // FluentAdaptiveTheme.of(context).persist();
    themeMode = fluent.ThemeMode.system;
    // isDarkMode = FluentAdaptiveTheme.of(context).brightness!.isDark;
    AppSettings.isDarkMode = null;
    isDarkMode;
  }

  static final material.ThemeData materialLightTheme = material.ThemeData(
    scaffoldBackgroundColor: material.Colors.white,
    cardTheme: material.CardTheme(
        color: material.Colors.white,
        shadowColor: const Color(0xAA000000),
        elevation: 4,
        shape: material.RoundedRectangleBorder(
            borderRadius: material.BorderRadius.circular(8))),
    textTheme: GoogleFonts.openSansTextTheme(),
    colorScheme: material.ColorScheme.fromSeed(
        seedColor: weightechBlue, brightness: material.Brightness.light),
    dialogTheme: const material.DialogTheme(
      surfaceTintColor: material.Colors.white,
    ),
  );

  static fluent.FluentThemeData fluentLightTheme =
      fluent.FluentThemeData().copyWith(
          brightness: fluent.Brightness.light,
          // fontFamily: 'Segoe UI',
          typography: fluent.Typography.fromBrightness(
              brightness: fluent.Brightness.light),
          accentColor: wtBlue,
          activeColor: weightechBlue,
          inactiveColor: weightechGray,
          cardColor: (AppSettings.useMica ?? true)
              ? fluent.Colors.transparent
              : windowsLight,
          scaffoldBackgroundColor: (AppSettings.useMica ?? false)
              ? fluent.Colors.transparent
              : windowsLight,
          dialogTheme: fluent.ContentDialogThemeData(
            titleStyle: const TextStyle(
                color: WeightechTheme.weightechBlue, fontSize: 18),
            decoration: BoxDecoration(
              color: fluent.Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: fluent.kElevationToShadow[6],
            ),
            padding: const EdgeInsets.all(20),
            titlePadding: const EdgeInsetsDirectional.only(bottom: 12),
            actionsSpacing: 10,
            actionsDecoration: const BoxDecoration(
              color: windowsLight,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
              // boxShadow: kElevationToShadow[1],
            ),
            actionsPadding: const EdgeInsets.all(20),
          ),
          buttonTheme: fluent.ButtonThemeData(
            defaultButtonStyle: fluent.ButtonStyle(
              textStyle: WidgetStatePropertyAll<TextStyle>(TextStyle(
                  fontFamily: 'Segoe UI',
                  letterSpacing: 0.3,
                  textBaseline: TextBaseline.alphabetic,
                  height: 1.4,
                  decoration: TextDecoration.none,
                  wordSpacing: 1,
                  decorationThickness: 1)),
            ),
            outlinedButtonStyle: fluent.ButtonStyle(
              textStyle: WidgetStatePropertyAll<TextStyle>(TextStyle(
                  fontFamily: 'Segoe UI',
                  letterSpacing: 0.3,
                  textBaseline: TextBaseline.alphabetic,
                  height: 1.4,
                  decoration: TextDecoration.none,
                  wordSpacing: 1,
                  decorationThickness: 1)),
              backgroundColor: fluent.WidgetStatePropertyAll<Color>(
                  fluent.Colors.transparent),
              foregroundColor:
                  fluent.WidgetStatePropertyAll<Color>(wtGray.darker),
            ),
            filledButtonStyle: fluent.ButtonStyle(
              backgroundColor: fluent.WidgetStatePropertyAll<Color>(
                  WeightechTheme.weightechBlue),
              foregroundColor:
                  fluent.WidgetStatePropertyAll<Color>(fluent.Colors.white),
              textStyle: WidgetStatePropertyAll<TextStyle>(TextStyle(
                  fontFamily: 'Segoe UI',
                  letterSpacing: 0.3,
                  textBaseline: TextBaseline.alphabetic,
                  height: 1.4,
                  decoration: TextDecoration.none,
                  wordSpacing: 1,
                  decorationThickness: 1)),
            ),
            iconButtonStyle: fluent.ButtonStyle(
              textStyle: WidgetStatePropertyAll<TextStyle>(TextStyle(
                  fontFamily: 'Segoe UI',
                  letterSpacing: 0.3,
                  textBaseline: TextBaseline.alphabetic,
                  height: 1.4,
                  decoration: TextDecoration.none,
                  wordSpacing: 1,
                  decorationThickness: 1)),
            ),
          ),
          tooltipTheme: const fluent.TooltipThemeData());

  static final material.ThemeData materialDarkTheme = material.ThemeData(
    scaffoldBackgroundColor: const material.Color(0xFF202020),
    cardTheme: material.CardTheme(
        color: const material.Color(0xFF202020),
        elevation: 4,
        shape: material.RoundedRectangleBorder(
            borderRadius: material.BorderRadius.circular(8))),
    textTheme: GoogleFonts.openSansTextTheme(),
    colorScheme: material.ColorScheme.fromSeed(
        seedColor: weightechBlue, brightness: material.Brightness.dark),
    dialogTheme: const material.DialogTheme(
      surfaceTintColor: material.Color(0xFF202020),
    ),
  );

  static fluent.FluentThemeData fluentDarkTheme =
      fluent.FluentThemeData.dark().copyWith(
          brightness: fluent.Brightness.dark,
          // fontFamily: 'Segoe UI',
          typography: fluent.Typography.fromBrightness(
              brightness: fluent.Brightness.dark),
          accentColor: wtGray,
          activeColor: weightechOrange,
          inactiveColor: wtGray.darkest,
          cardColor: (AppSettings.useMica ?? false)
              ? fluent.Colors.transparent
              : windowsDark,
          scaffoldBackgroundColor: (AppSettings.useMica ?? true)
              ? fluent.Colors.transparent
              : windowsDark,
          dialogTheme: fluent.ContentDialogThemeData(
            titleStyle: const TextStyle(
                color: WeightechTheme.weightechGray, fontSize: 18),
            decoration: BoxDecoration(
              color: windowsDark,
              borderRadius: BorderRadius.circular(12),
              boxShadow: fluent.kElevationToShadow[6],
            ),
            padding: const EdgeInsets.all(20),
            titlePadding: const EdgeInsetsDirectional.only(bottom: 12),
            actionsSpacing: 10,
            actionsDecoration: const BoxDecoration(
              color: windowsDark,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
              // boxShadow: kElevationToShadow[1],
            ),
            actionsPadding: const EdgeInsets.all(20),
          ),
          buttonTheme: fluent.ButtonThemeData(
            defaultButtonStyle: fluent.ButtonStyle(
              textStyle: WidgetStatePropertyAll<TextStyle>(TextStyle(
                  fontFamily: 'Segoe UI',
                  letterSpacing: 0.3,
                  textBaseline: TextBaseline.alphabetic,
                  height: 1.4,
                  decoration: TextDecoration.none,
                  wordSpacing: 1,
                  decorationThickness: 1)),
            ),
            outlinedButtonStyle: fluent.ButtonStyle(
              textStyle: WidgetStatePropertyAll<TextStyle>(TextStyle(
                  fontFamily: 'Segoe UI',
                  letterSpacing: 0.3,
                  textBaseline: TextBaseline.alphabetic,
                  height: 1.4,
                  decoration: TextDecoration.none,
                  wordSpacing: 1,
                  decorationThickness: 1)),
              backgroundColor: fluent.WidgetStatePropertyAll<Color>(
                  fluent.Colors.transparent),
              foregroundColor:
                  fluent.WidgetStatePropertyAll<Color>(wtGray.lighter),
            ),
            filledButtonStyle: fluent.ButtonStyle(
              backgroundColor: fluent.WidgetStatePropertyAll<Color>(
                  WeightechTheme.weightechOrange),
              foregroundColor:
                  fluent.WidgetStatePropertyAll<Color>(fluent.Colors.white),
              textStyle: WidgetStatePropertyAll<TextStyle>(TextStyle(
                  fontFamily: 'Segoe UI',
                  letterSpacing: 0.3,
                  textBaseline: TextBaseline.alphabetic,
                  height: 1.4,
                  decoration: TextDecoration.none,
                  wordSpacing: 1,
                  decorationThickness: 1)),
            ),
            iconButtonStyle: fluent.ButtonStyle(
              textStyle: WidgetStatePropertyAll<TextStyle>(TextStyle(
                  fontFamily: 'Segoe UI',
                  letterSpacing: 0.3,
                  textBaseline: TextBaseline.alphabetic,
                  height: 1.4,
                  decoration: TextDecoration.none,
                  wordSpacing: 1,
                  decorationThickness: 1)),
            ),
          ),
          tooltipTheme: const fluent.TooltipThemeData());
}
