import 'package:flutter/material.dart';

import '../routes/app_routes.dart';
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
  final TextEditingController _confirmarContrasenaController =
      TextEditingController();

  bool _cargando = true;
  bool _mostrandoRegistro = false;

  @override
  void initState() {
    super.initState();
    _restaurarSesion();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _contrasenaController.dispose();
    _confirmarContrasenaController.dispose();
    super.dispose();
  }

  /// Lee las preferencias al iniciar la pantalla para evitar parpadeos.
  Future<void> _restaurarSesion() async {
    final bool sesionActiva = await _preferencesService.obtenerSesionActiva();

    if (!mounted) {
      return;
    }

    if (sesionActiva) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _navegarADashboard();
        }
      });
      return;
    }

    setState(() {
      _cargando = false;
    });
  }

  /// Guarda un usuario nuevo en las preferencias del dispositivo.
  Future<void> _registrarUsuario() async {
    final String nombre = _nombreController.text.trim();
    final String contrasena = _contrasenaController.text.trim();
    final String confirmacion = _confirmarContrasenaController.text.trim();

    if (nombre.isEmpty || contrasena.isEmpty || confirmacion.isEmpty) {
      _mostrarMensaje('Completa todos los campos para crear tu cuenta.');
      return;
    }

    if (contrasena.length < 6) {
      _mostrarMensaje('La contraseña debe tener al menos 6 caracteres.');
      return;
    }

    if (contrasena != confirmacion) {
      _mostrarMensaje('La contraseña y su confirmación no coinciden.');
      return;
    }

    await _preferencesService.guardarUsuarioRegistrado(nombre, contrasena);

    if (!mounted) {
      return;
    }

    setState(() {
      _mostrandoRegistro = false;
    });
    _confirmarContrasenaController.clear();
    _contrasenaController.clear();

    _mostrarMensaje('Cuenta creada correctamente. Ahora inicia sesión.');
  }

  /// Valida las credenciales contra lo que ya está almacenado en SharedPreferences.
  Future<void> _iniciarSesion() async {
    final String nombre = _nombreController.text.trim();
    final String contrasena = _contrasenaController.text.trim();

    if (nombre.isEmpty || contrasena.isEmpty) {
      _mostrarMensaje('Debes ingresar nombre y contraseña para continuar.');
      return;
    }

    final bool hayUsuarioRegistrado = await _preferencesService
        .tieneUsuarioRegistrado();

    if (!hayUsuarioRegistrado) {
      _mostrarMensaje(
        'No hay ningún usuario registrado. Crea una cuenta antes de iniciar sesión.',
      );
      return;
    }

    final bool credencialesValidas = await _preferencesService
        .validarCredenciales(nombre, contrasena);

    if (!credencialesValidas) {
      _mostrarMensaje('Usuario o contraseña incorrectos.');
      return;
    }

    await _preferencesService.guardarSesion(nombre, contrasena);

    if (!mounted) {
      return;
    }

    _navegarADashboard();
  }

  /// Muestra mensajes cortos sin duplicar el código de SnackBar.
  void _mostrarMensaje(String mensaje) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(mensaje)));
  }

  /// Reemplaza el login por el menú principal.
  void _navegarADashboard() {
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.dashboard,
      (Route<dynamic> route) => false,
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
          _mostrandoRegistro
              ? 'Crea tu cuenta para empezar a usar PocketControl.'
              : 'Accede para revisar tus finanzas personales.',
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
        if (_mostrandoRegistro) ...[
          const SizedBox(height: 16),
          TextField(
            controller: _confirmarContrasenaController,
            obscureText: true,
            decoration: baseDecoration.copyWith(
              hintText: 'Confirmar contraseña',
              labelText: 'Confirmar contraseña',
              prefixIcon: const Icon(Icons.lock_reset_outlined),
            ),
          ),
        ],
        const SizedBox(height: 28),
        FilledButton(
          onPressed: _mostrandoRegistro ? _registrarUsuario : _iniciarSesion,
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Text(_mostrandoRegistro ? 'Crear cuenta' : 'Iniciar sesión'),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () {
            setState(() {
              _mostrandoRegistro = !_mostrandoRegistro;
            });
          },
          child: Text(
            _mostrandoRegistro ? 'Ya tengo una cuenta' : 'Crear cuenta',
          ),
        ),
        Text(
          _mostrandoRegistro
              ? 'El registro guarda el usuario de forma real en SharedPreferences.'
              : 'Si la sesión ya existe, PocketControl te enviará directo al menú principal.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
