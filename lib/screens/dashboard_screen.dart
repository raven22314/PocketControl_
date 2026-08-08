import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';

import '../models/clima.dart';
import '../models/tipo_cambio.dart';
import '../routes/app_routes.dart';
import '../services/clima_service.dart';
import '../services/preferences_service.dart';
import '../services/tipo_cambio_service.dart';

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
  final TipoCambioService _tipoCambioService = TipoCambioService();
  final ClimaService _climaService = ClimaService();

  static const List<String> _monedasDisponibles = <String>[
    'MXN',
    'USD',
    'EUR',
    'GBP',
    'JPY',
    'CAD',
  ];

  static const Map<String, String> _simbolosMoneda = <String, String>{
    'MXN': r'MX$',
    'USD': r'US$',
    'EUR': '€',
    'GBP': '£',
    'JPY': '¥',
    'CAD': r'CA$',
  };

  static const Map<String, double> _tasasFallback = <String, double>{
    'MXN': 1.0,
    'USD': 0.054,
    'EUR': 0.049,
    'GBP': 0.042,
    'JPY': 8.0,
    'CAD': 0.073,
  };

  late Future<_DashboardData> _dashboardFuture;
  late Future<Clima> _climaFuture;

  @override
  void initState() {
    super.initState();
    _dashboardFuture = _cargarDashboard();
    _climaFuture = _cargarClimaActual();
  }

  Future<Clima> _cargarClimaActual() async {
    try {
      final bool servicioHabilitado =
          await Geolocator.isLocationServiceEnabled();
      if (!servicioHabilitado) {
        throw Exception('Activa el GPS para consultar el clima local.');
      }

      LocationPermission permiso = await Geolocator.checkPermission();
      if (permiso == LocationPermission.denied) {
        permiso = await Geolocator.requestPermission();
      }

      if (permiso == LocationPermission.denied) {
        throw Exception('Permiso de ubicación denegado.');
      }

      if (permiso == LocationPermission.deniedForever) {
        throw Exception(
          'Permiso de ubicación denegado permanentemente. Habilítalo en ajustes.',
        );
      }

      final Position posicion = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      return _climaService.obtenerClimaPorCoordenadas(
        latitud: posicion.latitude,
        longitud: posicion.longitude,
      );
    } on MissingPluginException {
      throw Exception(
        'No se encontró el plugin de ubicación. Reinicia la app por completo para registrar geolocator.',
      );
    } on PlatformException catch (error) {
      throw Exception('Error de ubicación: ${error.message ?? error.code}');
    }
  }

  void _refrescarClima() {
    setState(() {
      _climaFuture = _cargarClimaActual();
    });
  }

  /// Carga en paralelo los datos persistidos que necesita el dashboard.
  Future<_DashboardData> _cargarDashboard() async {
    final List<dynamic> resultados =
        await Future.wait<dynamic>(<Future<dynamic>>[
          _preferencesService.obtenerNombre(),
          _preferencesService.obtenerTotalIngresos(),
          _preferencesService.obtenerTotalGastos(),
          _preferencesService.obtenerMonedaPreferida(),
        ]);

    final String? nombreGuardado = resultados[0] as String?;
    final double totalIngresos = resultados[1] as double;
    final double totalGastos = resultados[2] as double;
    final String monedaPreferida = resultados[3] as String;
    final String monedaSeleccionada =
        _monedasDisponibles.contains(monedaPreferida) ? monedaPreferida : 'MXN';
    final double factorConversion = await _obtenerFactorConversion(
      monedaSeleccionada,
    );

    return _DashboardData(
      nombre: nombreGuardado?.trim().isNotEmpty == true
          ? nombreGuardado!.trim()
          : 'Usuario',
      totalIngresos: totalIngresos,
      totalGastos: totalGastos,
      moneda: monedaSeleccionada,
      factorConversion: factorConversion,
      saldo: (totalIngresos - totalGastos) * factorConversion,
    );
  }

  Future<double> _obtenerFactorConversion(String moneda) async {
    if (moneda == 'MXN') {
      return 1.0;
    }

    try {
      final List<TipoCambio> tiposCambio = await _tipoCambioService
          .obtenerTiposCambio();
      final Map<String, double> tasas = <String, double>{
        for (final TipoCambio tipo in tiposCambio) tipo.moneda: tipo.valor,
      };

      return tasas[moneda] ?? _tasasFallback[moneda] ?? 1.0;
    } catch (_) {
      return _tasasFallback[moneda] ?? 1.0;
    }
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

  /// Formatea los valores monetarios con separadores de miles y moneda elegida.
  String _formatearMoneda(double valor, String moneda) {
    final bool esNegativo = valor < 0;
    final double valorAbsoluto = valor.abs();
    final String entero = valorAbsoluto.truncate().toString();
    final bool sinDecimales = moneda == 'JPY';
    final String decimal = sinDecimales
        ? ''
        : '.${((valorAbsoluto - valorAbsoluto.truncate()) * 100).round().toString().padLeft(2, '0')}';

    final StringBuffer partes = StringBuffer();
    for (int indice = 0; indice < entero.length; indice++) {
      partes.write(entero[indice]);
      final int caracteresRestantes = entero.length - indice - 1;
      if (caracteresRestantes > 0 && caracteresRestantes % 3 == 0) {
        partes.write(',');
      }
    }

    final String simbolo = _simbolosMoneda[moneda] ?? '\$';

    return '${esNegativo ? '-' : ''}$simbolo${partes.toString()}$decimal';
  }

  Future<void> _seleccionarMoneda(_DashboardData data) async {
    String monedaSeleccionada = data.moneda;

    final String? monedaElegida = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder:
              (
                BuildContext context,
                void Function(void Function()) setDialogState,
              ) {
                return AlertDialog(
                  title: const Text('Seleccionar moneda'),
                  content: DropdownButtonFormField<String>(
                    initialValue: monedaSeleccionada,
                    decoration: const InputDecoration(
                      labelText: 'Moneda',
                      border: OutlineInputBorder(),
                    ),
                    items: _monedasDisponibles
                        .map(
                          (String moneda) => DropdownMenuItem<String>(
                            value: moneda,
                            child: Text(moneda),
                          ),
                        )
                        .toList(),
                    onChanged: (String? value) {
                      if (value == null) {
                        return;
                      }

                      setDialogState(() {
                        monedaSeleccionada = value;
                      });
                    },
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancelar'),
                    ),
                    ElevatedButton(
                      onPressed: () =>
                          Navigator.of(context).pop(monedaSeleccionada),
                      child: const Text('Guardar'),
                    ),
                  ],
                );
              },
        );
      },
    );

    if (monedaElegida == null || monedaElegida == data.moneda) {
      return;
    }

    await _preferencesService.guardarMonedaPreferida(monedaElegida);

    if (!mounted) {
      return;
    }

    setState(() {
      _dashboardFuture = _cargarDashboard();
    });
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
            tooltip: 'Cambiar moneda',
            onPressed: () async {
              final _DashboardData data = await _dashboardFuture;

              if (!mounted) {
                return;
              }

              await _seleccionarMoneda(data);
            },
            icon: const Icon(Icons.payments_outlined),
          ),
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
                      _climaFuture = _cargarClimaActual();
                    });
                    await _dashboardFuture;
                    await _climaFuture;
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
                        const SizedBox(height: 16),
                        FutureBuilder<Clima>(
                          future: _climaFuture,
                          builder:
                              (
                                BuildContext context,
                                AsyncSnapshot<Clima> clima,
                              ) {
                                return _WeatherCard(
                                  clima: clima.data,
                                  cargando:
                                      clima.connectionState ==
                                      ConnectionState.waiting,
                                  error: clima.hasError
                                      ? clima.error.toString().replaceFirst(
                                          'Exception: ',
                                          '',
                                        )
                                      : null,
                                  onRefresh: _refrescarClima,
                                );
                              },
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Chip(
                              label: Text('Moneda actual: ${data.moneda}'),
                              visualDensity: VisualDensity.compact,
                            ),
                            OutlinedButton.icon(
                              onPressed: () => _seleccionarMoneda(data),
                              icon: const Icon(Icons.tune),
                              label: const Text('Cambiar moneda'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _MetricCard(
                          title: 'Saldo actual',
                          value: _formatearMoneda(data.saldo, data.moneda),
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
                                value: _formatearMoneda(
                                  data.totalIngresos * data.factorConversion,
                                  data.moneda,
                                ),
                                icon: Icons.trending_up,
                                iconColor: const Color(0xFF1B7F5A),
                                backgroundColor: const Color(0xFFE2F6EC),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _MetricCard(
                                title: 'Gastos',
                                value: _formatearMoneda(
                                  data.totalGastos * data.factorConversion,
                                  data.moneda,
                                ),
                                icon: Icons.trending_down,
                                iconColor: const Color(0xFFB23B3B),
                                backgroundColor: const Color(0xFFFBE5E5),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _IncomeExpenseChart(
                          ingresos: data.totalIngresos * data.factorConversion,
                          gastos: data.totalGastos * data.factorConversion,
                          currencyFormatter: (double valor) =>
                              _formatearMoneda(valor, data.moneda),
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
    required this.moneda,
    required this.factorConversion,
    required this.saldo,
  });

  final String nombre;
  final double totalIngresos;
  final double totalGastos;
  final String moneda;
  final double factorConversion;
  final double saldo;
}

class _WeatherCard extends StatelessWidget {
  const _WeatherCard({
    required this.clima,
    required this.cargando,
    required this.error,
    required this.onRefresh,
  });

  final Clima? clima;
  final bool cargando;
  final String? error;
  final VoidCallback onRefresh;

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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.cloud_outlined, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Clima local',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Actualizar clima',
                  onPressed: cargando ? null : onRefresh,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (cargando) const LinearProgressIndicator(),
            if (error != null && !cargando)
              Text(
                error!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            if (clima != null && !cargando)
              Row(
                children: [
                  Image.network(
                    'https://openweathermap.org/img/wn/${clima!.icono}@2x.png',
                    width: 56,
                    height: 56,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.cloud, size: 40),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          clima!.ciudad,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '${clima!.temperatura.toStringAsFixed(1)} °C · ${clima!.descripcion}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
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

/// Gráfica tipo pastel para comparar ingresos y gastos.
class _IncomeExpenseChart extends StatelessWidget {
  const _IncomeExpenseChart({
    required this.ingresos,
    required this.gastos,
    required this.currencyFormatter,
  });

  final double ingresos;
  final double gastos;
  final String Function(double valor) currencyFormatter;

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
                              color: const Color(
                                0xFF8DBE95,
                              ).withValues(alpha: 0.16),
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
                        value: currencyFormatter(ingresos),
                        percent: total > 0
                            ? '${(porcentajeIngresos * 100).round()}%'
                            : '0%',
                      ),
                      const SizedBox(height: 12),
                      _LegendItem(
                        color: const Color(0xFFD6A6A6),
                        label: 'Gastos',
                        value: currencyFormatter(gastos),
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
                          'Saldo: ${currencyFormatter(ingresos - gastos)}',
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
