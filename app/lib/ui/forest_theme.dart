import 'package:material_ui/material_ui.dart';

/// Material fallback surfaces share the current Figma palette and typography.
ThemeData forestTheme() => ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  fontFamily: 'DMSans',
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xffeacb80),
    brightness: Brightness.dark,
    surface: const Color(0xff172c23),
  ),
  scaffoldBackgroundColor: const Color(0xff101e19),
  textTheme: ThemeData.dark().textTheme.apply(
    fontFamily: 'DMSans',
    bodyColor: const Color(0xfffff1d2),
    displayColor: const Color(0xfffff1d2),
  ),
  snackBarTheme: const SnackBarThemeData(
    backgroundColor: Color(0xff243d31),
    contentTextStyle: TextStyle(fontFamily: 'DMSans', color: Color(0xfffff1d2)),
  ),
);
