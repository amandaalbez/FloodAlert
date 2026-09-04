
import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'screens/map_screen.dart';

void main() {
  runApp(const FloodAlertApp());
}

/// Paleta base do app. Trocar aqui muda o tom de cor em todo o app.
class AppColors {
  static const primary = Color(0xFF1D5FA8);
  static const primaryDark = Color(0xFF123E70);
  static const secondary = Color(0xFFE8A24C);
  static const background = Color(0xFFF2F6FB);
  static const surface = Colors.white;
  static const textPrimary = Color(0xFF122338);
  static const textSecondary = Color(0xFF5C6E80);
  static const border = Color(0xFFDCE4EE);
  static const error = Color(0xFFD65B5B);
}

class FloodAlertApp extends StatelessWidget {
  const FloodAlertApp({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      surface: AppColors.surface,
      error: AppColors.error,
      brightness: Brightness.light,
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FloodAlert',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        scaffoldBackgroundColor: AppColors.background,
        fontFamily: 'Roboto',
        textTheme: const TextTheme(
          headlineMedium: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: Colors.white,
          ),
          titleLarge: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
          bodyMedium: TextStyle(
            fontSize: 15,
            color: AppColors.textSecondary,
            height: 1.4,
          ),
          bodySmall: TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
          labelLarge: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF5F9FD),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: AppColors.primary,
              width: 1.6,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.error),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: AppColors.error,
              width: 1.6,
            ),
          ),
          hintStyle: const TextStyle(
            color: Color(0xFF93A6AD),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            disabledBackgroundColor:
                AppColors.primary.withValues(alpha: 0.55),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.4,
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
          ),
        ),
      ),

      // A tela inicial continua sendo a HomeScreen.
      home: const MainNavigation(),
    );
  }
}

/// Controla a navegação principal entre as telas do aplicativo.
class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _abaAtual = 0;

  final List<Widget> _telas = const [
    HomeScreen(),
    MapScreen(),
    _AlertasScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _abaAtual,
        children: _telas,
      ),

      bottomNavigationBar: NavigationBar(
        selectedIndex: _abaAtual,

        onDestinationSelected: (index) {
          setState(() {
            _abaAtual = index;
          });
        },

        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primary.withValues(alpha: 0.12),

        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(
              Icons.home_rounded,
              color: AppColors.primary,
            ),
            label: 'Início',
          ),

          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(
              Icons.map_rounded,
              color: AppColors.primary,
            ),
            label: 'Mapa',
          ),

          NavigationDestination(
            icon: Icon(Icons.notifications_outlined),
            selectedIcon: Icon(
              Icons.notifications_rounded,
              color: AppColors.primary,
            ),
            label: 'Alertas',
          ),
        ],
      ),
    );
  }
}

/// Tela provisória de alertas.
/// Depois podemos substituir pela tela completa de alertas.
class _AlertasScreen extends StatelessWidget {
  const _AlertasScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'Alertas',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
      ),

      body: const Center(
        child: Text(
          'Tela de alertas em desenvolvimento',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}