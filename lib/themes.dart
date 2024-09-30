import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class WeightechThemes {
  static late ThemeData materialTheme;
  static late Color defaultTextColor;
  static const Color weightechBlue = Color(0xFF224190);
  static const Color weightechGray = Color(0xFFC9C9CC);
  static const Color weightechOrange = Color(0xFFF48128);
  static const Color light = Color(0xFFF3F3F3);
  WeightechThemes(){
    // Brightness brightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
    const brightness = Brightness.light;
    if (brightness == Brightness.dark) {
      materialTheme = materialDarkTheme;
      defaultTextColor = Colors.white;
    }
    else {
      materialTheme = materialLightTheme;
      defaultTextColor = Colors.black;
    }
  }


  static final ThemeData materialLightTheme = ThemeData(
    scaffoldBackgroundColor: Colors.white,
    cardTheme: CardTheme(
      color: Colors.white,
      shadowColor: const Color(0xAA000000),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8)
      )
    ),
    textTheme: GoogleFonts.openSansTextTheme(),
    colorScheme: ColorScheme.fromSeed(seedColor: weightechBlue, brightness: Brightness.light),
    dialogTheme: const DialogTheme(
      surfaceTintColor: Colors.white,
    ),
  );


  static final ThemeData materialDarkTheme = ThemeData(
    scaffoldBackgroundColor: const Color(0xFF202020),
    cardTheme: CardTheme(
      color: const Color(0xFF202020),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8)
      )
    ),
    textTheme: GoogleFonts.openSansTextTheme(),
    colorScheme: ColorScheme.fromSeed(seedColor: weightechBlue, brightness: Brightness.dark),
    dialogTheme: const DialogTheme(
      surfaceTintColor: Color(0xFF202020),
    ),
  );
}