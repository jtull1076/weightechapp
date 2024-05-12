import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' as material;
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/widgets.dart';

class WeightechThemes {
  static late material.ThemeData materialTheme;
  static late fluent.FluentThemeData fluentTheme;
  static late fluent.Color commandBarColor;
  static late fluent.Color startupScaffoldColor;
  static late fluent.Color defaultTextColor;
  WeightechThemes(){
    Brightness brightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
    if (brightness == Brightness.dark) {
      materialTheme = materialDarkTheme;
      fluentTheme = fluentDarkTheme;
      commandBarColor = const fluent.Color(0xFF202020);
      startupScaffoldColor = const fluent.Color(0xFF202020);
      defaultTextColor = fluent.Colors.white;
    }
    else {
      materialTheme = materialLightTheme;
      fluentTheme = fluentLightTheme;
      commandBarColor = const fluent.Color(0xFFF3F3F3);
      startupScaffoldColor = const fluent.Color(0xFFF3F3F3);
      defaultTextColor = fluent.Colors.black;
    }
  }


  static final material.ThemeData materialLightTheme = material.ThemeData(
    scaffoldBackgroundColor: material.Colors.white,
    cardTheme: material.CardTheme(
      color: material.Colors.white,
      elevation: 4,
      shape: material.RoundedRectangleBorder(
        borderRadius: material.BorderRadius.circular(8)
      )
    ),
    textTheme: GoogleFonts.openSansTextTheme(),
    colorScheme: material.ColorScheme.fromSeed(seedColor: const material.Color(0xFF224190), brightness: material.Brightness.light),
    dialogTheme: const material.DialogTheme(
      surfaceTintColor: material.Colors.white,
    ),
  );

  static final fluent.FluentThemeData fluentLightTheme = fluent.FluentThemeData(
    brightness: fluent.Brightness.light,
    activeColor: const fluent.Color(0xFF224190),
    inactiveColor: const fluent.Color(0xFFC9C9CC),
    scaffoldBackgroundColor: const fluent.Color(0xFFFFFFFF),
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
    colorScheme: material.ColorScheme.fromSeed(seedColor: const material.Color(0xFF224190), brightness: material.Brightness.dark),
    dialogTheme: const material.DialogTheme(
      surfaceTintColor: material.Color(0xFF202020),
    ),
  );

  static final fluent.FluentThemeData fluentDarkTheme = fluent.FluentThemeData(
    brightness: fluent.Brightness.dark,
    activeColor: const fluent.Color(0xFF224190),
    
    inactiveColor: const fluent.Color(0xFF202020),
    scaffoldBackgroundColor: const fluent.Color(0xFF505050),
  );
}