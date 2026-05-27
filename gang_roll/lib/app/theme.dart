// gang.roll — design system, matched to the mobile prototype
// (Downloads/gang-roll-prototype.html), per the 2026-05-27 frontend direction.
//
// Warm, editorial, film-camera feel. A single coral accent does the
// punctuation; everything else is cream, paper, and ink. The PRIMARY CTA is
// dark ink (not coral) — coral is reserved for accents, the "New roll" card,
// the Live badge, and active states.
//
// Typography: Fraunces (display serif, used UPRIGHT by default with italic
// coral *emphasis* words), Inter (body/UI), JetBrains Mono (codes, counts,
// dates, eyebrow labels). Pulled at runtime via google_fonts.
//
// Light mode only in v1.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  // ── Color palette (prototype) ──────────────────────────────────────────
  static const Color coral = Color(0xFFE85A47); // primary accent
  static const Color coralDeep = Color(0xFFC84634);
  static const Color amber = Color(0xFFE8A547); // "Developing" badge
  static const Color sage = Color(0xFF7A8B6F); // "Developed/Done" badge

  static const Color cream = Color(0xFFF4EDE0); // scaffold background
  static const Color cream2 = Color(0xFFEDE3D2); // pressed / filled surfaces
  static const Color paper = Color(0xFFFAF6EE); // cards & components

  static const Color ink = Color(0xFF1A1A1A); // primary text, dark surfaces
  static const Color ink2 = Color(0xFF3A3A38); // body text
  static const Color muted = Color(0xFF8A8378); // metadata, captions

  static final Color line = const Color(0xFF1A1A1A).withValues(alpha: 0.10);
  static final Color line2 = const Color(0xFF1A1A1A).withValues(alpha: 0.06);
  static const Color softShadow = Color.fromRGBO(26, 26, 26, 0.18);
  static const Color glassOverlay = Color.fromRGBO(255, 255, 255, 0.65);

  // ── Radii ────────────────────────────────────────────────────────────────
  static const double radiusCard = 18;
  static const double radiusButton = 14;
  static const double radiusChip = 12;
  static const double radiusSheet = 24;
  static const double radiusPill = 999;

  // ── Button styles ──────────────────────────────────────────────────────
  // Primary CTA = dark ink, cream text, 14px radius (prototype .btn-primary).
  static ButtonStyle get primaryButton => FilledButton.styleFrom(
        backgroundColor: ink,
        foregroundColor: cream,
        disabledBackgroundColor: ink.withValues(alpha: 0.35),
        padding: const EdgeInsets.symmetric(vertical: 18),
        minimumSize: const Size.fromHeight(56),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusButton),
        ),
        textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
        elevation: 0,
      );

  // Accent CTA = coral (prototype .lb-cta / coral action card).
  static ButtonStyle get coralButton => FilledButton.styleFrom(
        backgroundColor: coral,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 18),
        minimumSize: const Size.fromHeight(56),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusButton),
        ),
        textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
        elevation: 0,
      );

  // Soft "social" button — paper fill, hairline border (prototype .social-btn).
  static ButtonStyle get softButton => OutlinedButton.styleFrom(
        backgroundColor: paper,
        foregroundColor: ink,
        padding: const EdgeInsets.symmetric(vertical: 16),
        minimumSize: const Size.fromHeight(52),
        side: BorderSide(color: line),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusButton),
        ),
        textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
      );

  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: coral,
      brightness: Brightness.light,
      primary: coral,
      onPrimary: Colors.white,
      secondary: amber,
      surface: cream,
      onSurface: ink,
      surfaceContainerHighest: paper,
      outline: line,
      outlineVariant: line2,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: cream,
      splashColor: coral.withValues(alpha: 0.08),
      highlightColor: coral.withValues(alpha: 0.04),
      textTheme: _textTheme(),
      appBarTheme: AppBarTheme(
        backgroundColor: cream,
        foregroundColor: ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.fraunces(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: ink,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(style: primaryButton),
      outlinedButtonTheme: OutlinedButtonThemeData(style: softButton),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: ink2,
          textStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
        ),
      ),
      // Underline fields (prototype .field input) — static mono label sits
      // above via the LabeledField widget; no floating Material label.
      inputDecorationTheme: InputDecorationTheme(
        filled: false,
        isDense: true,
        contentPadding: const EdgeInsets.only(top: 8, bottom: 12),
        hintStyle: GoogleFonts.fraunces(
          fontSize: 17,
          color: ink.withValues(alpha: 0.25),
        ),
        border: UnderlineInputBorder(borderSide: BorderSide(color: ink, width: 1.5)),
        enabledBorder:
            UnderlineInputBorder(borderSide: BorderSide(color: ink, width: 1.5)),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: coral, width: 1.5),
        ),
      ),
      cardTheme: CardThemeData(
        color: paper,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusCard),
          side: BorderSide(color: line),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: paper,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(radiusSheet)),
        ),
      ),
      dividerTheme: DividerThemeData(color: line2, thickness: 1, space: 1),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: ink,
        contentTextStyle: GoogleFonts.inter(fontSize: 13, color: cream),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusChip),
        ),
      ),
    );
  }

  // Type scale per prototype. Fraunces is UPRIGHT here; italic is applied only
  // to emphasis words (see HeroTitle / AppText.emphasis).
  static TextTheme _textTheme() {
    final fraunces = GoogleFonts.frauncesTextTheme();
    final inter = GoogleFonts.interTextTheme();

    TextStyle display(TextStyle? base, double size, {double height = 1.1}) =>
        (base ?? const TextStyle()).copyWith(
          fontSize: size,
          fontWeight: FontWeight.w600,
          color: ink,
          height: height,
          letterSpacing: -size * 0.03,
        );

    return TextTheme(
      displayLarge: display(fraunces.displayLarge, 56, height: 1.0),
      displayMedium: display(fraunces.displayMedium, 36),
      displaySmall: display(fraunces.displaySmall, 30),
      headlineMedium: display(fraunces.headlineMedium, 24),
      headlineSmall: display(fraunces.headlineSmall, 20),
      titleLarge: inter.titleLarge?.copyWith(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: ink,
      ),
      titleMedium: inter.titleMedium?.copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: ink,
      ),
      bodyLarge: inter.bodyLarge?.copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: ink2,
        height: 1.5,
      ),
      bodyMedium: inter.bodyMedium?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: ink2,
        height: 1.5,
      ),
      bodySmall: inter.bodySmall?.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: muted,
        height: 1.4,
      ),
      labelLarge: inter.labelLarge?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: ink,
      ),
    );
  }
}

