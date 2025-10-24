class NPKData {
  final double? temperature;
  final int? humidity;
  final int? conductivity;
  final double? ph;
  final int? nitrogen;
  final int? phosphorus;
  final int? potassium;
  final int? fertility;
  final DateTime timestamp;

  NPKData({
    this.temperature,
    this.humidity,
    this.conductivity,
    this.ph,
    this.nitrogen,
    this.phosphorus,
    this.potassium,
    this.fertility,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  @override
  String toString() {
    StringBuffer buffer = StringBuffer();
    if (temperature != null) {
      buffer.writeln("🌡️ Température: ${temperature!.toStringAsFixed(1)} °C");
    }
    if (humidity != null) {
      buffer.writeln("💧 Humidité: $humidity %");
    }
    if (conductivity != null) {
      buffer.writeln("⚡ Conductivité: $conductivity µS/cm");
    }
    if (ph != null) {
      buffer.writeln("🧪 pH: ${ph!.toStringAsFixed(1)}");
    }
    if (nitrogen != null) {
      buffer.writeln("🌿 Azote (N): $nitrogen mg/kg");
    }
    if (phosphorus != null) {
      buffer.writeln("🌱 Phosphore (P): $phosphorus mg/kg");
    }
    if (potassium != null) {
      buffer.writeln("🍃 Potassium (K): $potassium mg/kg");
    }
    if (fertility != null) {
      buffer.writeln("🌾 Fertilité: $fertility mg/kg");
    }
    return buffer.toString().trim();
  }
}
