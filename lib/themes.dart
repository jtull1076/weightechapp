import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class WeightechThemes {
  static final ThemeData lightTheme = ThemeData(
    scaffoldBackgroundColor: Colors.white,
    cardTheme: CardTheme(
      color: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8)
      )
    ),
    textTheme: GoogleFonts.openSansTextTheme(),
    colorScheme: ColorScheme.fromSeed(seedColor: Color.fromARGB(255, 12, 23, 50), brightness: Brightness.light)
    
  );
}