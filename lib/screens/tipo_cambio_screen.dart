import 'package:flutter/material.dart';

import '../models/tipo_cambio.dart';
import '../services/tipo_cambio_service.dart';

class TipoCambioScreen extends StatefulWidget {
  const TipoCambioScreen({super.key});

  @override
  State<TipoCambioScreen> createState() => _TipoCambioScreenState();
}

class _TipoCambioScreenState extends State<TipoCambioScreen> {
  final TipoCambioService _tipoCambioService = TipoCambioService();

  late Future<List<TipoCambio>> _futureTiposCambio;

  @override
  void initState() {
    super.initState();

    _futureTiposCambio = _tipoCambioService.obtenerTiposCambio();
  }

  void _actualizarDatos() {
    setState(() {
      _futureTiposCambio = _tipoCambioService.obtenerTiposCambio();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tipo de cambio'),
        actions: [
          IconButton(
            onPressed: _actualizarDatos,
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: FutureBuilder<List<TipoCambio>>(
        future: _futureTiposCambio,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 60),
                    const SizedBox(height: 16),
                    const Text(
                      'No se pudo obtener el tipo de cambio.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('${snapshot.error}', textAlign: TextAlign.center),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _actualizarDatos,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Intentar nuevamente'),
                    ),
                  ],
                ),
              ),
            );
          }

          final tiposCambio = snapshot.data ?? [];

          final monedasMostrar = ['USD', 'EUR', 'GBP', 'JPY', 'CAD'];

          final monedasFiltradas = tiposCambio
              .where((tipoCambio) => monedasMostrar.contains(tipoCambio.moneda))
              .toList();

          return RefreshIndicator(
            onRefresh: () async {
              _actualizarDatos();
              await _futureTiposCambio;
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        const Icon(Icons.currency_exchange, size: 55),
                        const SizedBox(height: 12),
                        const Text(
                          'Peso Mexicano',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 5),
                        const Text(
                          '1 MXN equivale a:',
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                ...monedasFiltradas.map(
                  (tipoCambio) => Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: const CircleAvatar(
                        child: Icon(Icons.attach_money),
                      ),
                      title: Text(
                        tipoCambio.moneda,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: const Text('Valor respecto a 1 MXN'),
                      trailing: Text(
                        tipoCambio.valor.toStringAsFixed(4),
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
