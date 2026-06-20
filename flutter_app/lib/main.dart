import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'screens/chat_screen.dart';
import 'services/theme_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const HealthAIApp(),
    ),
  );
}

class HealthAIApp extends StatelessWidget {
  const HealthAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    return MaterialApp(
      title: 'HealthAI Assistant',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      themeMode: themeProvider.themeMode,
      home: const ChatScreen(),
    );
  }

  ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    const primary = Color(0xFF00685F);
    const primaryDark = Color(0xFF10A37F);
    const primaryContainer = Color(0xFF008378);
    const surface = Color(0xFFF7F9FB);
    const surfaceDark = Color(0xFF212121);
    const onSurface = Color(0xFF191C1E);
    const onSurfaceDark = Color.fromARGB(255, 15, 14, 14);
    const outline = Color(0xFF6D7A77);
    const outlineVariant = Color(0xFF3A3A3A);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: isDark ? primaryDark : primary,
        onPrimary: Colors.white,
        primaryContainer: primaryContainer,
        onPrimaryContainer: const Color(0xFFF4FFFC),
        secondary: const Color(0xFF565E74),
        onSecondary: Colors.white,
        secondaryContainer: const Color(0xFFDAE2FD),
        onSecondaryContainer: const Color(0xFF5C647A),
        tertiary: const Color(0xFF006763),
        onTertiary: Colors.white,
        tertiaryContainer: const Color(0xFF00827E),
        onTertiaryContainer: const Color(0xFFF3FFFD),
        error: const Color(0xFFBA1A1A),
        onError: Colors.white,
        errorContainer: const Color(0xFFFFDAD6),
        onErrorContainer: const Color(0xFF93000A),
        surface: isDark ? surfaceDark : surface,
        onSurface: isDark ? onSurfaceDark : onSurface,
        surfaceContainerHighest:
            isDark ? const Color(0xFF2D3133) : const Color(0xFFE0E3E5),
        outline: outline,
        outlineVariant: outlineVariant,
      ),
      fontFamily: 'Inter',
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? const Color(0xFF00504D) : primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: isDark ? const Color(0xFF303030) : Colors.white,
        hintStyle: TextStyle(color: isDark ? const Color(0xFFB4B4B4): Colors.black54),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color : isDark ? const Color(0xFF3A3A3A) : outlineVariant.withValues(alpha: 0.6)),
        ),
        color: isDark ? const Color(0xFF2D3133) : Colors.white,
      ),
    );
  }
}
