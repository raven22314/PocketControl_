import 'package:flutter/material.dart';

import '../services/preferences_service.dart';

class EstadisticasScreen extends StatefulWidget {
  const EstadisticasScreen({super.key});

  @override
  State<EstadisticasScreen> createState() => _EstadisticasScreenState();
}

class _EstadisticasScreenState extends State<EstadisticasScreen> {
  final PreferencesService _preferencesService = PreferencesService();
  late Future<_EstadisticasData> _estadisticasFuture;

  String _limpiarTexto(String texto) {
    return texto.replaceAll(' / ', ' - ').replaceAll('/', ' - ');
  }

  @override
  void initState() {
    super.initState();
    _estadisticasFuture = _cargarEstadisticas();
  }

  Future<void> _refrescar() async {
    setState(() {
      _estadisticasFuture = _cargarEstadisticas();
    });

    await _estadisticasFuture;
  }

  Future<_EstadisticasData> _cargarEstadisticas() async {
    final List<Map<String, dynamic>> movimientos = await _preferencesService
        .obtenerMovimientos();
    final double totalIngresos = await _preferencesService
        .obtenerTotalIngresos();
    final double totalGastos = await _preferencesService.obtenerTotalGastos();
    final String moneda = await _preferencesService.obtenerMonedaPreferida();

    final List<_MovimientoProcesado> movimientosProcesados = movimientos
        .map(_MovimientoProcesado.fromMap)
        .where((_MovimientoProcesado movimiento) => movimiento.fecha != null)
        .toList();

    movimientosProcesados.sort(
      (_MovimientoProcesado a, _MovimientoProcesado b) =>
          b.fecha!.compareTo(a.fecha!),
    );

    final DateTime ahora = DateTime.now();
    final DateTime inicioMes = DateTime(ahora.year, ahora.month, 1);
    double ingresosMes = 0;
    double gastosMes = 0;
    final Map<String, double> categoriasIngresos = <String, double>{};
    final Map<String, double> categoriasGastos = <String, double>{};

    for (final _MovimientoProcesado movimiento in movimientosProcesados) {
      final DateTime fecha = movimiento.fecha!;

      if (fecha.isAfter(inicioMes.subtract(const Duration(seconds: 1)))) {
        if (movimiento.esIngreso) {
          ingresosMes += movimiento.monto;
        } else {
          gastosMes += movimiento.monto;
        }
      }

      if (movimiento.esIngreso) {
        categoriasIngresos.update(
          movimiento.categoria,
          (double value) => value + movimiento.monto,
          ifAbsent: () => movimiento.monto,
        );
      } else {
        categoriasGastos.update(
          movimiento.categoria,
          (double value) => value + movimiento.monto,
          ifAbsent: () => movimiento.monto,
        );
      }
    }

    final List<_CategoriaResumen> topIngresos = _topCategorias(
      categoriasIngresos,
    );
    final List<_CategoriaResumen> topGastos = _topCategorias(categoriasGastos);
    final List<_MovimientoProcesado> recientes = movimientosProcesados
        .take(5)
        .toList();

    return _EstadisticasData(
      moneda: moneda,
      totalIngresos: totalIngresos,
      totalGastos: totalGastos,
      balance: totalIngresos - totalGastos,
      totalMovimientos: movimientosProcesados.length,
      totalIngresosRegistrados: movimientosProcesados
          .where((_MovimientoProcesado movimiento) => movimiento.esIngreso)
          .length,
      totalGastosRegistrados: movimientosProcesados
          .where((_MovimientoProcesado movimiento) => !movimiento.esIngreso)
          .length,
      promedioIngreso:
          movimientosProcesados
              .where((_MovimientoProcesado movimiento) => movimiento.esIngreso)
              .map((_MovimientoProcesado movimiento) => movimiento.monto)
              .fold<double>(0, (double total, double monto) => total + monto) /
          (movimientosProcesados
                  .where(
                    (_MovimientoProcesado movimiento) => movimiento.esIngreso,
                  )
                  .isEmpty
              ? 1
              : movimientosProcesados
                    .where(
                      (_MovimientoProcesado movimiento) => movimiento.esIngreso,
                    )
                    .length),
      promedioGasto:
          movimientosProcesados
              .where((_MovimientoProcesado movimiento) => !movimiento.esIngreso)
              .map((_MovimientoProcesado movimiento) => movimiento.monto)
              .fold<double>(0, (double total, double monto) => total + monto) /
          (movimientosProcesados
                  .where(
                    (_MovimientoProcesado movimiento) => !movimiento.esIngreso,
                  )
                  .isEmpty
              ? 1
              : movimientosProcesados
                    .where(
                      (_MovimientoProcesado movimiento) =>
                          !movimiento.esIngreso,
                    )
                    .length),
      porcentajeAhorro: totalIngresos > 0
          ? ((totalIngresos - totalGastos) / totalIngresos)
          : 0,
      ingresosMes: ingresosMes,
      gastosMes: gastosMes,
      balanceMes: ingresosMes - gastosMes,
      topIngresos: topIngresos,
      topGastos: topGastos,
      recientes: recientes,
    );
  }

