import 'package:flutter/material.dart' as material;
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:google_fonts/google_fonts.dart';

class WeightechThemes {
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
    typography: fluent.Typography.fromBrightness(brightness: fluent.Brightness.light),
    activeColor: const fluent.Color(0xFF224190),
    inactiveColor: const fluent.Color(0xFFC9C9CC),
    fontFamily: 'Open Sans',
    scaffoldBackgroundColor: fluent.Colors.white,
    buttonTheme: fluent.ButtonThemeData(
      defaultButtonStyle: fluent.ButtonStyle(
        foregroundColor: fluent.ButtonState.all<fluent.Color>(fluent.Colors.white),
        backgroundColor: fluent.ButtonState.all<fluent.Color>(const fluent.Color(0xFFC9C9CC)),
      ),
      filledButtonStyle: fluent.ButtonStyle(
        foregroundColor: fluent.ButtonState.all<fluent.Color>(fluent.Colors.white),
        backgroundColor: fluent.ButtonState.all<fluent.Color>(const fluent.Color(0xFF224190)),
      )
    )
  );
}