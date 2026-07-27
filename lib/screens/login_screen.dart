import 'package:flutter/material.dart';

import '../services/preferences_service.dart';

/// Pantalla de inicio de sesión de PocketControl.
///
/// Esta pantalla muestra un formulario de acceso cuando no existe una sesión
/// activa y una vista de bienvenida cuando los datos fueron restaurados desde
/// SharedPreferences.
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
  bool _sesionActiva = false;
  String _nombreGuardado = '';

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
      final String? nombre = await _preferencesService.obtenerNombre();
      final String? contrasena = await _preferencesService.obtenerContrasena();

      if (!mounted) {
        return;
      }

      setState(() {
        _sesionActiva = true;
        _nombreGuardado = nombre ?? '';
        _nombreController.text = nombre ?? '';
        _contrasenaController.text = contrasena ?? '';
        _cargando = false;
      });
      return;
    }

    setState(() {
      _sesionActiva = false;
      _nombreGuardado = '';
      _nombreController.clear();
      _contrasenaController.clear();
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

    setState(() {
      _sesionActiva = true;
      _nombreGuardado = nombre;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sesión iniciada correctamente.')),
    );
  }

  /// Cierra la sesión y deja la pantalla lista para un nuevo acceso.
  Future<void> _cerrarSesion() async {
    await _preferencesService.cerrarSesion();

    if (!mounted) {
      return;
    }

    setState(() {
      _sesionActiva = false;
      _nombreGuardado = '';
      _nombreController.clear();
      _contrasenaController.clear();
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Sesión cerrada.')));
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
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 250),
                            child: _sesionActiva
                                ? _buildBienvenida(theme)
                                : _buildFormulario(theme),
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  /// Construye la vista de bienvenida cuando ya existe una sesión activa.
  Widget _buildBienvenida(ThemeData theme) {
    return Column(
      key: const ValueKey('bienvenida'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(
          Icons.account_balance_wallet_outlined,
          size: 64,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(height: 20),
        Text(
          'Bienvenido, $_nombreGuardado',
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Tu sesión está activa y tus datos quedaron restaurados automáticamente.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 28),
        FilledButton(
          onPressed: _cerrarSesion,
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: const Text('Cerrar sesión'),
        ),
      ],
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
          'La sesión se restaurará automáticamente la próxima vez que abras la app.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
