import 'package:flutter/material.dart';

import 'core/app_theme.dart';
import 'core/services.dart';
import 'ui/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final services = await AppServices.create();
  runApp(CircuitoApp(services: services));
}

class CircuitoApp extends StatelessWidget {
  const CircuitoApp({super.key, required this.services});
  final AppServices services;

  @override
  Widget build(BuildContext context) {
    return ServicesScope(
      services: services,
      child: ListenableBuilder(
        listenable: services.settings,
        builder: (context, _) => MaterialApp(
          title: 'Circuito Guinda',
          debugShowCheckedModeBanner: false,
          theme: buildTheme(services.settings.palette, Brightness.light),
          darkTheme: buildTheme(services.settings.palette, Brightness.dark),
          themeMode: ThemeMode.system, // claro/oscuro automático
          home: const HomeScreen(),
        ),
      ),
    );
  }
}
