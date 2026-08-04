import 'package:flutter/material.dart';

import 'screens/login_screen.dart';

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
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1F5C6C),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF4F7F9),
      ),
      home: const LoginScreen(),
    );
  }
}
//app no tiene rutas renombradas , implementarlo 