import 'dart:typed_data';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:usb_serial/usb_serial.dart';

void main() => runApp(const NPKReaderApp());

class NPKReaderApp extends StatefulWidget {
  const NPKReaderApp({super.key});

  @override
  State<NPKReaderApp> createState() => _NPKReaderAppState();
}

class _NPKReaderAppState extends State<NPKReaderApp> {
  UsbPort? _port;
  Stream<Uint8List>? _inputStream;
  UsbDevice? _selectedDevice;
  List<UsbDevice> _devices = [];
  bool isConnected = false;
  String data = 'Aucune donnée reçue';
  List<String> log = [];
  Timer? _pollTimer;
  List<int> _buffer = [];

  // Valeurs des capteurs (7-8 registres)
  double? temperature; // Température en °C
  int? humidity; // Humidité en %
  int? conductivity; // Conductivité en µS/cm
  int? ph; // pH (multiplié par 10, ex: 65 = 6.5)
  int? nitrogen; // Azote en mg/kg
  int? phosphorus; // Phosphore en mg/kg
  int? potassium; // Potassium en mg/kg
  int? fertility; // Fertilité en mg/kg (optionnel)

  @override
  void initState() {
    super.initState();
    _addLog("Application démarrée");
    _scanDevices();
    _initUsbListeners();
  }

  void _addLog(String message) {
    setState(() {
      log.insert(0, "${DateTime.now().toIso8601String()} - $message");
      if (log.length > 100) log.removeLast();
    });
    print(message);
  }

  void _initUsbListeners() {
    UsbSerial.usbEventStream!.listen((UsbEvent event) {
      if (event.event == UsbEvent.ACTION_USB_ATTACHED) {
        _addLog("Périphérique USB branché");
        _scanDevices();
      } else if (event.event == UsbEvent.ACTION_USB_DETACHED) {
        _addLog("Périphérique USB débranché");
        _scanDevices();
      }
    });
  }

  Future<void> _scanDevices() async {
    List<UsbDevice> devices = await UsbSerial.listDevices();
    _addLog("Scan USB terminé, ${devices.length} périphérique(s) trouvé(s)");
    setState(() {
      _devices = devices;
      if (_selectedDevice != null &&
          !devices.any((d) => d.deviceId == _selectedDevice!.deviceId)) {
        _disconnect();
        _selectedDevice = null;
      }
    });
  }

  /// Calcul du CRC16 Modbus
  int _calculateCRC16(List<int> data) {
    int crc = 0xFFFF;
    for (int byte in data) {
      crc ^= byte;
      for (int i = 0; i < 8; i++) {
        if ((crc & 0x0001) != 0) {
          crc = (crc >> 1) ^ 0xA001;
        } else {
          crc >>= 1;
        }
      }
    }
    return crc;
  }

  /// Crée une requête Modbus RTU pour lire tous les registres
  Uint8List _createModbusRequest() {
    // Essayez d'abord avec 7 registres, puis 8 si nécessaire
    // Vous pouvez changer 0x07 en 0x08 pour tester
    List<int> request = [
      0x01, // Adresse de l'esclave
      0x03, // Fonction : Read Holding Registers
      0x00, 0x00, // Adresse du premier registre
      0x00, 0x07, // Nombre de registres (7 au lieu de 8 pour tester)
    ];

    // Calcul du CRC
    int crc = _calculateCRC16(request);
    request.add(crc & 0xFF); // CRC Low byte
    request.add((crc >> 8) & 0xFF); // CRC High byte

    return Uint8List.fromList(request);
  }

  /// Parse la réponse Modbus
  void _parseModbusResponse(List<int> response) {
    _addLog(
      "Parsing réponse : ${response.map((b) => '0x${b.toRadixString(16).padLeft(2, '0')}').join(' ')}",
    );

    if (response.length < 5) {
      _addLog("Réponse trop courte (${response.length} bytes)");
      return;
    }

    // Vérification de l'adresse et de la fonction
    int address = response[0];
    int function = response[1];
    int byteCount = response[2];

    if (address != 0x01) {
      _addLog("Adresse incorrecte : $address");
      return;
    }

    if (function != 0x03) {
      _addLog("Fonction incorrecte : $function");
      return;
    }

    // Vérification du CRC
    if (response.length >= byteCount + 5) {
      List<int> dataWithoutCRC = response.sublist(0, response.length - 2);
      int receivedCRC =
          response[response.length - 2] | (response[response.length - 1] << 8);
      int calculatedCRC = _calculateCRC16(dataWithoutCRC);

      if (receivedCRC != calculatedCRC) {
        _addLog(
          "CRC invalide ! Reçu: 0x${receivedCRC.toRadixString(16)}, Calculé: 0x${calculatedCRC.toRadixString(16)}",
        );
        return;
      }
    }

    // Extraction des valeurs (2 bytes par registre)
    // Ordre typique : Humidité, Température, Conductivité, pH, N, P, K, [Fertilité optionnelle]
    int numRegisters = byteCount ~/ 2;
    _addLog("Nombre de registres reçus : $numRegisters");

    if (numRegisters >= 7) {
      // Index des données : commence à response[3]
      humidity = (response[3] << 8) | response[4];
      temperature = ((response[5] << 8) | response[6]) / 10;
      conductivity = (response[7] << 8) | response[8];
      ph = (response[9] << 8) | response[10];
      nitrogen = (response[11] << 8) | response[12];
      phosphorus = (response[13] << 8) | response[14];
      potassium = (response[15] << 8) | response[16];

      // Fertilité optionnelle (8e registre)
      if (numRegisters >= 8 && response.length >= 19) {
        fertility = (response[17] << 8) | response[18];
      } else {
        // Calcul approximatif de la fertilité si non fournie
        fertility =
            ((nitrogen ?? 0) + (phosphorus ?? 0) + (potassium ?? 0)) ~/ 3;
        _addLog("Fertilité calculée à partir de NPK");
      }

      setState(() {
        data = _buildDataString();
        isConnected = true;
      });

      _addLog(
        "Données extraites : T=${temperature}°C, H=${humidity}%, Cond=${conductivity}µS/cm, pH=${(ph! / 10.0).toStringAsFixed(1)}, N=$nitrogen, P=$phosphorus, K=$potassium, Fert=$fertility mg/kg",
      );
    } else {
      _addLog(
        "Nombre de registres insuffisant : $numRegisters (minimum 7 requis)",
      );
    }
  }

