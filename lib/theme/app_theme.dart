import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ═══════════════════════════════════════════════════
  //  Brand Colors — مستوحاة من شعار MERAJ3I
  //  اللون الأساسي: أخضر داكن عميق (كلون القبعة والكتاب في الشعار)
  // ═══════════════════════════════════════════════════
  static const primaryColor   = Color(0xFF0B6B58); // أخضر داكن — اللون الأساسي للشعار
  static const secondaryColor = Color(0xFFD4AF37); // ذهبي
  static const accentColor    = Color(0xFF0A5546); // أخضر أغمق للوضع الليلي
  static const lightGreen     = Color(0xFF14A085); // أخضر فيروزي فاتح للتمييز

  static const backgroundLight = Color(0xFFF4FAF8); // خلفية فاتحة بلمسة خضراء خفيفة
  static const surfaceLight    = Colors.white;

  static const backgroundDark = Color(0xFF0A1A15); // أخضر داكن جداً للوضع الليلي
  static const surfaceDark    = Color(0xFF112A22); // سطح الوضع الليلي
  static const surfaceDark2   = Color(0xFF1A3A2D); // سطح ثانوي للوضع الليلي

  // ═══════════════════════════════════════════════════
  //  Gradients
  // ═══════════════════════════════════════════════════

  /// التدرج الرئيسي — أخضر داكن إلى أخضر فيروزي
  static const primaryGradient = LinearGradient(
    colors: [Color(0xFF0B6B58), Color(0xFF14A085)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// تدرج العلامة التجارية للـ Header
  static const brandGradient = LinearGradient(
    colors: [Color(0xFF083D2F), Color(0xFF0B6B58), Color(0xFF14A085)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// تدرج عميق للـ Header والـ Drawer
  static const deepBlueGradient = LinearGradient(
    colors: [Color(0xFF083D2F), Color(0xFF0B6B58)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// تدرج ذهبي — المسابقات والامتحانات
  static const goldGradient = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// تدرج ثانوي — أصفر ذهبي
  static const secondaryGradient = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// تدرج أخضر فاتح — التنزيلات
  static const greenGradient = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF059669)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// تدرج بنفسجي — الذكاء الاصطناعي
  static const purpleGradient = LinearGradient(
    colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// تدرج أزرق — المراحل الدراسية
  static const blueGradient = LinearGradient(
    colors: [Color(0xFF0EA5E9), Color(0xFF0284C7)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// تدرج وردي — SWEDD
  static const pinkGradient = LinearGradient(
    colors: [Color(0xFFEC4899), Color(0xFFBE185D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ═══════════════════════════════════════════════════
  //  Light Theme
  // ═══════════════════════════════════════════════════
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      pageTransitionsTheme: PageTransitionsTheme(
        builders: {
          TargetPlatform.android: const ZoomPageTransitionsBuilder(
            allowEnterRouteSnapshotting: false,
          ),
          TargetPlatform.iOS: const CupertinoPageTransitionsBuilder(),
        },
      ),
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: surfaceLight,
        onSurface: Color(0xFF0A1A15),
        onPrimary: Colors.white,
        onSecondary: Colors.white,
      ),
      scaffoldBackgroundColor: backgroundLight,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0A1A15),
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.tajawal(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF0A1A15),
        ),
      ),
      textTheme: GoogleFonts.tajawalTextTheme().apply(
        bodyColor: const Color(0xFF0A1A15),
        displayColor: const Color(0xFF0A1A15),
      ),
      cardTheme: const CardThemeData(
        elevation: 0,
        color: Colors.white,
        margin: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(18)),
          side: BorderSide(color: Color(0xFFE8F5F0), width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle: GoogleFonts.tajawal(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFD1EAE3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFD1EAE3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        labelStyle: GoogleFonts.tajawal(color: Color(0xFF4B7A6A)),
        hintStyle: GoogleFonts.tajawal(color: Color(0xFF8AADA4)),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        selectedItemColor: primaryColor,
        unselectedItemColor: Color(0xFF94A3B8),
        backgroundColor: Colors.white,
        elevation: 20,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.bold),
      ),
      dividerColor: const Color(0xFFD1EAE3),
    );
  }

  // ═══════════════════════════════════════════════════
  //  Dark Theme
  // ═══════════════════════════════════════════════════
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      pageTransitionsTheme: PageTransitionsTheme(
        builders: {
          TargetPlatform.android: const ZoomPageTransitionsBuilder(
            allowEnterRouteSnapshotting: false,
          ),
          TargetPlatform.iOS: const CupertinoPageTransitionsBuilder(),
        },
      ),
      colorScheme: const ColorScheme.dark(
        primary: lightGreen,
        secondary: secondaryColor,
        surface: surfaceDark,
        onSurface: Colors.white,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
      ),
      scaffoldBackgroundColor: backgroundDark,
      appBarTheme: AppBarTheme(
        backgroundColor: backgroundDark,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.tajawal(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      textTheme: GoogleFonts.tajawalTextTheme(
        ThemeData.dark().textTheme,
      ).apply(bodyColor: Colors.white, displayColor: Colors.white),
      cardTheme: CardThemeData(
        elevation: 0,
        color: surfaceDark,
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: Colors.white.withValues(alpha: 0.07),
            width: 1,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle: GoogleFonts.tajawal(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF1A3A2D)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF1A3A2D)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: lightGreen, width: 2),
        ),
        filled: true,
        fillColor: surfaceDark,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        labelStyle: GoogleFonts.tajawal(color: Color(0xFF7BB5A5)),
        hintStyle: GoogleFonts.tajawal(color: Color(0xFF4A7A6A)),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        selectedItemColor: lightGreen,
        unselectedItemColor: Color(0xFF64748B),
        backgroundColor: surfaceDark,
        elevation: 20,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.bold),
      ),
      dividerColor: const Color(0xFF1A3A2D),
    );
  }
}
