import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/clima.dart';

class ClimaService {
  static const String apiKey = "dc054c15595c08b7ef428040eea6480c";
  static const String _baseUrl =
      "https://api.openweathermap.org/data/2.5/weather";

  Future<Clima> obtenerClima(String ciudad) async {
    final url = Uri.parse(
      "$_baseUrl"
      "?q=${Uri.encodeComponent(ciudad)}"
      "&appid=$apiKey"
      "&units=metric"
      "&lang=es",
    );

    final response = await http.get(url);

    return _manejarRespuesta(response);
  }

  Future<Clima> obtenerClimaPorCoordenadas({
    required double latitud,
    required double longitud,
  }) async {
    final url = Uri.parse(
      "$_baseUrl"
      "?lat=$latitud"
      "&lon=$longitud"
      "&appid=$apiKey"
      "&units=metric"
      "&lang=es",
    );

    final response = await http.get(url);

    return _manejarRespuesta(response);
  }

  Clima _manejarRespuesta(http.Response response) {
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);

      return Clima.fromJson(data);
    }

    if (response.statusCode == 401) {
      throw Exception("API Key inválida o todavía no está activa.");
    }

    if (response.statusCode == 404) {
      throw Exception("Ciudad no encontrada.");
    }

    throw Exception("Error ${response.statusCode}: ${response.body}");
  }
}
