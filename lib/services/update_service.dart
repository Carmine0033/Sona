import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

class UpdateInfo {
  final String version;
  final String url;
  const UpdateInfo(this.version, this.url);
}

class UpdateService {
  static const _api =
      'https://api.github.com/repos/tuo-utente/sona/releases/latest';

  static Future<UpdateInfo?> check() async {
    try {
      final res = await http.get(Uri.parse(_api),
          headers: {'Accept': 'application/vnd.github+json'});
      if (res.statusCode != 200) return null;

      final json = jsonDecode(res.body) as Map<String, dynamic>;
      final tag = (json['tag_name'] as String).replaceFirst('v', ''); 
      final htmlUrl = json['html_url'] as String;

      final info = await PackageInfo.fromPlatform();
      final current = info.version; // da pubspec.yaml

      if (_isNewer(tag, current)) return UpdateInfo(tag, htmlUrl);
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Confronto semantico: true se `remote` > `local`.
  static bool _isNewer(String remote, String local) {
    List<int> parse(String v) =>
        v.split('.').map((e) => int.tryParse(e.trim()) ?? 0).toList();
    final r = parse(remote), l = parse(local);
    for (int i = 0; i < 3; i++) {
      final rv = i < r.length ? r[i] : 0;
      final lv = i < l.length ? l[i] : 0;
      if (rv != lv) return rv > lv;
    }
    return false;
  }
}