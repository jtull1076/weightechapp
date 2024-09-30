import 'dart:ui';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart' as material;
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/widgets.dart';

class WeightechThemes {
  static late material.ThemeData materialTheme;
  static late fluent.FluentThemeData fluentTheme;
  static late fluent.Color commandBarColor;
  static late fluent.Color startupScaffoldColor;
  static late fluent.Color defaultTextColor;
  static late fluent.Color infoWidgetColor;
  static late fluent.Color loadingAnimationColor;
  static late fluent.Color fileDropColor;
  static late fluent.TextStyle dialogTitleStyle;
  static const fluent.Color weightechBlue = Color(0xFF224190);
  static const fluent.Color weightechGray = Color(0xFFC9C9CC);
  static const fluent.Color weightechOrange = Color(0xFFF48128);
  static const fluent.Color windowsLight = Color(0xFFF3F3F3);
  static final fluent.AccentColor wtBlue = fluent.AccentColor
  .swatch(
    const {
      'darkest': Color(0xff0a142b),
      'darker': Color(0xff0f1d40),
      'dark': Color(0xff152959),
      'normal': weightechBlue,
      'light': Color(0xff2d55bb),
      'lighter': Color(0xff3666df),
      'lightest': Color(0xff3d74ff),
    }
  );
  static final fluent.AccentColor wtGray = fluent.AccentColor
  .swatch(
    const {
      'darkest': Color(0xFF3b3b3c),
      'darker': Color(0xFF5c5c5d),
      'dark': Color(0xFF808081),
      'normal': weightechGray,
      'light': Color(0xffd9d9dB),
      'lighter': Color(0xffe9e9eB),
      'lightest': Color(0xfff4f4f9),
    }
  );
  WeightechThemes(){
    // Brightness brightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
    const brightness = Brightness.light;
    if (brightness == Brightness.dark) {
      materialTheme = materialDarkTheme;
      fluentTheme = fluentDarkTheme;
      defaultTextColor = fluent.Colors.white;
      infoWidgetColor = wtGray.darker;
      loadingAnimationColor = wtGray.light;
      fileDropColor = const Color(0x44224190);
    }
    else {
      materialTheme = materialLightTheme;
      fluentTheme = fluentLightTheme;
      defaultTextColor = fluent.Colors.black;
      infoWidgetColor = wtGray.light;
      loadingAnimationColor = wtBlue.normal;
      fileDropColor = const Color(0x44224190);
      dialogTitleStyle = const TextStyle(color: WeightechThemes.weightechBlue, fontSize: 18);
    }
  }


  static final material.ThemeData materialLightTheme = material.ThemeData(
    scaffoldBackgroundColor: material.Colors.white,
    cardTheme: material.CardTheme(
      color: material.Colors.white,
      shadowColor: const Color(0xAA000000),
      elevation: 4,
      shape: material.RoundedRectangleBorder(
        borderRadius: material.BorderRadius.circular(8)
      )
    ),
    textTheme: GoogleFonts.openSansTextTheme(),
    colorScheme: material.ColorScheme.fromSeed(seedColor: weightechBlue, brightness: material.Brightness.light),
    dialogTheme: const material.DialogTheme(
      surfaceTintColor: material.Colors.white,
    ),
  );

  static final fluent.FluentThemeData fluentLightTheme = fluent.FluentThemeData(
    brightness: fluent.Brightness.light,
    fontFamily: 'Segoe UI',
    accentColor: wtBlue,
    activeColor: weightechBlue,
    inactiveColor: weightechGray,
    cardColor: windowsLight,
    scaffoldBackgroundColor: fluent.Colors.white,
    dialogTheme: fluent.ContentDialogThemeData(
      titleStyle: const TextStyle(color: WeightechThemes.weightechBlue, fontSize: 18),
      decoration: BoxDecoration(
        color: windowsLight,
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
    buttonTheme: const fluent.ButtonThemeData(
      defaultButtonStyle: fluent.ButtonStyle(
        textStyle: WidgetStatePropertyAll<TextStyle>(TextStyle(
          fontFamily: 'Segoe UI',
          letterSpacing: 0.3, 
          textBaseline: TextBaseline.alphabetic, 
          height: 1.4, 
          decoration: TextDecoration.none,
          backgroundColor: fluent.Colors.transparent,
          wordSpacing: 1,
          decorationThickness: 1
        )),
      ), 
      filledButtonStyle: fluent.ButtonStyle(
        backgroundColor: fluent.WidgetStatePropertyAll<Color>(WeightechThemes.weightechBlue),
        foregroundColor: fluent.WidgetStatePropertyAll<Color>(fluent.Colors.white),
        textStyle: WidgetStatePropertyAll<TextStyle>(TextStyle(
          fontFamily: 'Segoe UI',
          letterSpacing: 0.3, 
          textBaseline: TextBaseline.alphabetic, 
          height: 1.4, 
          decoration: TextDecoration.none,
          backgroundColor: fluent.Colors.transparent,
          wordSpacing: 1,
          decorationThickness: 1
        )),
      ),
      iconButtonStyle: fluent.ButtonStyle(
        textStyle: WidgetStatePropertyAll<TextStyle>(TextStyle(
          fontFamily: 'Segoe UI',
          letterSpacing: 0.3, 
          textBaseline: TextBaseline.alphabetic, 
          height: 1.4, 
          decoration: TextDecoration.none,
          backgroundColor: fluent.Colors.transparent,
          wordSpacing: 1,
          decorationThickness: 1
        )),
      ),    
    ),
    tooltipTheme: const fluent.TooltipThemeData(
    )
  );

  static final material.ThemeData materialDarkTheme = material.ThemeData(
    scaffoldBackgroundColor: const material.Color(0xFF202020),
    cardTheme: material.CardTheme(
      color: const material.Color(0xFF202020),
      elevation: 4,
      shape: material.RoundedRectangleBorder(
        borderRadius: material.BorderRadius.circular(8)
      )
    ),
    textTheme: GoogleFonts.openSansTextTheme(),
    colorScheme: material.ColorScheme.fromSeed(seedColor: weightechBlue, brightness: material.Brightness.dark),
    dialogTheme: const material.DialogTheme(
      surfaceTintColor: material.Color(0xFF202020),
    ),
  );

  static final fluent.FluentThemeData fluentDarkTheme = fluent.FluentThemeData(
    brightness: fluent.Brightness.dark,
    activeColor: weightechBlue,
    fontFamily: 'packages/google_fonts/Open Sans',
    inactiveColor: wtGray.darker,
    scaffoldBackgroundColor: windowsLight,
  );
}