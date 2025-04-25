import 'package:flutter/material.dart';
import 'custom_theme.dart';

class AppTheme {
  // Cores principais inspiradas no design moderno
  static const Color primaryColor = Color(0xFFFF3D8A); // Rosa-fúcsia vibrante
  static const Color secondaryColor = Color(0xFF00CFFD); // Azul-ciano
  static const Color accentColor = Color(0xFF00E096); // Verde neon
  static const Color errorColor = Color(0xFFFF3D71); // Rosa para erro
  static const Color successColor = Color(0xFF00E0B0); // Verde-azulado
  static const Color warningColor = Color(0xFFFFD166); // Amarelo

  // Cores de fundo
  static const Color darkBackground = Color(0xFF0A1128); // Azul-petróleo escuro
  static const Color darkSurface = Color(0xFF121F3D); // Azul escuro um pouco mais claro
  static const Color darkCardColor = Color(0xFF1A2C50); // Cor dos cards no tema escuro

  // Gradientes
  static const Color gradientStart = Color(0xFFFF3D8A); // Rosa-fúcsia
  static const Color gradientEnd = Color(0xFF9C1AFF); // Roxo-elétrico

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [gradientStart, gradientEnd], // Rosa-fúcsia para roxo-elétrico
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [Color(0xFF00CFFD), Color(0xFF2E7BFF)], // Azul-ciano para azul-elétrico
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient chartGradient = LinearGradient(
    colors: [Color(0xFF00E096), Color(0xFF00CFFD)], // Verde neon para azul-ciano
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF00E0B0), Color(0xFF00CFFD)], // Verde-azulado para azul-ciano
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Efeitos de brilho
  static BoxShadow primaryGlow = BoxShadow(
    color: primaryColor.withOpacity(0.5),
    blurRadius: 20,
    spreadRadius: -5,
  );

  static BoxShadow secondaryGlow = BoxShadow(
    color: secondaryColor.withOpacity(0.5),
    blurRadius: 20,
    spreadRadius: -5,
  );

  // Cores para o tema claro
  static const Color lightBackground = Color(0xFFF5F5F5);
  static const Color lightSurface = Colors.white;
  static const Color lightOnPrimary = Colors.white;
  static const Color lightOnSecondary = Colors.white;
  static const Color lightOnBackground = Color(0xFF212121);
  static const Color lightOnSurface = Color(0xFF212121);

  // Cores para o tema escuro moderno
  static const Color darkOnPrimary = Colors.white;
  static const Color darkOnSecondary = Colors.white;
  static const Color darkOnBackground = Color(0xFFFFFFFF); // Branco para melhor contraste
  static const Color darkOnSurface = Color(0xFFFFFFFF); // Branco para melhor contraste

  // Tema claro
  static final ThemeData lightTheme = CustomTheme.lightTheme(
    primaryColor: primaryColor,
    secondaryColor: secondaryColor,
    errorColor: errorColor,
  );

  // Tema claro original (mantido para referência)
  static final ThemeData lightThemeOriginal = ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme(
      brightness: Brightness.light,
      primary: primaryColor,
      onPrimary: lightOnPrimary,
      secondary: secondaryColor,
      onSecondary: lightOnSecondary,
      error: errorColor,
      onError: Colors.white,
      surface: lightSurface,
      onSurface: lightOnSurface,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryColor,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      floatingLabelStyle: const TextStyle(color: primaryColor),
    ),
    cardTheme: CardTheme(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      color: Colors.white,
      shadowColor: Colors.black.withOpacity(0.1),
    ),
    textTheme: TextTheme(
      bodyLarge: const TextStyle(color: lightOnSurface),
      bodyMedium: const TextStyle(color: lightOnSurface),
      titleLarge: const TextStyle(color: lightOnSurface, fontWeight: FontWeight.bold),
      titleMedium: const TextStyle(color: lightOnSurface, fontWeight: FontWeight.bold),
      titleSmall: TextStyle(color: lightOnSurface.withOpacity(0.8)),
      labelLarge: const TextStyle(color: lightOnSurface),
    ),
    scaffoldBackgroundColor: lightBackground,
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: primaryColor,
      unselectedItemColor: Colors.black54, // Cor mais escura para garantir visibilidade, mas não tão escura
      type: BottomNavigationBarType.fixed,
      elevation: 8,
      selectedIconTheme: IconThemeData(
        size: 28,
        color: primaryColor,
      ),
      unselectedIconTheme: IconThemeData(
        size: 24,
        color: Colors.black54, // Cor mais escura para garantir visibilidade em fundo claro
      ),
      selectedLabelStyle: TextStyle(
        color: primaryColor,
        fontWeight: FontWeight.bold,
        fontSize: 12,
      ),
      unselectedLabelStyle: TextStyle(
        color: Colors.black54, // Cor mais escura para garantir visibilidade
        fontSize: 12,
      ),
      showSelectedLabels: true,
      showUnselectedLabels: true,
    ),
  );

  // Tema escuro moderno
  static final ThemeData darkTheme = CustomTheme.darkTheme(
    primaryColor: primaryColor,
    secondaryColor: secondaryColor,
    backgroundColor: darkBackground,
    surfaceColor: darkSurface,
    errorColor: errorColor,
  );

  // Tema escuro original (mantido para referência)
  static final ThemeData darkThemeOriginal = ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme(
      brightness: Brightness.dark,
      primary: primaryColor,
      onPrimary: darkOnPrimary,
      secondary: secondaryColor,
      onSecondary: darkOnSecondary,
      error: errorColor,
      onError: Colors.white,
      surface: darkSurface,
      onSurface: darkOnSurface,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: darkBackground,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        letterSpacing: 1.2,
      ),
      shadowColor: primaryColor.withOpacity(0.2),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        elevation: 0,
        shadowColor: primaryColor.withOpacity(0.3),
      ).copyWith(
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) {
            return primaryColor.withOpacity(0.8);
          }
          return primaryColor;
        }),
        overlayColor: WidgetStateProperty.all(Colors.white.withOpacity(0.1)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ).copyWith(
        overlayColor: WidgetStateProperty.all(primaryColor.withOpacity(0.1)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: darkCardColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: secondaryColor, width: 2),
      ),
      floatingLabelStyle: const TextStyle(color: secondaryColor),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      hoverColor: secondaryColor.withOpacity(0.1),
    ),
    cardTheme: CardTheme(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 0,
      color: darkCardColor,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      shadowColor: primaryColor.withOpacity(0.2),
    ),
    textTheme: TextTheme(
      bodyLarge: const TextStyle(color: darkOnSurface),
      bodyMedium: const TextStyle(color: darkOnSurface),
      titleLarge: const TextStyle(color: darkOnSurface, fontWeight: FontWeight.bold),
      titleMedium: const TextStyle(color: darkOnSurface, fontWeight: FontWeight.bold),
      titleSmall: TextStyle(color: darkOnSurface.withOpacity(0.8)),
      labelLarge: const TextStyle(color: darkOnSurface),
    ),
    scaffoldBackgroundColor: darkBackground,
    dialogTheme: DialogTheme(
      backgroundColor: darkSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 0,
      shadowColor: primaryColor.withOpacity(0.3),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: darkSurface,
      selectedItemColor: primaryColor,
      unselectedItemColor: Colors.white.withOpacity(0.7), // Aumentado para melhor visibilidade
      type: BottomNavigationBarType.fixed,
      elevation: 0,
      selectedIconTheme: const IconThemeData(
        size: 28,
        color: primaryColor,
      ),
      unselectedIconTheme: IconThemeData(
        size: 24,
        color: Colors.white.withOpacity(0.7), // Aumentado para melhor visibilidade
      ),
      selectedLabelStyle: const TextStyle(
        color: primaryColor,
        fontWeight: FontWeight.bold,
        fontSize: 12,
      ),
      unselectedLabelStyle: TextStyle(
        color: Colors.white.withOpacity(0.7), // Aumentado para melhor visibilidade
        fontSize: 12,
      ),
      showSelectedLabels: true,
      showUnselectedLabels: true,
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: primaryColor,
      thumbColor: primaryColor,
      overlayColor: primaryColor.withOpacity(0.2),
      valueIndicatorColor: primaryColor,
      valueIndicatorTextStyle: const TextStyle(color: Colors.white),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return primaryColor;
        return Colors.grey;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return primaryColor.withOpacity(0.5);
        return Colors.grey.withOpacity(0.5);
      }),
    ),
    tabBarTheme: TabBarTheme(
      labelColor: primaryColor,
      unselectedLabelColor: Colors.white.withOpacity(0.5),
      indicator: const UnderlineTabIndicator(
        borderSide: BorderSide(color: primaryColor, width: 2),
      ),
    ),
    dividerTheme: DividerThemeData(
      color: Colors.white.withOpacity(0.1),
      thickness: 1,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: darkCardColor,
      contentTextStyle: const TextStyle(color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      behavior: SnackBarBehavior.floating,
    ),
  );
}