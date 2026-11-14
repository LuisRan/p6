import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

class SensorsPage extends StatefulWidget {
  const SensorsPage({super.key});
  @override
  State<SensorsPage> createState() => _SensorsPageState();
}

class _SensorsPageState extends State<SensorsPage> with WidgetsBindingObserver {
  StreamSubscription<AccelerometerEvent>? _accel;
  StreamSubscription<GyroscopeEvent>? _gyro;
  AccelerometerEvent? _a;
  GyroscopeEvent? _g;
  String _status = 'Iniciando sensores…';
  int _gestures = 0;
  bool _available = true;
  bool _tilted = false;
  @override
  void initState() { super.initState(); WidgetsBinding.instance.addObserver(this); _start(); }
  void _start() {
    _accel = accelerometerEventStream(samplingPeriod: SensorInterval.normalInterval).listen((e) {
      if (!mounted) return;
      setState(() {
        _a = e;
        _status = 'Lectura física activa';
        if (e.x.abs() > 7.5 && !_tilted) { _gestures++; _tilted = true; }
        if (e.x.abs() < 5) _tilted = false;
      });
    }, onError: _missing);
    _gyro = gyroscopeEventStream(samplingPeriod: SensorInterval.normalInterval).listen((e) {
      if (mounted) setState(() => _g = e);
    }, onError: _missing);
  }
  void _missing(Object _) { if (mounted) setState(() { _available = false; _status = 'Sensor no disponible'; }); }
  void _stop() { _accel?.cancel(); _gyro?.cancel(); _accel = null; _gyro = null; }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) { _available = true; _start(); }
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive || state == AppLifecycleState.detached) _stop();
  }
  @override
  void dispose() { WidgetsBinding.instance.removeObserver(this); _stop(); super.dispose(); }
  Widget _card(String title, String unit, List<double>? v, DateTime? timestamp, IconData icon) => Card(child: ListTile(
    leading: Icon(icon, color: Theme.of(context).colorScheme.primary), title: Text(title),
    subtitle: Text(v == null ? 'Esperando lectura…' : 'x ${v[0].toStringAsFixed(2)}  y ${v[1].toStringAsFixed(2)}  z ${v[2].toStringAsFixed(2)} $unit\nInstante: ${timestamp!.toLocal().toIso8601String()}'),
  ));
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Sensores del dispositivo')),
    body: ListView(padding: const EdgeInsets.all(16), children: [
      Chip(avatar: Icon(_available ? Icons.check_circle : Icons.warning_amber), label: Text(_status)),
      _card('Acelerómetro', 'm/s²', _a == null ? null : [_a!.x,_a!.y,_a!.z], _a?.timestamp, Icons.screen_rotation),
      _card('Giroscopio', 'rad/s', _g == null ? null : [_g!.x,_g!.y,_g!.z], _g?.timestamp, Icons.rotate_90_degrees_ccw),
      const SizedBox(height: 12),
      Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Interacción del juego', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8), const Text('Inclina el teléfono hacia un lado para registrar el movimiento.'),
        Text('Inclinaciones detectadas: $_gestures', style: Theme.of(context).textTheme.headlineSmall),
        Text('Los valores son lecturas físicas del dispositivo; no son datos simulados.', style: Theme.of(context).textTheme.bodySmall),
      ]))),
    ]),
  );
}
