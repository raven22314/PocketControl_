import 'package:flutter/material.dart';

import 'dashboard_screen.dart';
import '../services/preferences_service.dart';

/// Pantalla de inicio de sesión de PocketControl.
///
/// Esta pantalla gestiona el acceso y redirige al Dashboard cuando la sesión
/// ya está activa o cuando el usuario inicia sesión correctamente.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final PreferencesService _preferencesService = PreferencesService();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _contrasenaController = TextEditingController();

  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _restaurarSesion();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _contrasenaController.dispose();
    super.dispose();
  }

  /// Lee las preferencias al iniciar la pantalla para evitar parpadeos.
  Future<void> _restaurarSesion() async {
    final bool sesionActiva = await _preferencesService.obtenerSesionActiva();

    if (!mounted) {
      return;
    }

    if (sesionActiva) {
      _navegarADashboard();
      return;
    }

    setState(() {
      _cargando = false;
    });
  }

  /// Valida los campos y guarda la sesión cuando ambos valores son válidos.
  Future<void> _iniciarSesion() async {
    final String nombre = _nombreController.text.trim();
    final String contrasena = _contrasenaController.text.trim();

    if (nombre.isEmpty || contrasena.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes ingresar nombre y contraseña para continuar.'),
        ),
      );
      return;
    }

    await _preferencesService.guardarSesion(nombre, contrasena);

    if (!mounted) {
      return;
    }

    _navegarADashboard();
  }

  /// Reemplaza el login por el menú principal.
  void _navegarADashboard() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute<DashboardScreen>(
        builder: (BuildContext context) => const DashboardScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.surface,
                theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.7,
                ),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Center(
            child: _cargando
                ? const CircularProgressIndicator()
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: Card(
                        elevation: 0,
                        color: theme.colorScheme.surface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                          side: BorderSide(
                            color: theme.colorScheme.outlineVariant,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: _buildFormulario(theme),
                        ),
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  /// Construye el formulario de acceso cuando no hay sesión activa.
  Widget _buildFormulario(ThemeData theme) {
    final InputDecoration baseDecoration = InputDecoration(
      filled: true,
      fillColor: theme.colorScheme.surfaceContainerHighest.withValues(
        alpha: 0.35,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
    );

    return Column(
      key: const ValueKey('formulario'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'PocketControl',
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Accede para revisar tus finanzas personales.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 28),
        TextField(
          controller: _nombreController,
          decoration: baseDecoration.copyWith(
            hintText: 'Nombre',
            labelText: 'Nombre',
            prefixIcon: const Icon(Icons.person_outline),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _contrasenaController,
          obscureText: true,
          decoration: baseDecoration.copyWith(
            hintText: 'Contraseña',
            labelText: 'Contraseña',
            prefixIcon: const Icon(Icons.lock_outline),
          ),
        ),
        const SizedBox(height: 28),
        FilledButton(
          onPressed: _iniciarSesion,
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: const Text('Iniciar sesión'),
        ),
        const SizedBox(height: 12),
        Text(
          'Si la sesión ya existe, PocketControl te enviará directo al menú principal.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
