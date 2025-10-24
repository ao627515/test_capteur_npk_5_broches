/// Modèle de données pour les capteurs agricoles
class SensorData {
  final double? temperature; // °C
  final double? humidity; // %
  final double? conductivity; // us/cm
  final double? ph; // pH
  final double? nitrogen; // mg/kg
  final double? phosphorus; // mg/kg
  final double? kalium; // mg/kg
  final double? fertility; // mg/kg
  final DateTime timestamp;

  SensorData({
    this.temperature,
    this.humidity,
    this.conductivity,
    this.ph,
    this.nitrogen,
    this.phosphorus,
    this.kalium,
    this.fertility,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Constructeur depuis JSON
  factory SensorData.fromJson(Map<String, dynamic> json) {
    return SensorData(
      temperature: json['temperature']?.toDouble(),
      humidity: json['humidity']?.toDouble(),
      conductivity: json['conductivity']?.toDouble(),
      ph: json['ph']?.toDouble(),
      nitrogen: json['nitrogen']?.toDouble(),
      phosphorus: json['phosphorus']?.toDouble(),
      kalium: json['kalium']?.toDouble(),
      fertility: json['fertility']?.toDouble(),
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
    );
  }

  /// Conversion en JSON
  Map<String, dynamic> toJson() {
    return {
      'temperature': temperature,
      'humidity': humidity,
      'conductivity': conductivity,
      'ph': ph,
      'nitrogen': nitrogen,
      'phosphorus': phosphorus,
      'kalium': kalium,
      'fertility': fertility,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// Copie avec modification
  SensorData copyWith({
    double? temperature,
    double? humidity,
    double? conductivity,
    double? ph,
    double? nitrogen,
    double? phosphorus,
    double? kalium,
    double? fertility,
    DateTime? timestamp,
  }) {
    return SensorData(
      temperature: temperature ?? this.temperature,
      humidity: humidity ?? this.humidity,
      conductivity: conductivity ?? this.conductivity,
      ph: ph ?? this.ph,
      nitrogen: nitrogen ?? this.nitrogen,
      phosphorus: phosphorus ?? this.phosphorus,
      kalium: kalium ?? this.kalium,
      fertility: fertility ?? this.fertility,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  /// Vérifie si toutes les données sont disponibles
  bool get isComplete {
    return temperature != null &&
        humidity != null &&
        conductivity != null &&
        ph != null &&
        nitrogen != null &&
        phosphorus != null &&
        kalium != null &&
        fertility != null;
  }

  @override
  String toString() {
    return 'SensorData(temp: $temperature°C, hum: $humidity%, ph: $ph)';
  }
}