/// Typography helpers for cases the [TextTheme] can't express.
class AppText {
  AppText._();

  /// JetBrains Mono — codes, counts, dates.
  static TextStyle mono({
    double fontSize = 12,
    FontWeight fontWeight = FontWeight.w500,
    double? letterSpacing,
    Color? color,
  }) =>
      GoogleFonts.jetBrainsMono(
        fontSize: fontSize,
        fontWeight: fontWeight,
        letterSpacing: letterSpacing,
        color: color ?? AppTheme.ink,
      );

  /// Mono uppercase eyebrow label (field labels, section tags). e.g. "CODE".
  static TextStyle label({Color? color, double fontSize = 10}) =>
      GoogleFonts.jetBrainsMono(
        fontSize: fontSize,
        fontWeight: FontWeight.w500,
        letterSpacing: 1.5,
        color: color ?? AppTheme.muted,
      );

  /// Fraunces upright — display base.
  static TextStyle display({double fontSize = 30, Color? color}) =>
      GoogleFonts.fraunces(
        fontSize: fontSize,
        fontWeight: FontWeight.w600,
        letterSpacing: -fontSize * 0.03,
        color: color ?? AppTheme.ink,
        height: 1.1,
      );

  /// Fraunces italic coral — the emphasized word inside a hero title.
  static TextStyle emphasis({double fontSize = 30, Color? color}) =>
      GoogleFonts.fraunces(
        fontSize: fontSize,
        fontWeight: FontWeight.w500,
        fontStyle: FontStyle.italic,
        letterSpacing: -fontSize * 0.03,
        color: color ?? AppTheme.coral,
        height: 1.1,
      );
}
