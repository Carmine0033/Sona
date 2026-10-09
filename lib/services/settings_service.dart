import 'dart:convert';
import 'dart:io';

class SettingsService {
  static late File _file;
  static Map<String, dynamic> _data = {};

  static Directory get _baseDir {
    final base = Platform.environment['APPDATA'] ?? Directory.systemTemp.path;
    final dir = Directory('$base\\Sona');
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return dir;
  }

  static Future<void> init() async {
    _file = File('${_baseDir.path}\\settings.json');
    if (_file.existsSync()) {
      try {
        _data = jsonDecode(_file.readAsStringSync()) as Map<String, dynamic>;
      } catch (_) {
        _data = {};
      }
    }
  }

  static bool getBool(String k, bool def) => _data[k] is bool ? _data[k] : def;
  static int getInt(String k, int def) =>
      _data[k] is num ? (_data[k] as num).toInt() : def;
  static String? getString(String k) => _data[k] is String ? _data[k] : null;

  static void _save() {
    try {
      _file.writeAsStringSync(jsonEncode(_data));
    } catch (_) {}
  }

  static Future<void> setBool(String k, bool v) async { _data[k] = v; _save(); }
  static Future<void> setInt(String k, int v) async { _data[k] = v; _save(); }
  static Future<void> setString(String k, String v) async { _data[k] = v; _save(); }
  static Future<void> remove(String k) async { _data.remove(k); _save(); }

  // cartella dove copiare il media custom
  static Directory mediaDir() {
    final dir = Directory('${_baseDir.path}\\media');
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return dir;
  }
}