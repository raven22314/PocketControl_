import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/tipo_cambio.dart';

class TipoCambioService {
  static const String _url = "https://open.er-api.com/v6/latest/MXN";

  Future<List<TipoCambio>> obtenerTiposCambio() async {
    final response = await http.get(Uri.parse(_url));

    if (response.statusCode != 200) {
      throw Exception("Error al obtener el tipo de cambio");
    }

    final Map<String, dynamic> data = jsonDecode(response.body);

    final Map<String, dynamic> rates = data["rates"];

    return rates.entries
        .map((e) => TipoCambio.fromMap(e.key, e.value))
        .toList();
  }
}
