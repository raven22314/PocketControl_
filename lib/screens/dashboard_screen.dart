import 'package:flutter/material.dart';

import '../services/preferences_service.dart';
import 'estadisticas_screen.dart';
import 'gasto_screen.dart';
import 'historial_screen.dart';
import 'ingreso_screen.dart';
import 'login_screen.dart';

/// Menú principal de PocketControl.
///
/// Esta pantalla resume el estado financiero del usuario y expone accesos
/// directos a los módulos principales de la app.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final PreferencesService _preferencesService = PreferencesService();

  late Future<_DashboardData> _dashboardFuture;

  @override
  void initState() {
    super.initState();
    _dashboardFuture = _cargarDashboard();
  }

  /// Carga en paralelo los datos persistidos que necesita el dashboard.
  Future<_DashboardData> _cargarDashboard() async {
    final String? nombreGuardado = await _preferencesService.obtenerNombre();
    final double totalIngresos = await _preferencesService
        .obtenerTotalIngresos();
    final double totalGastos = await _preferencesService.obtenerTotalGastos();

    return _DashboardData(
      nombre: nombreGuardado?.trim().isNotEmpty == true
          ? nombreGuardado!.trim()
          : 'Usuario',
      totalIngresos: totalIngresos,
      totalGastos: totalGastos,
      saldo: totalIngresos - totalGastos,
    );
  }

  /// Cierra sesión, borra los datos persistidos y vuelve al login.
  Future<void> _cerrarSesion() async {
    await _preferencesService.cerrarSesion();

    if (!mounted) {
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute<LoginScreen>(
        builder: (BuildContext context) => const LoginScreen(),
      ),
    );
  }

  /// Formatea los valores monetarios con separadores de miles y dos decimales.
  String _formatearMoneda(double valor) {
    final bool esNegativo = valor < 0;
    final double valorAbsoluto = valor.abs();
    final String entero = valorAbsoluto.truncate().toString();
    final String decimal = ((valorAbsoluto - valorAbsoluto.truncate()) * 100)
        .round()
        .toString()
        .padLeft(2, '0');

    final StringBuffer partes = StringBuffer();
    for (int indice = 0; indice < entero.length; indice++) {
      partes.write(entero[indice]);
      final int caracteresRestantes = entero.length - indice - 1;
      if (caracteresRestantes > 0 && caracteresRestantes % 3 == 0) {
        partes.write(',');
      }
    }

    return '${esNegativo ? '-' : ''}\$${partes.toString()}.$decimal';
  }

  /// Abre una pantalla de acceso rápido dentro de la navegación principal.
  void _irA(Widget pantalla) {
    Navigator.push(
      context,
      MaterialPageRoute<Widget>(builder: (BuildContext context) => pantalla),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('PocketControl'),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            onPressed: _cerrarSesion,
            icon: const Icon(Icons.logout_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: FutureBuilder<_DashboardData>(
          future: _dashboardFuture,
          builder:
              (BuildContext context, AsyncSnapshot<_DashboardData> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 56,
                            color: theme.colorScheme.error,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No fue posible cargar el menú principal.',
                            style: theme.textTheme.titleMedium,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Intenta abrir la pantalla nuevamente.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final _DashboardData data = snapshot.data!;

                return RefreshIndicator(
                  onRefresh: () async {
                    setState(() {
                      _dashboardFuture = _cargarDashboard();
                    });
                    await _dashboardFuture;
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hola, ${data.nombre}',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Aquí tienes el resumen de tu situación financiera.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 24),
                        _MetricCard(
                          title: 'Saldo actual',
                          value: _formatearMoneda(data.saldo),
                          icon: Icons.account_balance_wallet_outlined,
                          iconColor: theme.colorScheme.primary,
                          backgroundColor: theme.colorScheme.primaryContainer,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _MetricCard(
                                title: 'Ingresos',
                                value: _formatearMoneda(data.totalIngresos),
                                icon: Icons.trending_up,
                                iconColor: const Color(0xFF1B7F5A),
                                backgroundColor: const Color(0xFFE2F6EC),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _MetricCard(
                                title: 'Gastos',
                                value: _formatearMoneda(data.totalGastos),
                                icon: Icons.trending_down,
                                iconColor: const Color(0xFFB23B3B),
                                backgroundColor: const Color(0xFFFBE5E5),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Accesos rápidos',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 1.2,
                          children: [
                            _AccessCard(
                              title: 'Registrar ingreso',
                              icon: Icons.add_circle_outline,
                              onTap: () => _irA(const IngresoScreen()),
                            ),
                            _AccessCard(
                              title: 'Registrar gasto',
                              icon: Icons.remove_circle_outline,
                              onTap: () => _irA(const GastoScreen()),
                            ),
                            _AccessCard(
                              title: 'Historial',
                              icon: Icons.receipt_long_outlined,
                              onTap: () => _irA(const HistorialScreen()),
                            ),
                            _AccessCard(
                              title: 'Estadísticas',
                              icon: Icons.pie_chart_outline,
                              onTap: () => _irA(const EstadisticasScreen()),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
        ),
      ),
    );
  }
}

/// Datos ya resueltos para renderizar el dashboard.
class _DashboardData {
  const _DashboardData({
    required this.nombre,
    required this.totalIngresos,
    required this.totalGastos,
    required this.saldo,
  });

  final String nombre;
  final double totalIngresos;
  final double totalGastos;
  final double saldo;
}

/// Tarjeta visual para mostrar cada métrica principal del dashboard.
class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Card(
      elevation: 0,
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.all(12),
              child: Icon(icon, color: iconColor),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Botón de acceso rápido con estilo de tarjeta.
class _AccessCard extends StatelessWidget {
  const _AccessCard({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 34, color: theme.colorScheme.primary),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
