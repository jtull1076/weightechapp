import 'package:flutter/material.dart';

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
    fontFamily: 'Arial'
  );
}