import 'package:flutter/material.dart';

ThemeData get lightTheme => ThemeData(
  useMaterial3: true,
  colorSchemeSeed: Colors.blue,
  brightness: Brightness.light,
);

ThemeData get darkTheme => ThemeData(
  useMaterial3: true,
  colorSchemeSeed: Colors.blue,
  brightness: Brightness.dark,
);