  List<_CategoriaResumen> _topCategorias(Map<String, double> categorias) {
    final List<MapEntry<String, double>> ordenadas = categorias.entries.toList()
      ..sort(
        (MapEntry<String, double> a, MapEntry<String, double> b) =>
            b.value.compareTo(a.value),
      );

    final double total = categorias.values.fold<double>(
      0,
      (double total, double monto) => total + monto,
    );

    return ordenadas
        .take(3)
        .map(
          (MapEntry<String, double> entry) => _CategoriaResumen(
            nombre: _limpiarTexto(entry.key),
            monto: entry.value,
            porcentaje: total > 0 ? entry.value / total : 0,
          ),
        )
        .toList();
  }

  String _simboloMoneda(String moneda) {
    switch (moneda.toUpperCase()) {
      case 'MXN':
        return r'$';
      case 'USD':
        return r'$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      default:
        return r'$';
    }
  }

  String _formatearMonto(double monto, String moneda) {
    final String simbolo = _simboloMoneda(moneda);
    return '$simbolo${monto.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Estadísticas'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Actualizar',
            onPressed: _refrescar,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: FutureBuilder<_EstadisticasData>(
          future: _estadisticasFuture,
          builder: (BuildContext context, AsyncSnapshot<_EstadisticasData> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(
                        Icons.error_outline,
                        size: 56,
                        color: theme.colorScheme.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No fue posible cargar las estadísticas.',
                        style: theme.textTheme.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: _refrescar,
                        child: const Text('Intentar de nuevo'),
                      ),
                    ],
                  ),
                ),
              );
            }

            final _EstadisticasData data = snapshot.data!;

            if (data.totalMovimientos == 0) {
              return RefreshIndicator(
                onRefresh: _refrescar,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  children: <Widget>[
                    _HeroResumen(
                      moneda: data.moneda,
                      titulo: 'Aún no hay movimientos',
                      subtitulo:
                          'Registra ingresos y gastos para ver tu panorama financiero.',
                      valorPrincipal: _formatearMonto(0, data.moneda),
                      valorSecundario: 'Saldo inicial',
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: 20),
                    _EmptyStatsCard(
                      title: 'Empieza a generar estadísticas',
                      description:
                          'Cada movimiento alimenta el resumen general, el comportamiento mensual y las categorías principales.',
                      icon: Icons.insights_outlined,
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: _refrescar,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                children: <Widget>[
                  _HeroResumen(
                    moneda: data.moneda,
                    titulo: 'Resumen general',
                    subtitulo:
                        'Balance actual con base en todos tus movimientos.',
                    valorPrincipal: _formatearMonto(data.balance, data.moneda),
                    valorSecundario: 'Balance disponible',
                    color: data.balance >= 0
                        ? const Color(0xFF1B7F5A)
                        : const Color(0xFFB23B3B),
                  ),
                  const SizedBox(height: 20),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.1,
                    children: <Widget>[
                      _MetricCard(
                        title: 'Ingresos',
                        value: _formatearMonto(data.totalIngresos, data.moneda),
                        icon: Icons.trending_up,
                        color: const Color(0xFF1B7F5A),
                      ),
                      _MetricCard(
                        title: 'Gastos',
                        value: _formatearMonto(data.totalGastos, data.moneda),
                        icon: Icons.trending_down,
                        color: const Color(0xFFB23B3B),
                      ),
                      _MetricCard(
                        title: 'Movimientos',
                        value: data.totalMovimientos.toString(),
                        icon: Icons.receipt_long_outlined,
                        color: theme.colorScheme.primary,
                      ),
                      _MetricCard(
                        title: 'Ahorro',
                        value:
                            '${(data.porcentajeAhorro * 100).toStringAsFixed(1)}%',
                        icon: Icons.savings_outlined,
                        color: const Color(0xFF0F5EAF),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _SectionCard(
                    title: 'Movimiento del mes',
                    child: Column(
                      children: <Widget>[
                        _ResumenRow(
                          label: 'Ingresos del mes',
                          value: _formatearMonto(data.ingresosMes, data.moneda),
                          color: const Color(0xFF1B7F5A),
                        ),
                        const SizedBox(height: 12),
                        _ResumenRow(
                          label: 'Gastos del mes',
                          value: _formatearMonto(data.gastosMes, data.moneda),
                          color: const Color(0xFFB23B3B),
                        ),
                        const SizedBox(height: 12),
                        _ResumenRow(
                          label: 'Balance del mes',
                          value: _formatearMonto(data.balanceMes, data.moneda),
                          color: data.balanceMes >= 0
                              ? const Color(0xFF1B7F5A)
                              : const Color(0xFFB23B3B),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _SectionCard(
                    title: 'Promedios y actividad',
                    child: Column(
                      children: <Widget>[
                        _ResumenRow(
                          label: 'Promedio de ingreso',
                          value: _formatearMonto(
                            data.promedioIngreso,
                            data.moneda,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _ResumenRow(
                          label: 'Promedio de gasto',
                          value: _formatearMonto(
                            data.promedioGasto,
                            data.moneda,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _ResumenRow(
                          label: 'Categorías con ingresos',
                          value: data.topIngresos.isEmpty
                              ? 'Sin datos'
                              : data.topIngresos.first.nombre,
                        ),
                        const SizedBox(height: 12),
                        _ResumenRow(
                          label: 'Categorías con gastos',
                          value: data.topGastos.isEmpty
                              ? 'Sin datos'
                              : data.topGastos.first.nombre,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _SectionCard(
                    title: 'Categorías principales',
                    child: Column(
                      children: <Widget>[
                        if (data.topGastos.isNotEmpty)
                          _TopCategoriesList(
                            title: 'Gastos',
                            categories: data.topGastos,
                            moneda: data.moneda,
                            accent: const Color(0xFFB23B3B),
                          ),
                        if (data.topGastos.isNotEmpty &&
                            data.topIngresos.isNotEmpty)
                          const SizedBox(height: 16),
                        if (data.topIngresos.isNotEmpty)
                          _TopCategoriesList(
                            title: 'Ingresos',
                            categories: data.topIngresos,
                            moneda: data.moneda,
                            accent: const Color(0xFF1B7F5A),
                          ),
                        if (data.topGastos.isEmpty && data.topIngresos.isEmpty)
                          const Text(
                            'Todavía no hay categorías suficientes para mostrar.',
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _SectionCard(
                    title: 'Movimientos recientes',
                    child: Column(
                      children: data.recientes
                          .map(
                            (_MovimientoProcesado movimiento) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _MovimientoTile(
                                movimiento: movimiento,
                                moneda: data.moneda,
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _EstadisticasData {
  const _EstadisticasData({
    required this.moneda,
    required this.totalIngresos,
    required this.totalGastos,
    required this.balance,
    required this.totalMovimientos,
    required this.totalIngresosRegistrados,
    required this.totalGastosRegistrados,
    required this.promedioIngreso,
    required this.promedioGasto,
    required this.porcentajeAhorro,
    required this.ingresosMes,
    required this.gastosMes,
    required this.balanceMes,
    required this.topIngresos,
    required this.topGastos,
    required this.recientes,
  });

  final String moneda;
  final double totalIngresos;
  final double totalGastos;
  final double balance;
  final int totalMovimientos;
  final int totalIngresosRegistrados;
  final int totalGastosRegistrados;
  final double promedioIngreso;
  final double promedioGasto;
  final double porcentajeAhorro;
  final double ingresosMes;
  final double gastosMes;
  final double balanceMes;
  final List<_CategoriaResumen> topIngresos;
  final List<_CategoriaResumen> topGastos;
  final List<_MovimientoProcesado> recientes;
}

class _MovimientoProcesado {
  const _MovimientoProcesado({
    required this.esIngreso,
    required this.monto,
    required this.categoria,
    required this.fecha,
    required this.descripcion,
  });

  factory _MovimientoProcesado.fromMap(Map<String, dynamic> map) {
    final DateTime? fecha = map['fecha'] is String
        ? DateTime.tryParse(map['fecha'] as String)?.toLocal()
        : null;

    return _MovimientoProcesado(
      esIngreso: map['tipo']?.toString() == 'ingreso',
      monto: (map['monto'] as num?)?.toDouble() ?? 0,
      categoria: map['categoria']?.toString().trim().isNotEmpty == true
          ? map['categoria']
                .toString()
                .replaceAll(' / ', ' - ')
                .replaceAll('/', ' - ')
          : 'Sin categoría',
      fecha: fecha,
      descripcion: map['descripcion']?.toString().trim().isNotEmpty == true
          ? map['descripcion'].toString()
          : 'Sin descripción',
    );
  }

  final bool esIngreso;
  final double monto;
  final String categoria;
  final DateTime? fecha;
  final String descripcion;
}

class _CategoriaResumen {
  const _CategoriaResumen({
    required this.nombre,
    required this.monto,
    required this.porcentaje,
  });

  final String nombre;
  final double monto;
  final double porcentaje;
}

class _HeroResumen extends StatelessWidget {
  const _HeroResumen({
    required this.moneda,
    required this.titulo,
    required this.subtitulo,
    required this.valorPrincipal,
    required this.valorSecundario,
    required this.color,
  });

  final String moneda;
  final String titulo;
  final String subtitulo;
  final String valorPrincipal;
  final String valorSecundario;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[
            color.withValues(alpha: 0.96),
            color.withValues(alpha: 0.82),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            titulo,
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitulo,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.86),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            valorPrincipal,
            style: theme.textTheme.displaySmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            valorSecundario,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.86),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              _Badge(text: moneda),
              const SizedBox(width: 8),
              _Badge(text: 'Resumen general'),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: color.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.15),
              foregroundColor: color,
              child: Icon(icon),
            ),
            const SizedBox(height: 14),
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            Text(
              title,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _ResumenRow extends StatelessWidget {
  const _ResumenRow({required this.label, required this.value, this.color});

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Row(
      children: <Widget>[
        Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
        const SizedBox(width: 12),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _TopCategoriesList extends StatelessWidget {
  const _TopCategoriesList({
    required this.title,
    required this.categories,
    required this.moneda,
    required this.accent,
  });

  final String title;
  final List<_CategoriaResumen> categories;
  final String moneda;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        ...categories.map(
          (_CategoriaResumen categoria) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(child: Text(categoria.nombre)),
                    const SizedBox(width: 12),
                    Text(
                      '${(categoria.porcentaje * 100).toStringAsFixed(0)}%',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: accent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    minHeight: 8,
                    value: categoria.porcentaje,
                    backgroundColor: accent.withValues(alpha: 0.12),
                    valueColor: AlwaysStoppedAnimation<Color>(accent),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${categoria.nombre} · ${categoria.monto.toStringAsFixed(2)} ${moneda.toUpperCase()}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MovimientoTile extends StatelessWidget {
  const _MovimientoTile({required this.movimiento, required this.moneda});

  final _MovimientoProcesado movimiento;
  final String moneda;

  String _simboloMoneda(String moneda) {
    switch (moneda.toUpperCase()) {
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      default:
        return r'$';
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool esIngreso = movimiento.esIngreso;
    final Color color = esIngreso
        ? const Color(0xFF1B7F5A)
        : const Color(0xFFB23B3B);
    final String fecha = movimiento.fecha == null
        ? 'Fecha no disponible'
        : '${movimiento.fecha!.day.toString().padLeft(2, '0')}-${movimiento.fecha!.month.toString().padLeft(2, '0')}-${movimiento.fecha!.year}';

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(18),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.12),
          foregroundColor: color,
          child: Icon(esIngreso ? Icons.trending_up : Icons.trending_down),
        ),
        title: Text(
          '${esIngreso ? 'Ingreso' : 'Gasto'} · ${movimiento.categoria}',
        ),
        subtitle: Text('$fecha\n${movimiento.descripcion}'),
        isThreeLine: true,
        trailing: Text(
          '${_simboloMoneda(moneda)}${movimiento.monto.toStringAsFixed(2)}',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _EmptyStatsCard extends StatelessWidget {
  const _EmptyStatsCard({
    required this.title,
    required this.description,
    required this.icon,
  });

  final String title;
  final String description;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: <Widget>[
            CircleAvatar(
              radius: 28,
              backgroundColor: theme.colorScheme.primaryContainer,
              foregroundColor: theme.colorScheme.onPrimaryContainer,
              child: Icon(icon, size: 30),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              description,
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
}
