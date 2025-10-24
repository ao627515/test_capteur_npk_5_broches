import 'package:flutter/material.dart';
import 'package:test_capteur/models/npk_data.dart';
import 'package:test_capteur/services/npk_service.dart';
import 'package:test_capteur/services/usb_service.dart';
import 'package:usb_serial/usb_serial.dart';

void main() => runApp(const NPKReaderApp());

class NPKReaderApp extends StatefulWidget {
  const NPKReaderApp({super.key});

  @override
  State<NPKReaderApp> createState() => _NPKReaderAppState();
}

class _NPKReaderAppState extends State<NPKReaderApp> {
  late UsbService _usbService;
  late NPKService _npkService;

  UsbDevice? _selectedDevice;
  List<UsbDevice> _devices = [];
  bool _isConnected = false;
  NPKData? _currentData;
  List<String> _logs = [];

  @override
  void initState() {
    super.initState();
    _usbService = UsbService();
    _npkService = NPKService(_usbService);

    _addLog("Application démarrée");
    _scanDevices();
    _initListeners();
  }

  void _initListeners() {
    // Écoute des événements USB
    _usbService.initUsbEventListener((event) {
      _addLog(event);
      _scanDevices();
    });

    // Écoute des données NPK
    _npkService.dataStream.listen((data) {
      setState(() {
        _currentData = data;
      });
    });

    // Écoute des logs NPK
    _npkService.logStream.listen((log) {
      _addLog(log);
    });
  }

  void _addLog(String message) {
    setState(() {
      _logs.insert(0, message);
      if (_logs.length > 100) _logs.removeLast();
    });
  }

  Future<void> _scanDevices() async {
    List<UsbDevice> devices = await _usbService.scanDevices();
    _addLog("Scan USB: ${devices.length} périphérique(s) trouvé(s)");
    setState(() {
      _devices = devices;
      if (_selectedDevice != null &&
          !devices.any((d) => d.deviceId == _selectedDevice!.deviceId)) {
        _disconnect();
        _selectedDevice = null;
      }
    });
  }

  Future<void> _connectDevice(UsbDevice device) async {
    _addLog("Connexion à ${device.productName}...");

    bool connected = await _usbService.connect(device);
    if (!connected) {
      _addLog("Échec de connexion");
      return;
    }

    _addLog("Connecté avec succès");
    setState(() {
      _isConnected = true;
    });

    _npkService.startPolling();
  }

  Future<void> _disconnect() async {
    _npkService.stopPolling();
    await _usbService.disconnect();
    setState(() {
      _isConnected = false;
      _currentData = null;
    });
    _addLog("Déconnecté");
  }

  @override
  void dispose() {
    _npkService.dispose();
    _usbService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Capteur NPK Multi-Paramètres'),
          backgroundColor: Colors.green,
        ),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Sélection du périphérique
              if (_devices.isEmpty)
                const Text("Aucun périphérique USB détecté")
              else ...[
                const Text("Sélectionnez un périphérique :"),
                const SizedBox(height: 10),
                DropdownButton<UsbDevice>(
                  value: _selectedDevice,
                  items: _devices.map((device) {
                    return DropdownMenuItem(
                      value: device,
                      child: Text("${device.productName} (${device.deviceId})"),
                    );
                  }).toList(),
                  onChanged: (device) {
                    if (device != null) {
                      setState(() {
                        _selectedDevice = device;
                      });
                      _disconnect().then((_) => _connectDevice(device));
                    }
                  },
                  hint: const Text("Choisir un périphérique"),
                ),
              ],
              const SizedBox(height: 20),

              // Indicateur de connexion
              Icon(
                _isConnected ? Icons.sensors : Icons.sensors_off,
                color: _isConnected ? Colors.green : Colors.red,
                size: 60,
              ),
              const SizedBox(height: 20),

              // Données NPK
              Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    _currentData?.toString() ?? 'Aucune donnée reçue',
                    textAlign: TextAlign.left,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Bouton lecture manuelle
              if (_isConnected)
                ElevatedButton.icon(
                  onPressed: () => _npkService.sendRequest(),
                  icon: const Icon(Icons.refresh),
                  label: const Text("Lire maintenant"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),

              const Divider(height: 40),

              // Log
              const Text(
                "Log :",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Expanded(
                child: ListView.builder(
                  reverse: true,
                  itemCount: _logs.length,
                  itemBuilder: (context, index) {
                    return Text(
                      _logs[index],
                      style: const TextStyle(fontSize: 11),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
