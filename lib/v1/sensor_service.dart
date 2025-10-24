import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'sensor_data_model.dart';

/// Service de gestion des données de capteurs
class SensorService extends ChangeNotifier {
  SensorData? _currentData;
  final List<SensorData> _history = [];
  Timer? _simulationTimer;
  bool _isConnected = false;

  SensorData? get currentData => _currentData;
  List<SensorData> get history => List.unmodifiable(_history);
  bool get isConnected => _isConnected;

  /// Démarre la simulation de lecture des capteurs
  void startSimulation() {
    if (_simulationTimer != null) return;

    _isConnected = true;
    _simulationTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _generateSensorData(),
    );

    // Génère les données initiales
    _generateSensorData();
    notifyListeners();
  }

  /// Arrête la simulation
  void stopSimulation() {
    _simulationTimer?.cancel();
    _simulationTimer = null;
    _isConnected = false;
    notifyListeners();
  }

  /// Génère des données de capteur simulées (pour testing)
  void _generateSensorData() {
    final random = Random();

    _currentData = SensorData(
      temperature: 20 + random.nextDouble() * 15, // 20-35°C
      humidity: 40 + random.nextDouble() * 40, // 40-80%
      conductivity: 500 + random.nextDouble() * 1500, // 500-2000 us/cm
      ph: 5.5 + random.nextDouble() * 2.5, // 5.5-8.0
      nitrogen: 50 + random.nextDouble() * 150, // 50-200 mg/kg
      phosphorus: 20 + random.nextDouble() * 80, // 20-100 mg/kg
      kalium: 100 + random.nextDouble() * 300, // 100-400 mg/kg
      fertility: 60 + random.nextDouble() * 40, // 60-100 mg/kg
    );

    _history.add(_currentData!);

    // Garde seulement les 100 dernières lectures
    if (_history.length > 100) {
      _history.removeAt(0);
    }

    notifyListeners();
  }

  /// Met à jour manuellement les données (pour capteurs réels)
  void updateSensorData(SensorData data) {
    _currentData = data;
    _history.add(data);

    if (_history.length > 100) {
      _history.removeAt(0);
    }

    notifyListeners();
  }

  /// Sauvegarde les données (peut être étendu pour sauvegarder en base de données)
  Future<bool> saveData() async {
    try {
      if (_currentData == null) return false;

      // Ici, vous pouvez implémenter la sauvegarde en base de données
      // Par exemple avec sqflite, hive, ou firebase

      if (kDebugMode) {
        print('Données sauvegardées: ${_currentData!.toJson()}');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de la sauvegarde: $e');
      }
      return false;
    }
  }

  /// Exporte l'historique en JSON
  String exportHistoryAsJson() {
    final jsonList = _history.map((data) => data.toJson()).toList();
    return jsonEncode(jsonList);
  }

  /// Récupère les statistiques des données
  Map<String, double> getStatistics() {
    if (_history.isEmpty) return {};

    double avgTemp = 0, avgHum = 0, avgPh = 0;
    int count = 0;

    for (final data in _history) {
      if (data.temperature != null) avgTemp += data.temperature!;
      if (data.humidity != null) avgHum += data.humidity!;
      if (data.ph != null) avgPh += data.ph!;
      count++;
    }

    return {
      'avgTemperature': avgTemp / count,
      'avgHumidity': avgHum / count,
      'avgPh': avgPh / count,
      'dataCount': count.toDouble(),
    };
  }

  /// Nettoie les ressources
  @override
  void dispose() {
    stopSimulation();
    super.dispose();
  }
}
