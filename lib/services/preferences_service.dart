import 'dart:convert';

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
  static const String _keyMonedaPreferida = 'monedaPreferida';
  static const String _keyMovimientos = 'movimientos';

  /// Guarda o actualiza el usuario registrado en el dispositivo.
  Future<void> guardarUsuarioRegistrado(
    String nombre,
    String contrasena,
  ) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    await prefs.setString(_keyNombre, nombre);
    await prefs.setString(_keyContrasena, contrasena);
  }

  /// Guarda los datos de acceso y marca la sesión como activa.
  Future<void> guardarSesion(String nombre, String contrasena) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    await prefs.setString(_keyNombre, nombre);
    await prefs.setString(_keyContrasena, contrasena);
    await prefs.setBool(_keySesionActiva, true);
  }

  /// Indica si ya existe un usuario registrado en el dispositivo.
  Future<bool> tieneUsuarioRegistrado() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    final String? nombre = prefs.getString(_keyNombre);
    final String? contrasena = prefs.getString(_keyContrasena);

    return nombre?.trim().isNotEmpty == true &&
        contrasena?.trim().isNotEmpty == true;
  }

  /// Verifica si las credenciales ingresadas coinciden con las almacenadas.
  Future<bool> validarCredenciales(String nombre, String contrasena) async {
    final String? nombreGuardado = await obtenerNombre();
    final String? contrasenaGuardada = await obtenerContrasena();

    return nombreGuardado?.trim() == nombre.trim() &&
        contrasenaGuardada?.trim() == contrasena.trim();
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

  /// Obtiene la moneda preferida para mostrar los montos.
  Future<String> obtenerMonedaPreferida() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyMonedaPreferida) ?? 'MXN';
  }

  /// Agrega un movimiento al historial persistido como JSON serializado.
  Future<void> agregarMovimiento(Map<String, dynamic> movimiento) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String> movimientosGuardados =
        prefs.getStringList(_keyMovimientos) ?? <String>[];

    await prefs.setStringList(_keyMovimientos, <String>[
      ...movimientosGuardados,
      jsonEncode(movimiento),
    ]);
  }

  /// Obtiene el historial de movimientos convertido a mapas de Dart.
  Future<List<Map<String, dynamic>>> obtenerMovimientos() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String> movimientosGuardados =
        prefs.getStringList(_keyMovimientos) ?? <String>[];

    return movimientosGuardados.map((String item) {
      final dynamic decoded = jsonDecode(item);

      if (decoded is Map<String, dynamic>) {
        return decoded;
      }

      return Map<String, dynamic>.from(decoded as Map);
    }).toList();
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

  /// Guarda la moneda preferida para el formato del saldo y los totales.
  Future<void> guardarMonedaPreferida(String moneda) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyMonedaPreferida, moneda);
  }

  /// Borra todos los datos guardados para dejar la app en estado inicial.
  Future<void> cerrarSesion() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keySesionActiva);
  }

  /// Limpia los totales y el historial sin borrar el usuario registrado.
  Future<void> reiniciarMovimientosFinancieros() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyTotalIngresos);
    await prefs.remove(_keyTotalGastos);
    await prefs.remove(_keyMovimientos);
  }
}
