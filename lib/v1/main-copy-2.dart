import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'sensor_service.dart';
import 'agriculture_monitor_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SensorService(),
      child: MaterialApp(
        title: 'Agriculture Monitor',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF6B4CE6),
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          fontFamily: 'Roboto',
        ),
        home: const AgricultureMonitorScreen(),
      ),
    );
  }
}
