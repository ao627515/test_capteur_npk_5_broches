import 'dart:typed_data';
import 'dart:async';
import 'package:usb_serial/usb_serial.dart';

class UsbService {
  UsbPort? _port;
  Stream<Uint8List>? _inputStream;
  StreamController<List<int>>? _dataController;
  StreamSubscription? _usbEventSubscription;
  StreamSubscription? _inputSubscription;

  Stream<List<int>>? get dataStream => _dataController?.stream;
  bool get isConnected => _port != null;

  Future<List<UsbDevice>> scanDevices() async {
    return await UsbSerial.listDevices();
  }

  void initUsbEventListener(Function(String) onEvent) {
    _usbEventSubscription = UsbSerial.usbEventStream!.listen((UsbEvent event) {
      if (event.event == UsbEvent.ACTION_USB_ATTACHED) {
        onEvent("Périphérique USB branché");
      } else if (event.event == UsbEvent.ACTION_USB_DETACHED) {
        onEvent("Périphérique USB débranché");
      }
    });
  }

  Future<bool> connect(UsbDevice device, {int baudRate = 9600}) async {
    try {
      await disconnect();

      _port = await device.create();
      bool openResult = await _port!.open();
      if (!openResult) {
        return false;
      }

      await _port!.setDTR(true);
      await _port!.setRTS(true);
      await _port!.setPortParameters(
        baudRate,
        UsbPort.DATABITS_8,
        UsbPort.STOPBITS_1,
        UsbPort.PARITY_NONE,
      );

      _inputStream = _port!.inputStream;
      _dataController = StreamController<List<int>>.broadcast();

      List<int> buffer = [];
      _inputSubscription = _inputStream!.listen((Uint8List chunk) {
        buffer.addAll(chunk);

        // Détection de trame Modbus complète
        if (buffer.length >= 3 && buffer[1] == 0x03) {
          int expectedByteCount = buffer[2];
          int expectedLength = 3 + expectedByteCount + 2;

          if (buffer.length >= expectedLength) {
            List<int> completeResponse = buffer.sublist(0, expectedLength);
            _dataController?.add(completeResponse);
            buffer.removeRange(0, expectedLength);
          }
        }

        // Nettoyage du buffer
        if (buffer.length > 50) {
          buffer.clear();
        }
      });

      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> write(Uint8List data) async {
    if (_port != null) {
      await _port!.write(data);
    }
  }

  Future<void> disconnect() async {
    await _inputSubscription?.cancel();
    _inputSubscription = null;

    await _dataController?.close();
    _dataController = null;

    if (_port != null) {
      await _port!.close();
      _port = null;
    }
  }

  void dispose() {
    disconnect();
    _usbEventSubscription?.cancel();
  }
}
