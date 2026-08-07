import 'package:flutter/material.dart';

import '../services/preferences_service.dart';

/// Pantalla que consulta y presenta el historial persistido de movimientos.
class HistorialScreen extends StatefulWidget {
  const HistorialScreen({super.key});

  @override
  State<HistorialScreen> createState() => _HistorialScreenState();
}

class _HistorialScreenState extends State<HistorialScreen> {
  final PreferencesService _preferencesService = PreferencesService();

  Future<List<Map<String, dynamic>>> _cargarMovimientos() {
    return _preferencesService.obtenerMovimientos();
  }

  String _formatearFecha(String fechaIso) {
    final DateTime fecha = DateTime.parse(fechaIso).toLocal();
    final String dia = fecha.day.toString().padLeft(2, '0');
    final String mes = fecha.month.toString().padLeft(2, '0');
    final String anio = fecha.year.toString();
    final String hora = fecha.hour.toString().padLeft(2, '0');
    final String minuto = fecha.minute.toString().padLeft(2, '0');

    return '$dia/$mes/$anio $hora:$minuto';
  }

  String _formatearMoneda(double monto) {
    return '\$${monto.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Historial')),
      body: SafeArea(
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _cargarMovimientos(),
          builder:
              (
                BuildContext context,
                AsyncSnapshot<List<Map<String, dynamic>>> snapshot,
              ) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final List<Map<String, dynamic>> movimientos =
                    snapshot.data ?? <Map<String, dynamic>>[];

                if (movimientos.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Aún no hay movimientos registrados.',
                        style: theme.textTheme.bodyLarge,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: movimientos.length,
                  separatorBuilder: (BuildContext context, int index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (BuildContext context, int index) {
                    final Map<String, dynamic> movimiento = movimientos[index];
                    final bool esIngreso = movimiento['tipo'] == 'ingreso';
                    final String tipo = esIngreso ? 'Ingreso' : 'Gasto';
                    final double monto =
                        (movimiento['monto'] as num?)?.toDouble() ?? 0.0;
                    final String categoria =
                        movimiento['categoria']?.toString() ?? 'Sin categoría';
                    final String descripcion =
                        movimiento['descripcion']
                                ?.toString()
                                .trim()
                                .isNotEmpty ==
                            true
                        ? movimiento['descripcion'].toString()
                        : 'Sin descripción';
                    final String fecha = movimiento['fecha'] is String
                        ? _formatearFecha(movimiento['fecha'] as String)
                        : 'Fecha no disponible';

                    return Card(
                      elevation: 0,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: esIngreso
                              ? const Color(0xFFE2F6EC)
                              : const Color(0xFFFBE5E5),
                          child: Icon(
                            esIngreso ? Icons.trending_up : Icons.trending_down,
                            color: esIngreso
                                ? const Color(0xFF1B7F5A)
                                : const Color(0xFFB23B3B),
                          ),
                        ),
                        title: Text('$tipo · $categoria'),
                        subtitle: Text('$fecha\n$descripcion'),
                        isThreeLine: true,
                        trailing: Text(
                          _formatearMoneda(monto),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: esIngreso
                                ? const Color(0xFF1B7F5A)
                                : const Color(0xFFB23B3B),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
        ),
      ),
    );
  }
}
