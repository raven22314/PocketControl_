import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../routes/app_routes.dart';
import '../services/preferences_service.dart';

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

    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(AppRoutes.login, (Route<dynamic> route) => false);
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

  /// Abre una pantalla nombrada y refresca el resumen al volver.
  Future<void> _irA(String ruta) async {
    await Navigator.pushNamed(context, ruta);

    if (!mounted) {
      return;
    }

    setState(() {
      _dashboardFuture = _cargarDashboard();
    });
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
                        _IncomeExpenseChart(
                          ingresos: data.totalIngresos,
                          gastos: data.totalGastos,
                          formatter: _formatearMoneda,
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
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          childAspectRatio: 1.05,
                          children: [
                            _AccessCard(
                              title: 'Registrar ingreso',
                              icon: Icons.add_circle_outline,
                              onTap: () => _irA(AppRoutes.registrarIngreso),
                            ),
                            _AccessCard(
                              title: 'Registrar gasto',
                              icon: Icons.remove_circle_outline,
                              onTap: () => _irA(AppRoutes.registrarGasto),
                            ),
                            _AccessCard(
                              title: 'Historial',
                              icon: Icons.receipt_long_outlined,
                              onTap: () => _irA(AppRoutes.historial),
                            ),
                            _AccessCard(
                              title: 'Estadísticas',
                              icon: Icons.pie_chart_outline,
                              onTap: () => _irA(AppRoutes.estadisticas),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        OutlinedButton.icon(
                          onPressed: _cerrarSesion,
                          icon: const Icon(Icons.logout_outlined),
                          label: const Text('Cerrar sesión'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(52),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
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

/// Gráfica tipo pastel para comparar ingresos y gastos.
class _IncomeExpenseChart extends StatelessWidget {
  const _IncomeExpenseChart({
    required this.ingresos,
    required this.gastos,
    required this.formatter,
  });

  final double ingresos;
  final double gastos;
  final String Function(double valor) formatter;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final double total = ingresos + gastos;
    final double porcentajeIngresos = total > 0 ? ingresos / total : 0;
    final double porcentajeGastos = total > 0 ? gastos / total : 0;

    return Card(
      elevation: 0,
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.pie_chart_outline,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Ingresos vs gastos',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                SizedBox(
                  width: 136,
                  height: 136,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CustomPaint(
                        size: const Size(136, 136),
                        painter: _PieChartPainter(
                          values: [porcentajeIngresos, porcentajeGastos],
                          colors: const [Color(0xFF8DBE95), Color(0xFFD6A6A6)],
                        ),
                      ),
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF8DBE95).withOpacity(0.16),
                              blurRadius: 12,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            total > 0
                                ? '${(porcentajeIngresos * 100).round()}%\ningresos'
                                : 'Sin\ndatos',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _LegendItem(
                        color: const Color(0xFF8DBE95),
                        label: 'Ingresos',
                        value: formatter(ingresos),
                        percent: total > 0
                            ? '${(porcentajeIngresos * 100).round()}%'
                            : '0%',
                      ),
                      const SizedBox(height: 12),
                      _LegendItem(
                        color: const Color(0xFFD6A6A6),
                        label: 'Gastos',
                        value: formatter(gastos),
                        percent: total > 0
                            ? '${(porcentajeGastos * 100).round()}%'
                            : '0%',
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'Saldo: ${formatter(ingresos - gastos)}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PieChartPainter extends CustomPainter {
  _PieChartPainter({required this.values, required this.colors});

  final List<double> values;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint basePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 24
      ..strokeCap = StrokeCap.round;

    final Rect rect = Rect.fromCircle(
      center: Offset(size.width / 2, size.height / 2),
      radius: (size.width / 2) - 12,
    );

    if (values.every((double value) => value <= 0)) {
      basePaint.color = const Color(0xFFE7EFE8);
      canvas.drawArc(rect, -math.pi / 2, math.pi * 2, false, basePaint);
      return;
    }

    double startAngle = -math.pi / 2;
    for (int index = 0; index < values.length; index++) {
      final double value = values[index];
      if (value <= 0) {
        continue;
      }

      final double sweepAngle = (math.pi * 2) * value;
      final Paint paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 24
        ..strokeCap = StrokeCap.round
        ..color = colors[index];

      canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.color,
    required this.label,
    required this.value,
    required this.percent,
  });

  final Color color;
  final String label;
  final String value;
  final String percent;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$label $percent',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                value,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 26, color: theme.colorScheme.primary),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
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
