import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'sensor_service.dart';
import 'sensor_data_model.dart';


class AgricultureMonitorScreen extends StatefulWidget {
  const AgricultureMonitorScreen({super.key});

  @override
  State<AgricultureMonitorScreen> createState() =>
      _AgricultureMonitorScreenState();
}

class _AgricultureMonitorScreenState extends State<AgricultureMonitorScreen> {
  @override
  void initState() {
    super.initState();
    // Démarre la simulation au lancement
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SensorService>().startSimulation();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF6B4CE6), Color(0xFF5B3CD6)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Image d'en-tête
              Expanded(
                flex: 3,
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    image: const DecorationImage(
                      image: AssetImage('assets/images/agriculture_banner.jpg'),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Bouton de traduction (optionnel)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.translate,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Grille de paramètres
              Expanded(
                flex: 5,
                child: Consumer<SensorService>(
                  builder: (context, service, child) {
                    final data = service.currentData;

                    return GridView.count(
                      padding: const EdgeInsets.all(16),
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.3,
                      children: [
                        _SensorCard(
                          title: 'Temperature',
                          value: data?.temperature?.toStringAsFixed(1) ?? '--',
                          unit: '°C',
                          icon: Icons.thermostat,
                          color: const Color(0xFF7ED957),
                        ),
                        _SensorCard(
                          title: 'Humidity',
                          value: data?.humidity?.toStringAsFixed(1) ?? '--',
                          unit: '%',
                          icon: Icons.water_drop,
                          color: const Color(0xFF6BA3F5),
                        ),
                        _SensorCard(
                          title: 'Conductivity',
                          value: data?.conductivity?.toStringAsFixed(0) ?? '--',
                          unit: 'us/cm',
                          icon: Icons.flash_on,
                          color: const Color(0xFF5B4CE6),
                        ),
                        _SensorCard(
                          title: 'PH',
                          value: data?.ph?.toStringAsFixed(1) ?? '--',
                          unit: 'Ph',
                          icon: Icons.science,
                          color: const Color(0xFFD4E157),
                        ),
                        _SensorCard(
                          title: 'Nitrogen',
                          value: data?.nitrogen?.toStringAsFixed(0) ?? '--',
                          unit: 'mg/kg',
                          icon: Icons.nature,
                          color: const Color(0xFFFF6B9D),
                        ),
                        _SensorCard(
                          title: 'Phosphorus',
                          value: data?.phosphorus?.toStringAsFixed(0) ?? '--',
                          unit: 'mg/kg',
                          icon: Icons.spa,
                          color: const Color(0xFF5B8EF5),
                        ),
                        _SensorCard(
                          title: 'Kalium',
                          value: data?.kalium?.toStringAsFixed(0) ?? '--',
                          unit: 'mg/kg',
                          icon: Icons.grass,
                          color: const Color(0xFF4DB8C4),
                        ),
                        _SensorCard(
                          title: 'Fertility',
                          value: data?.fertility?.toStringAsFixed(0) ?? '--',
                          unit: 'mg/kg',
                          icon: Icons.eco,
                          color: const Color(0xFFFF9671),
                        ),
                      ],
                    );
                  },
                ),
              ),

              // Boutons d'action
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _saveData(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3D4A7A),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Save the data',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _reviewData(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2C3654),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Review the data',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _saveData(BuildContext context) async {
    final service = context.read<SensorService>();
    final success = await service.saveData();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Données sauvegardées avec succès'
                : 'Échec de la sauvegarde',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  void _reviewData(BuildContext context) {
    final service = context.read<SensorService>();
    final stats = service.getStatistics();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Statistiques des données'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Température moyenne: ${stats['avgTemperature']?.toStringAsFixed(1) ?? '--'}°C',
            ),
            Text(
              'Humidité moyenne: ${stats['avgHumidity']?.toStringAsFixed(1) ?? '--'}%',
            ),
            Text('pH moyen: ${stats['avgPh']?.toStringAsFixed(2) ?? '--'}'),
            Text('Nombre de mesures: ${stats['dataCount']?.toInt() ?? 0}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }
}

class _SensorCard extends StatelessWidget {
  final String title;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;

  const _SensorCard({
    required this.title,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Icon(icon, color: Colors.white.withOpacity(0.9), size: 28),
              ],
            ),
            const Spacer(),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              unit,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
