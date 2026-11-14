import 'package:flutter/material.dart';

import '../../core/theme/app_themes.dart';
import '../../core/utils/formatters.dart';
import '../../main.dart';
import '../browser/file_actions.dart';

/// Ajustes: selector de tema (el modo claro/oscuro sigue al sistema) y caché.
class SettingsView extends StatefulWidget {
  const SettingsView({super.key, required this.services});
  final AppServices services;
  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  @override
  Widget build(BuildContext context) {
    final s = widget.services;
    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
      body: ListView(children: [
        const ListTile(title: Text('Tema')),
        RadioGroup<AppThemeChoice>(
          groupValue: s.prefs.theme,
          onChanged: (v) { if (v != null) s.prefs.setTheme(v); },
          child: Column(children: [
            for (final t in AppThemeChoice.values)
              RadioListTile<AppThemeChoice>(
                value: t,
                title: Text(t.label),
                secondary: CircleAvatar(backgroundColor: t.seed, radius: 12),
              ),
          ]),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text('El modo claro u oscuro se ajusta automáticamente a la configuración del sistema.'),
        ),
        const Divider(),
        FutureBuilder<int>(
          future: s.thumbs.sizeOnDisk(),
          builder: (_, snap) => ListTile(
            leading: const Icon(Icons.cleaning_services),
            title: const Text('Limpiar caché de miniaturas'),
            subtitle: Text('Ocupa ${formatBytes(snap.data ?? 0)} (límite ${formatBytes(s.thumbs.maxBytes)})'),
            onTap: () async {
              await s.thumbs.clear();
              if (!context.mounted) return;
              setState(() {});
              showInfo(context, 'Caché limpiada.');
            },
          ),
        ),
        const ListTile(
          leading: Icon(Icons.info_outline),
          title: Text('Gestor de Archivos'),
          subtitle: Text('IPN ESCOM · funciona 100% sin conexión'),
        ),
      ]),
    );
  }
}
