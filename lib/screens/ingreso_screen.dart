import 'package:flutter/material.dart';

import '../services/preferences_service.dart';

/// Pantalla para registrar ingresos y sincronizar el resumen financiero.
class IngresoScreen extends StatefulWidget {
  const IngresoScreen({super.key});

  @override
  State<IngresoScreen> createState() => _IngresoScreenState();
}

class _IngresoScreenState extends State<IngresoScreen> {
  final PreferencesService _preferencesService = PreferencesService();
  final TextEditingController _montoController = TextEditingController();
  final TextEditingController _descripcionController = TextEditingController();
  final List<String> _categorias = <String>[
    'Sueldo / nómina',
    'Bonos y comisiones',
    'Aguinaldo',
    'Horas extra',
    'Propinas',
    'Ventas',
    'Freelance / trabajos independientes',
    'Honorarios profesionales',
    'Dividendos',
    'Intereses',
    'Rendimientos de inversiones',
    'Ganancias de criptomonedas o acciones',
    'Renta de propiedades',
    'Regalías',
    'Regalos en efectivo',
    'Reembolsos / cashback',
    'Venta de artículos usados',
    'Préstamos recibidos',
    'Premios / rifas',
    'Pensión / jubilación',
    'Apoyos gubernamentales',
    'Herencias',
    'Indemnizaciones',
    'Ingresos únicos o eventuales',
  ];

  String? _categoriaSeleccionada;
  DateTime _fechaSeleccionada = DateTime.now();

  @override
  void dispose() {
    _montoController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  void _salirDeLaPantalla() {
    Navigator.maybePop(context);
  }

  Future<void> _seleccionarFecha() async {
    final DateTime? fecha = await showDatePicker(
      context: context,
      initialDate: _fechaSeleccionada,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (fecha != null && mounted) {
      setState(() {
        _fechaSeleccionada = fecha;
      });
    }
  }

  Future<void> _guardarIngreso() async {
    final String montoTexto = _montoController.text.trim();
    final String descripcion = _descripcionController.text.trim();

    final double? monto = double.tryParse(montoTexto);

    if (monto == null) {
      _mostrarMensaje('Ingresa un monto numérico válido.');
      return;
    }

    if (monto <= 0) {
      _mostrarMensaje('El monto debe ser mayor a 0.');
      return;
    }

    if (_categoriaSeleccionada == null) {
      _mostrarMensaje('Selecciona una categoría para el ingreso.');
      return;
    }

    final double totalGastos = await _preferencesService.obtenerTotalGastos();
    final double totalIngresosActual = await _preferencesService
        .obtenerTotalIngresos();
    final double totalIngresosNuevo = totalIngresosActual + monto;
    final double saldoNuevo = totalIngresosNuevo - totalGastos;

    await _preferencesService.guardarTotalIngresos(totalIngresosNuevo);
    await _preferencesService.agregarMovimiento(<String, dynamic>{
      'tipo': 'ingreso',
      'monto': monto,
      'categoria': _categoriaSeleccionada,
      'fecha': _fechaSeleccionada.toIso8601String(),
      'descripcion': descripcion,
      'saldoPosterior': saldoNuevo,
    });

    if (!mounted) {
      return;
    }

    _mostrarMensaje('Ingreso guardado correctamente');
    Navigator.pop(context);
  }

  void _mostrarMensaje(String mensaje) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(mensaje)));
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final InputDecoration decoration = InputDecoration(
      filled: true,
      fillColor: theme.colorScheme.surfaceContainerHighest.withValues(
        alpha: 0.35,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar ingreso'),
        leading: IconButton(
          tooltip: 'Salir',
          icon: const Icon(Icons.close),
          onPressed: _salirDeLaPantalla,
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextField(
              controller: _montoController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: decoration.copyWith(
                labelText: 'Monto',
                hintText: '0.00',
                prefixIcon: const Icon(Icons.attach_money),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _categoriaSeleccionada,
              decoration: decoration.copyWith(
                labelText: 'Categoría',
                prefixIcon: const Icon(Icons.category_outlined),
              ),
              items: _categorias
                  .map(
                    (String categoria) => DropdownMenuItem<String>(
                      value: categoria,
                      child: Text(categoria),
                    ),
                  )
                  .toList(),
              onChanged: (String? value) {
                setState(() {
                  _categoriaSeleccionada = value;
                });
              },
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event_outlined),
              title: const Text('Fecha'),
              subtitle: Text(
                '${_fechaSeleccionada.day.toString().padLeft(2, '0')}/${_fechaSeleccionada.month.toString().padLeft(2, '0')}/${_fechaSeleccionada.year}',
              ),
              trailing: TextButton(
                onPressed: _seleccionarFecha,
                child: const Text('Cambiar'),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descripcionController,
              maxLines: 3,
              decoration: decoration.copyWith(
                labelText: 'Descripción opcional',
                hintText: 'Ej. pago de quincena',
                prefixIcon: const Icon(Icons.notes_outlined),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _guardarIngreso,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text('Guardar ingreso'),
            ),
          ],
        ),
      ),
    );
  }
}
