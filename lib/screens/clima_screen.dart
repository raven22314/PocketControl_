import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../models/clima.dart';
import '../services/clima_service.dart';

class ClimaScreen extends StatefulWidget {
  const ClimaScreen({super.key});

  @override
  State<ClimaScreen> createState() => _ClimaScreenState();
}

class _ClimaScreenState extends State<ClimaScreen> {
  final ClimaService _climaService = ClimaService();
  final TextEditingController _ciudadController = TextEditingController();

  Clima? _clima;
  bool _cargando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _buscarClimaPorUbicacion();
  }

  Future<void> _buscarClima() async {
    final ciudad = _ciudadController.text.trim();

    if (ciudad.isEmpty) {
      setState(() {
        _error = 'Escribe una ciudad.';
      });
      return;
    }

    setState(() {
      _cargando = true;
      _error = null;
      _clima = null;
    });

    try {
      final clima = await _climaService.obtenerClima(ciudad);

      if (!mounted) {
        return;
      }

      setState(() {
        _clima = clima;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _cargando = false;
      });
    }
  }

  Future<void> _buscarClimaPorUbicacion() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final bool servicioHabilitado =
          await Geolocator.isLocationServiceEnabled();
      if (!servicioHabilitado) {
        throw Exception('Activa el GPS para obtener tu ubicación actual.');
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
          'Permiso de ubicación denegado permanentemente. Habilítalo desde ajustes.',
        );
      }

      final Position posicion = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      final clima = await _climaService.obtenerClimaPorCoordenadas(
        latitud: posicion.latitude,
        longitud: posicion.longitude,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _clima = clima;
        _ciudadController.text = clima.ciudad;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _cargando = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _ciudadController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Clima')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Icon(Icons.cloud, size: 70),

            const SizedBox(height: 16),

            const Text(
              'Consulta el clima de una ciudad',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _cargando ? null : _buscarClimaPorUbicacion,
                icon: const Icon(Icons.my_location),
                label: const Text('Usar mi ubicación actual'),
              ),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: _ciudadController,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _buscarClima(),
              decoration: const InputDecoration(
                labelText: 'Ciudad',
                hintText: 'Ejemplo: Tokio',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_city),
              ),
            ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _cargando ? null : _buscarClima,
                icon: const Icon(Icons.search),
                label: const Text('Buscar clima'),
              ),
            ),

            const SizedBox(height: 30),

            if (_cargando) const CircularProgressIndicator(),

            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Column(
                  children: [
                    const Icon(Icons.error_outline, size: 50),
                    const SizedBox(height: 10),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),

            if (_clima != null)
              Card(
                margin: const EdgeInsets.only(top: 20),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text(
                        _clima!.ciudad,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 10),

                      Image.network(
                        'https://openweathermap.org/img/wn/${_clima!.icono}@2x.png',
                        width: 100,
                        height: 100,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.cloud, size: 80);
                        },
                      ),

                      Text(
                        '${_clima!.temperatura.toStringAsFixed(1)} °C',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 10),

                      Text(
                        _clima!.descripcion.toUpperCase(),
                        style: const TextStyle(fontSize: 17),
                      ),

                      const Divider(height: 30),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(
                            children: [
                              const Icon(Icons.water_drop),
                              const SizedBox(height: 5),
                              const Text('Humedad'),
                              Text(
                                '${_clima!.humedad}%',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),

                          Column(
                            children: [
                              const Icon(Icons.thermostat),
                              const SizedBox(height: 5),
                              const Text('Temperatura'),
                              Text(
                                '${_clima!.temperatura.toStringAsFixed(1)} °C',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
