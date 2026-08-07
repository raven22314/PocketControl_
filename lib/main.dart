import 'package:flutter/material.dart';

import 'routes/app_routes.dart';

import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/ingreso_screen.dart';
import 'screens/gasto_screen.dart';
import 'screens/historial_screen.dart';
import 'screens/estadisticas_screen.dart';
import 'screens/tipo_cambio_screen.dart';
import 'screens/clima_screen.dart';

void main() {
  runApp(const PocketControlApp());
}

/// Aplicación raíz de PocketControl.
///
/// Configura Material 3 y define la pantalla de inicio como LoginScreen.
class PocketControlApp extends StatelessWidget {
  const PocketControlApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PocketControl',
      initialRoute: AppRoutes.login,
      routes: <String, WidgetBuilder>{
        AppRoutes.login: (BuildContext context) => const LoginScreen(),
        AppRoutes.dashboard: (BuildContext context) => const DashboardScreen(),
        AppRoutes.registrarIngreso: (BuildContext context) =>
            const IngresoScreen(),
        AppRoutes.registrarGasto: (BuildContext context) => const GastoScreen(),
        AppRoutes.historial: (BuildContext context) => const HistorialScreen(),
        AppRoutes.estadisticas: (BuildContext context) =>
            const EstadisticasScreen(),
        AppRoutes.tipoCambio: (context) => const TipoCambioScreen(),
        AppRoutes.clima: (context) => const ClimaScreen(),
      },
      theme: ThemeData(
        useMaterial3: true,
        colorScheme:
            ColorScheme.fromSeed(
              seedColor: const Color(0xFF8DBE95),
              brightness: Brightness.light,
            ).copyWith(
              primary: const Color(0xFF8DBE95),
              onPrimary: const Color(0xFF112117),
              primaryContainer: const Color(0xFFDDEEDC),
              secondary: const Color(0xFFAFCBAE),
              onSecondary: const Color(0xFF112117),
              secondaryContainer: const Color(0xFFE8F4E7),
              surface: const Color(0xFFF7FBF5),
              onSurface: const Color(0xFF1D2A22),
              surfaceContainerHighest: const Color(0xFFEFF7EE),
              tertiary: const Color(0xFF6C9D7A),
              tertiaryContainer: const Color(0xFFCFEBDA),
            ),
        scaffoldBackgroundColor: const Color(0xFFF7FBF5),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF8DBE95),
          foregroundColor: Color(0xFF112117),
          elevation: 0,
        ),
        cardTheme: const CardThemeData(
          color: Color(0xFFFDFCF8),
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF8DBE95),
            foregroundColor: const Color(0xFF112117),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF3F8F1),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFBFDCC2)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFBFDCC2)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF8DBE95), width: 1.6),
          ),
        ),
      ),
    );
  }
}
