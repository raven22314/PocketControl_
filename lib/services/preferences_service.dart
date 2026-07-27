import 'package:shared_preferences/shared_preferences.dart';

/// Servicio encargado de guardar y leer la información de sesión.
///
/// La UI nunca debe acceder directamente a SharedPreferences; toda la
/// persistencia pasa por esta clase.
class PreferencesService {
  static const String _keyNombre = 'nombre';
  static const String _keyContrasena = 'contrasena';
  static const String _keySesionActiva = 'sesionActiva';

  /// Guarda los datos de acceso y marca la sesión como activa.
  Future<void> guardarSesion(String nombre, String contrasena) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    await prefs.setString(_keyNombre, nombre);
    await prefs.setString(_keyContrasena, contrasena);
    await prefs.setBool(_keySesionActiva, true);
  }

  /// Obtiene el nombre guardado, si existe.
  Future<String?> obtenerNombre() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyNombre);
  }

  /// Obtiene la contraseña guardada, si existe.
  Future<String?> obtenerContrasena() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyContrasena);
  }

  /// Indica si la sesión está activa.
  Future<bool> obtenerSesionActiva() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keySesionActiva) ?? false;
  }

  /// Borra todos los datos guardados para dejar la app en estado inicial.
  Future<void> cerrarSesion() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyNombre);
    await prefs.remove(_keyContrasena);
    await prefs.remove(_keySesionActiva);
  }
}
