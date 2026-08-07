class Clima {
  final String ciudad;
  final double temperatura;
  final int humedad;
  final String descripcion;
  final String icono;

  Clima({
    required this.ciudad,
    required this.temperatura,
    required this.humedad,
    required this.descripcion,
    required this.icono,
  });

  factory Clima.fromJson(Map<String, dynamic> json) {
    return Clima(
      ciudad: json["name"],
      temperatura: (json["main"]["temp"] as num).toDouble(),
      humedad: json["main"]["humidity"],
      descripcion: json["weather"][0]["description"],
      icono: json["weather"][0]["icon"],
    );
  }
}
