import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_themes.dart';

/// Persistencia con shared_preferences (clave/valor): recientes, favoritos,
/// carpetas externas añadidas, tema y bandera de siembra. Se eligió sobre
/// SQLite porque los datos son listas pequeñas de rutas.
class PrefsStore extends ChangeNotifier {
  PrefsStore(this._p);
  final SharedPreferences _p;

  static const maxRecents = 20;

  static Future<PrefsStore> load() async => PrefsStore(await SharedPreferences.getInstance());

  List<String> get favorites => _p.getStringList('favorites') ?? [];
  List<String> get recents => _p.getStringList('recents') ?? [];
  List<String> get externalRoots => _p.getStringList('roots') ?? [];
  bool get seeded => _p.getBool('seeded') ?? false;
  bool get explainedAccess => _p.getBool('explained') ?? false;

  AppThemeChoice get theme => AppThemeChoice.values.firstWhere(
        (t) => t.name == _p.getString('theme'),
        orElse: () => AppThemeChoice.guinda,
      );

  Future<void> setTheme(AppThemeChoice t) async {
    await _p.setString('theme', t.name);
    notifyListeners();
  }

  Future<void> setSeeded() => _p.setBool('seeded', true);
  Future<void> setExplained() => _p.setBool('explained', true);

  bool isFavorite(String path) => favorites.contains(path);

  Future<void> toggleFavorite(String path) async {
    final l = favorites;
    l.contains(path) ? l.remove(path) : l.add(path);
    await _p.setStringList('favorites', l);
    notifyListeners();
  }

  /// Más reciente primero, sin duplicados, máximo [maxRecents].
  Future<void> addRecent(String path) async {
    final l = recents..remove(path);
    l.insert(0, path);
    await _p.setStringList('recents', l.take(maxRecents).toList());
    notifyListeners();
  }

  Future<void> clearRecents() async {
    await _p.remove('recents');
    notifyListeners();
  }

  /// Quita rutas que ya no existen o fueron renombradas/eliminadas.
  Future<void> forget(String path) async {
    await _p.setStringList('favorites', favorites..remove(path));
    await _p.setStringList('recents', recents..remove(path));
    notifyListeners();
  }

  Future<void> addRoot(String path) async {
    final l = externalRoots;
    if (!l.contains(path)) l.add(path);
    await _p.setStringList('roots', l);
    notifyListeners();
  }

  Future<void> removeRoot(String path) async {
    await _p.setStringList('roots', externalRoots..remove(path));
    notifyListeners();
  }
}
