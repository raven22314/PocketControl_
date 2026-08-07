class TipoCambio {
  final String moneda;
  final double valor;

  TipoCambio({required this.moneda, required this.valor});

  factory TipoCambio.fromMap(String moneda, dynamic valor) {
    return TipoCambio(moneda: moneda, valor: (valor as num).toDouble());
  }
}
