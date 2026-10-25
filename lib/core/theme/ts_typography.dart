import 'package:flutter/material.dart';
import 'ts_palette.dart';

/// Skala tipografi dan tema TugasScroll sesuai Bagian 4 & 12 `design.md`.
///
/// Keluarga font:
/// - UI & navigasi: `PlusJakartaSans`
/// - Isi halaman (soal, jawaban, pembahasan, catatan): `Literata`
/// - Teks Arab: `NotoNaskhArabic`
/// - Mode ramah disleksia: `AtkinsonHyperlegible` menggantikan Literata & Plus Jakarta Sans
class TsTypography {
  const TsTypography._();

  static const String uiFont = 'PlusJakartaSans';
  static const String pageFont = 'Literata';
  static const String arabicFont = 'NotoNaskhArabic';
  static const String dyslexiaFont = 'AtkinsonHyperlegible';

  /// Judul layar: Plus Jakarta Sans 24 / 30, weight 700
  static TextStyle screenTitle(
    TsPalette palette, {
    bool dyslexiaFriendly = false,
  }) => TextStyle(
    fontFamily: dyslexiaFriendly ? dyslexiaFont : uiFont,
    fontSize: 24,
    height: 30 / 24,
    fontWeight: FontWeight.w700,
    color: palette.ink,
    letterSpacing: 0,
  );

  /// Judul bagian: Plus Jakarta Sans 18 / 24, weight 600
  static TextStyle sectionTitle(
    TsPalette palette, {
    bool dyslexiaFriendly = false,
  }) => TextStyle(
    fontFamily: dyslexiaFriendly ? dyslexiaFont : uiFont,
    fontSize: 18,
    height: 24 / 18,
    fontWeight: FontWeight.w600,
    color: palette.ink,
    letterSpacing: 0,
  );

  /// Soal di kartu: Literata 21 / 32, weight 500
  static TextStyle cardQuestion(
    TsPalette palette, {
    bool dyslexiaFriendly = false,
  }) => TextStyle(
    fontFamily: dyslexiaFriendly ? dyslexiaFont : pageFont,
    fontSize: 21,
    height: 32 / 21,
    fontWeight: FontWeight.w500,
    color: palette.ink,
    letterSpacing: 0,
  );

  /// Jawaban dan pembahasan: Literata 18 / 29, weight 400
  static TextStyle cardAnswer(
    TsPalette palette, {
    bool dyslexiaFriendly = false,
  }) => TextStyle(
    fontFamily: dyslexiaFriendly ? dyslexiaFont : pageFont,
    fontSize: 18,
    height: 29 / 18,
    fontWeight: FontWeight.w400,
    color: palette.ink,
    letterSpacing: 0,
  );

  /// Isi catatan: Literata 17 / 27, weight 400
  static TextStyle noteBody(
    TsPalette palette, {
    bool dyslexiaFriendly = false,
  }) => TextStyle(
    fontFamily: dyslexiaFriendly ? dyslexiaFont : pageFont,
    fontSize: 17,
    height: 27 / 17,
    fontWeight: FontWeight.w400,
    color: palette.ink,
    letterSpacing: 0,
  );

  /// Label tombol dan chip: Plus Jakarta Sans 15 / 20, weight 600
  static TextStyle buttonAndChip(
    TsPalette palette, {
    bool dyslexiaFriendly = false,
    Color? color,
  }) => TextStyle(
    fontFamily: dyslexiaFriendly ? dyslexiaFont : uiFont,
    fontSize: 15,
    height: 20 / 15,
    fontWeight: FontWeight.w600,
    color: color ?? palette.ink,
    letterSpacing: 0,
  );

  /// Keterangan: Plus Jakarta Sans 13 / 18, weight 500
  static TextStyle caption(
    TsPalette palette, {
    bool dyslexiaFriendly = false,
    Color? color,
  }) => TextStyle(
    fontFamily: dyslexiaFriendly ? dyslexiaFont : uiFont,
    fontSize: 13,
    height: 18 / 13,
    fontWeight: FontWeight.w500,
    color: color ?? palette.pencil,
    letterSpacing: 0,
  );

  /// Teks Arab di kartu: Noto Naskh Arabic 24 / 42, weight 400
  static TextStyle arabicCardText(TsPalette palette) => TextStyle(
    fontFamily: arabicFont,
    fontSize: 24,
    height: 42 / 24,
    fontWeight: FontWeight.w400,
    color: palette.ink,
  );

  /// Membuat `ThemeData` lengkap untuk Malam atau Siang sesuai aturan `design.md`.
  static ThemeData buildTheme({
    required TsPalette palette,
    bool dyslexiaFriendly = false,
  }) {
    final baseFont = dyslexiaFriendly ? dyslexiaFont : uiFont;
    return ThemeData(
      useMaterial3: true,
      brightness: palette.isNight ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: palette.bg,
      fontFamily: baseFont,
      colorScheme: ColorScheme(
        brightness: palette.isNight ? Brightness.dark : Brightness.light,
        primary: palette.primaryAction,
        onPrimary: palette.onPrimaryAction,
        secondary: palette.stabilo,
        onSecondary: palette.bg,
        error: palette.penRed,
        onError: palette.bg,
        surface: palette.page,
        onSurface: palette.ink,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: palette.bg,
        foregroundColor: palette.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: screenTitle(
          palette,
          dyslexiaFriendly: dyslexiaFriendly,
        ),
      ),
      cardTheme: CardThemeData(
        color: palette.page,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: palette.line, width: 1),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: palette.raised,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: palette.line,
        thickness: 1,
        space: 1,
      ),
      textTheme: TextTheme(
        headlineMedium: screenTitle(
          palette,
          dyslexiaFriendly: dyslexiaFriendly,
        ),
        titleMedium: sectionTitle(
          palette,
          dyslexiaFriendly: dyslexiaFriendly,
        ),
        bodyLarge: cardQuestion(
          palette,
          dyslexiaFriendly: dyslexiaFriendly,
        ),
        bodyMedium: cardAnswer(
          palette,
          dyslexiaFriendly: dyslexiaFriendly,
        ),
        bodySmall: caption(
          palette,
          dyslexiaFriendly: dyslexiaFriendly,
        ),
        labelLarge: buttonAndChip(
          palette,
          dyslexiaFriendly: dyslexiaFriendly,
        ),
      ),
      extensions: <ThemeExtension<dynamic>>[palette],
    );
  }
}
