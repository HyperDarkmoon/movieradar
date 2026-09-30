import 'package:flutter/material.dart';

/// Design tokens and theme data for the cinematic neon-violet look.
class Cinematic {
  Cinematic._();

  // Brand palette
  static const Color neonViolet = Color(0xFFC77DFF);
  static const Color deepViolet = Color(0xFF8B5CF6);
  static const Color nightViolet = Color(0xFF6D28D9);
  static const Color fuchsia = Color(0xFFE879F9);
  static const Color irisGlow = Color(0xFFA78BFA);

  // Dark surfaces
  static const Color bgTop = Color(0xFF0A0713);
  static const Color bgBottom = Color(0xFF150E2A);
  static const Color surface = Color(0xFF181129);
  static const Color surfaceBright = Color(0xFF251A42);
  static const Color line = Color(0xFF33275C);

  // Light surfaces
  static const Color glassLight = Color(0x14FFFFFF);
  static const Color glassDark = Color(0x1F000000);
  static const Color lineLight = Color(0x33FFD6FF);

  // Light surfacing (daymode)
  static const Color dayTop = Color(0xFFF6F0FE);
  static const Color dayBottom = Color(0xFFE9DDF8);
  static const Color surfaceLight = Color(0xE6FFFFFF);
  static const Color surfaceBrightLight = Color(0xFFFFFFFF);
  static const Color lineDay = Color(0x4DE5DAF7);
  static const Color glowDaySoft = Color(0x408B5CF6);

  // Text
  static const Color textPrimaryDark = Color(0xFFF3EDFF);
  static const Color textSecondaryDark = Color(0xFFB9ABE8);
  static const Color textPrimaryLight = Color(0xFF1E1231);
  static const Color textSecondaryLight = Color(0xFF6A5C8A);

  static const LinearGradient glowGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [neonViolet, deepViolet, nightViolet],
    stops: [0.1, 0.5, 0.95],
  );

  static const LinearGradient duskGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF3A1188), Color(0xFF1D0D3C), Color(0xFF0A0713)],
  );

  static const LinearGradient dayGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [dayTop, dayBottom],
  );

  static const Color appTitle = Color(0xFFEEDDFF);

  // ------------------------------------------------------------------
  // Theme-aware lookup helpers (adapt tokens to dark/light mode)
  // ------------------------------------------------------------------

  static Color textPrimaryOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? textPrimaryDark
          : textPrimaryLight;

  static Color textSecondaryOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? textSecondaryDark
          : textSecondaryLight;

  static Color surfaceOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? surface
          : surfaceLight;

  static Color surfaceBrightOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? surfaceBright
          : surfaceBrightLight;

  static Color bgOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? bgTop : dayTop;

  static Color lineOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? line : lineDay;

  static Color cardBorderOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? Colors.white.withValues(alpha: 0.08)
          : Cinematic.deepViolet.withValues(alpha: 0.14);

  static TextTheme textThemeOf(BuildContext context) =>
      Theme.of(context).textTheme;
}

/// Extra colors shared across the cinematic widgets.
class CinematicColors extends ThemeExtension<CinematicColors> {
  const CinematicColors({
    required this.glass,
    required this.glow,
    required this.glowSoft,
    required this.scrim,
    required this.borderGlow,
  });

  final Color glass;
  final Color glow;
  final Color glowSoft;
  final Color scrim;
  final Color borderGlow;

  @override
  CinematicColors copyWith({
    Color? glass,
    Color? glow,
    Color? glowSoft,
    Color? scrim,
    Color? borderGlow,
  }) {
    return CinematicColors(
      glass: glass ?? this.glass,
      glow: glow ?? this.glow,
      glowSoft: glowSoft ?? this.glowSoft,
      scrim: scrim ?? this.scrim,
      borderGlow: borderGlow ?? this.borderGlow,
    );
  }

  @override
  CinematicColors lerp(ThemeExtension<CinematicColors>? other, double t) {
    if (other is! CinematicColors) return this;
    return CinematicColors(
      glass: Color.lerp(glass, other.glass, t)!,
      glow: Color.lerp(glow, other.glow, t)!,
      glowSoft: Color.lerp(glowSoft, other.glowSoft, t)!,
      scrim: Color.lerp(scrim, other.scrim, t)!,
      borderGlow: Color.lerp(borderGlow, other.borderGlow, t)!,
    );
  }

  static CinematicColors of(BuildContext context) =>
      Theme.of(context).extension<CinematicColors>() ?? _fallback;

  static const _fallback = CinematicColors(
    glass: Color(0x14FFFFFF),
    glow: Cinematic.neonViolet,
    glowSoft: Color(0x59C77DFF),
    scrim: Color(0xA6000000),
    borderGlow: Color(0x66C77DFF),
  );
}

class CinematicTheme {
  CinematicTheme._();