  String _buildDataString() {
    StringBuffer buffer = StringBuffer();

    if (temperature != null) {
      buffer.writeln("🌡️ Température: $temperature °C");
    }
    if (humidity != null) {
      buffer.writeln("💧 Humidité: $humidity %");
    }
    if (conductivity != null) {
      buffer.writeln("⚡ Conductivité: $conductivity µS/cm");
    }
    if (ph != null) {
      buffer.writeln("🧪 pH: ${(ph! / 10.0).toStringAsFixed(1)}");
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

  /// Envoie une requête Modbus et attend la réponse
  Future<void> _sendModbusRequest() async {
    if (_port == null || !isConnected) return;

    try {
      Uint8List request = _createModbusRequest();
      _addLog(
        "Envoi requête Modbus : ${request.map((b) => '0x${b.toRadixString(16).padLeft(2, '0')}').join(' ')}",
      );
      await _port!.write(request);
    } catch (e) {
      _addLog("Erreur envoi requête : $e");
    }
  }

  Future<void> _connectDevice(UsbDevice device) async {
    _addLog(
      "Connexion au périphérique ${device.productName} (${device.deviceId})...",
    );
    _port = await device.create();
    bool openResult = await _port!.open();
    if (!openResult) {
      _addLog("Échec d'ouverture du port USB");
      setState(() => data = "Échec d'ouverture du port USB.");
      return;
    }

    await _port!.setDTR(true);
    await _port!.setRTS(true);

    // Essayez différents baudrates : 4800 ou 9600 (les plus courants)
    await _port!.setPortParameters(
      9600, // Changez à 4800 si ça ne marche pas
      UsbPort.DATABITS_8,
      UsbPort.STOPBITS_1,
      UsbPort
          .PARITY_NONE, // Essayez PARITY_EVEN si PARITY_NONE ne fonctionne pas
    );

    _inputStream = _port!.inputStream;
    _addLog("Port série ouvert avec succès (9600 bauds, 8N1)");

    setState(() {
      isConnected = true;
    });

    // Écoute des données entrantes
    _buffer.clear();
    _inputStream!.listen((Uint8List chunk) {
      _addLog(
        "Données brutes reçues (${chunk.length} bytes) : ${chunk.map((b) => '0x${b.toRadixString(16).padLeft(2, '0')}').join(' ')}",
      );

      _buffer.addAll(chunk);

      // Attendre un minimum de temps pour recevoir toute la trame
      // ou détecter dynamiquement la taille de réponse
      if (_buffer.length >= 3 && _buffer[1] == 0x03) {
        int expectedByteCount = _buffer[2];
        int expectedLength = 3 + expectedByteCount + 2; // header + data + CRC

        _addLog("Longueur buffer: ${_buffer.length}, Attendu: $expectedLength");

        if (_buffer.length >= expectedLength) {
          List<int> completeResponse = _buffer.sublist(0, expectedLength);
          _parseModbusResponse(completeResponse);
          _buffer.removeRange(0, expectedLength);
        }
      }

      // Nettoyer le buffer si trop grand (éviter accumulation)
      if (_buffer.length > 50) {
        _addLog("Buffer trop grand, réinitialisation");
        _buffer.clear();
      }
    });

    // Démarre l'interrogation périodique (toutes les 3 secondes)
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _sendModbusRequest();
    });

    // Première requête immédiate
    Future.delayed(const Duration(milliseconds: 500), () {
      _sendModbusRequest();
    });
  }

  Future<void> _disconnect() async {
    _pollTimer?.cancel();
    _pollTimer = null;

    if (_port != null) {
      await _port!.close();
      _addLog("Port USB fermé");
      setState(() {
        _port = null;
        isConnected = false;
        temperature = null;
        humidity = null;
        conductivity = null;
        ph = null;
        nitrogen = null;
        phosphorus = null;
        potassium = null;
        fertility = null;
        data = 'Aucune donnée reçue';
      });
    }
  }

  @override
  void dispose() {
    _disconnect();
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
                      _addLog(
                        "Sélection de périphérique : ${device.productName}",
                      );
                      setState(() {
                        _selectedDevice = device;
                        isConnected = false;
                      });
                      _disconnect().then((_) => _connectDevice(device));
                    }
                  },
                  hint: const Text("Choisir un périphérique"),
                ),
              ],
              const SizedBox(height: 20),
              Icon(
                isConnected ? Icons.sensors : Icons.sensors_off,
                color: isConnected ? Colors.green : Colors.red,
                size: 60,
              ),
              const SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    data,
                    textAlign: TextAlign.left,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (isConnected)
                ElevatedButton.icon(
                  onPressed: _sendModbusRequest,
                  icon: const Icon(Icons.refresh),
                  label: const Text("Lire maintenant"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              const Divider(height: 40),
              const Text(
                "Log :",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Expanded(
                child: ListView.builder(
                  reverse: true,
                  itemCount: log.length,
                  itemBuilder: (context, index) {
                    return Text(
                      log[index],
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
