import 'package:flutter/material.dart';

/// Palette CantiTrack : vert forêt adouci sur fond crème (sans orange).
class Couleurs {
  static const vert = Color(0xFF2F6B4F);
  static const vertFonce = Color(0xFF1F4D38);
  static const vertClair = Color(0xFFE3EFE8);
  static const fond = Color(0xFFF4F1EA);
  static const texte = Color(0xFF1A2B20);
  static const texteSecondaire = Color(0xFF4A5C50);
  static const alerte = Color(0xFFB42318);
  static const alerteFond = Color(0xFFFDECEA);
  static const bordure = Color(0xFFDDE3DA);
}

const styleSecondaire = TextStyle(color: Couleurs.texteSecondaire, fontSize: 13);

ThemeData construireTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: Couleurs.vert,
    brightness: Brightness.light,
  ).copyWith(
    primary: Couleurs.vert,
    onPrimary: Colors.white,
    error: Couleurs.alerte,
    surface: Colors.white,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: Couleurs.fond,
    appBarTheme: const AppBarTheme(
      backgroundColor: Couleurs.vert,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: Couleurs.vertClair,
      labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
            color: states.contains(WidgetState.selected) ? Couleurs.vert : Couleurs.texteSecondaire,
          )),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: Couleurs.vert,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: Couleurs.vert,
        side: const BorderSide(color: Couleurs.vert, width: 1.5),
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Couleurs.vert,
      foregroundColor: Colors.white,
    ),
  );
}