  static ThemeData dark() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: Cinematic.neonViolet,
      brightness: Brightness.dark,
    ).copyWith(
      primary: Cinematic.neonViolet,
      onPrimary: const Color(0xFF210A3A),
      secondary: Cinematic.deepViolet,
      tertiary: Cinematic.fuchsia,
      surface: Cinematic.surface,
      surfaceContainerLowest: Cinematic.bgTop,
      surfaceContainerLow: const Color(0xFF120D22),
      surfaceContainer: const Color(0xFF1A1430),
      surfaceContainerHigh: const Color(0xFF221B3D),
      surfaceContainerHighest: const Color(0xFF2A2148),
      onSurface: Cinematic.textPrimaryDark,
      onSurfaceVariant: Cinematic.textSecondaryDark,
      outline: const Color(0xFF4A3F73),
      outlineVariant: Cinematic.line,
      error: const Color(0xFFFF7A90),
      onError: const Color(0xFF3D050F),
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
    );

    return base.copyWith(
      scaffoldBackgroundColor: Cinematic.bgTop,
      canvasColor: Cinematic.bgTop,
      extensions: const <ThemeExtension<dynamic>>[
        CinematicColors(
          glass: Cinematic.glassDark,
          glow: Cinematic.neonViolet,
          glowSoft: Color(0x59C77DFF),
          scrim: Color(0xB3000000),
          borderGlow: Color(0x73C77DFF),
        ),
      ],
      textTheme: _textTheme(base.textTheme, isDark: true),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        foregroundColor: Cinematic.textPrimaryDark,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: Cinematic.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: Color(0x2EFFFFFF)),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        dividerColor: Colors.transparent,
        labelColor: Cinematic.neonViolet,
        unselectedLabelColor: Cinematic.textSecondaryDark,
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 13,
          letterSpacing: 0.8,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 13,
          letterSpacing: 0.8,
        ),
        overlayColor: WidgetStatePropertyAll(
          Cinematic.neonViolet.withValues(alpha: 0.08),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: Cinematic.deepViolet,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Cinematic.neonViolet,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Cinematic.surfaceBright,
          foregroundColor: Cinematic.textPrimaryDark,
          elevation: 2,
          shadowColor: Cinematic.neonViolet.withValues(alpha: 0.35),
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Cinematic.neonViolet,
          side: const BorderSide(color: Color(0x66C77DFF)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: Cinematic.neonViolet,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF110C20),
        labelStyle: const TextStyle(
          color: Cinematic.textSecondaryDark,
          fontWeight: FontWeight.w500,
        ),
        hintStyle: TextStyle(
          color: Cinematic.textSecondaryDark.withValues(alpha: 0.7),
        ),
        prefixIconColor: Cinematic.textSecondaryDark,
        suffixIconColor: Cinematic.textSecondaryDark,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0x4DFFFFFF)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Cinematic.neonViolet,
            width: 1.6,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.error, width: 1.4),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.error, width: 1.6),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Cinematic.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: Cinematic.surfaceBright,
        contentTextStyle: const TextStyle(color: Cinematic.textPrimaryDark),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0x33FFFFFF),
        thickness: 1,
        space: 1,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: Cinematic.neonViolet,
        textColor: Cinematic.textPrimaryDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      switchTheme: SwitchThemeData(
        trackOutlineColor: const WidgetStatePropertyAll(
          Color(0x4DFFFFFF),
        ),
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Colors.white
              : Cinematic.textSecondaryDark,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Cinematic.deepViolet
              : const Color(0xFF2A2148),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: Cinematic.neonViolet,
        linearTrackColor: Cinematic.line.withValues(alpha: 0.4),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: Cinematic.deepViolet,
        foregroundColor: Colors.white,
        elevation: 4,
        highlightElevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Cinematic.surface,
        indicatorColor: Cinematic.neonViolet.withValues(alpha: 0.18),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: Cinematic.surfaceBright,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: Cinematic.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      timePickerTheme: TimePickerThemeData(
        backgroundColor: Cinematic.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }

  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: Cinematic.deepViolet,
      brightness: Brightness.light,
    ).copyWith(
      primary: const Color(0xFF7A3FD6),
      onPrimary: Colors.white,
      primaryContainer: const Color(0xFFEDE0FF),
      onPrimaryContainer: const Color(0xFF2A1050),
      secondary: const Color(0xFF8B5CF6),
      onSecondary: Colors.white,
      secondaryContainer: const Color(0xFFF3E9FF),
      onSecondaryContainer: const Color(0xFF341359),
      tertiary: const Color(0xFFD946B4),
      surface: const Color(0xFFFDFBFF),
      onSurface: Cinematic.textPrimaryLight,
      onSurfaceVariant: Cinematic.textSecondaryLight,
      surfaceContainerLowest: const Color(0xFFFFFFFF),
      surfaceContainerLow: const Color(0xFFF8F2FF),
      surfaceContainer: const Color(0xFFF2E9FF),
      surfaceContainerHigh: const Color(0xFFECE0FC),
      surfaceContainerHighest: const Color(0xFFE6D8FA),
      outline: const Color(0xFF9A8BBF),
      outlineVariant: const Color(0xFFE0D5F5),
      error: const Color(0xFFBA1A1A),
      onError: Colors.white,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      shadowColor: const Color(0x2E8B5CF6),
    );

    return base.copyWith(
      scaffoldBackgroundColor: Cinematic.dayTop,
      canvasColor: Cinematic.dayTop,
      extensions: const <ThemeExtension<dynamic>>[
        CinematicColors(
          glass: Color(0xCCFFFFFF),
          glow: Color(0xFF7A3FD6),
          glowSoft: Color(0x408B5CF6),
          scrim: Color(0x33000000),
          borderGlow: Color(0x738B5CF6),
        ),
      ],
      textTheme: _textTheme(base.textTheme, isDark: false),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        foregroundColor: Cinematic.textPrimaryLight,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: Cinematic.surfaceLight,
        elevation: 1,
        surfaceTintColor: Cinematic.deepViolet.withValues(alpha: 0.05),
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: Color(0x3DE5DAF7)),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        dividerColor: Colors.transparent,
        labelColor: const Color(0xFF7A3FD6),
        unselectedLabelColor: Cinematic.textSecondaryLight,
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 13,
          letterSpacing: 0.8,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 13,
          letterSpacing: 0.8,
        ),
        overlayColor: WidgetStatePropertyAll(
          Cinematic.deepViolet.withValues(alpha: 0.08),
        ),
        indicatorColor: const Color(0xFF7A3FD6),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF7A3FD6),
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Cinematic.deepViolet,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Cinematic.textPrimaryLight,
          elevation: 1,
          shadowColor: Cinematic.deepViolet.withValues(alpha: 0.25),
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF7A3FD6),
          side: const BorderSide(color: Color(0x668B5CF6)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFF7A3FD6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.85),
        labelStyle: const TextStyle(
          color: Cinematic.textSecondaryLight,
          fontWeight: FontWeight.w500,
        ),
        hintStyle: TextStyle(
          color: Cinematic.textSecondaryLight.withValues(alpha: 0.75),
        ),
        prefixIconColor: Cinematic.textSecondaryLight,
        suffixIconColor: Cinematic.textSecondaryLight,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0x338B5CF6)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Color(0xFF7A3FD6),
            width: 1.6,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.error, width: 1.4),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.error, width: 1.6),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF2A2148),
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0x1F8B5CF6),
        thickness: 1,
        space: 1,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: const Color(0xFF7A3FD6),
        textColor: Cinematic.textPrimaryLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      switchTheme: SwitchThemeData(
        trackOutlineColor: const WidgetStatePropertyAll(
          Color(0x4D8B5CF6),
        ),
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Colors.white
              : Cinematic.textSecondaryLight,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? const Color(0xFF8B5CF6)
              : const Color(0xFFE0D5F5),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: Color(0xFF7A3FD6),
        linearTrackColor: Color(0x1F8B5CF6),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: const Color(0xFF7A3FD6),
        foregroundColor: Colors.white,
        elevation: 3,
        highlightElevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Cinematic.surfaceLight,
        indicatorColor: Cinematic.deepViolet.withValues(alpha: 0.14),
        shadowColor: Colors.transparent,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0x1F8B5CF6)),
        ),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      timePickerTheme: TimePickerThemeData(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }

  static TextTheme _textTheme(TextTheme base, {required bool isDark}) {
    final primary = isDark
        ? Cinematic.textPrimaryDark
        : Cinematic.textPrimaryLight;
    final secondary = isDark
        ? Cinematic.textSecondaryDark
        : Cinematic.textSecondaryLight;
    return base.copyWith(
      displayLarge: base.displayLarge?.copyWith(
        color: primary,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.5,
      ),
      displayMedium: base.displayMedium?.copyWith(
        color: primary,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.5,
      ),
      displaySmall: base.displaySmall?.copyWith(
        color: primary,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.5,
      ),
      headlineLarge: base.headlineLarge?.copyWith(
        color: primary,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.3,
      ),
      headlineMedium: base.headlineMedium?.copyWith(
        color: primary,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.3,
      ),
      headlineSmall: base.headlineSmall?.copyWith(
        color: primary,
        fontWeight: FontWeight.w700,
      ),
      titleLarge: base.titleLarge?.copyWith(
        color: primary,
        fontWeight: FontWeight.w700,
      ),
      titleMedium: base.titleMedium?.copyWith(
        color: primary,
        fontWeight: FontWeight.w600,
      ),
      titleSmall: base.titleSmall?.copyWith(
        color: primary,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: base.bodyLarge?.copyWith(color: primary),
      bodyMedium: base.bodyMedium?.copyWith(color: primary),
      bodySmall: base.bodySmall?.copyWith(color: secondary),
      labelLarge: base.labelLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: 0.4,
      ),
      labelMedium: base.labelMedium?.copyWith(
        color: secondary,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.6,
      ),
    );
  }
}