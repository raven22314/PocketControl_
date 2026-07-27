import 'package:shared_preferences/shared_preferences.dart';

/// Servicio encargado de guardar y leer la información de sesión.
///
/// La UI nunca debe acceder directamente a SharedPreferences; toda la
/// persistencia pasa por esta clase.
class PreferencesService {
  static const String _keyNombre = 'nombre';
  static const String _keyContrasena = 'contrasena';
  static const String _keySesionActiva = 'sesionActiva';
  static const String _keyTotalIngresos = 'totalIngresos';
  static const String _keyTotalGastos = 'totalGastos';

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

  /// Obtiene el total acumulado de ingresos guardado en las preferencias.
  Future<double> obtenerTotalIngresos() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_keyTotalIngresos) ?? 0.0;
  }

  /// Obtiene el total acumulado de gastos guardado en las preferencias.
  Future<double> obtenerTotalGastos() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_keyTotalGastos) ?? 0.0;
  }

  /// Guarda el total acumulado de ingresos en SharedPreferences.
  Future<void> guardarTotalIngresos(double monto) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyTotalIngresos, monto);
  }

  /// Guarda el total acumulado de gastos en SharedPreferences.
  Future<void> guardarTotalGastos(double monto) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyTotalGastos, monto);
  }

  /// Borra todos los datos guardados para dejar la app en estado inicial.
  Future<void> cerrarSesion() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyNombre);
    await prefs.remove(_keyContrasena);
    await prefs.remove(_keySesionActiva);
    await prefs.remove(_keyTotalIngresos);
    await prefs.remove(_keyTotalGastos);
  }
}
