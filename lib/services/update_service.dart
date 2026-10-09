import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:window_manager/window_manager.dart';

class UpdateInfo {
  final String version;
  final String pageUrl;
  final String? downloadUrl;
  const UpdateInfo(this.version, this.pageUrl, this.downloadUrl);
}

class UpdateService {
  static const _api =
      'https://api.github.com/repos/Carmine0033/Sona/releases/latest';
  static const _ua = 'Sona-Updater';

  static Future<UpdateInfo?> check() async {
    try {
      final res = await http.get(Uri.parse(_api), headers: {
        'Accept': 'application/vnd.github+json',
        'User-Agent': _ua,
      }).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return null;

      final json = jsonDecode(res.body) as Map<String, dynamic>;
      final tag = (json['tag_name'] as String).replaceFirst('v', '');
      final page = json['html_url'] as String;

      String? dl;
      for (final a in (json['assets'] as List? ?? [])) {
        final name = (a['name'] as String? ?? '').toLowerCase();
        if (name.endsWith('.exe')) {
          dl = a['browser_download_url'] as String?;
          break;
        }
      }

      final info = await PackageInfo.fromPlatform();
      if (_isNewer(tag, info.version)) return UpdateInfo(tag, page, dl);
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<void> downloadAndRun(String url,
      {void Function(double)? onProgress}) async {
    final client = http.Client();
    try {
      final req = http.Request('GET', Uri.parse(url))
        ..headers['User-Agent'] = _ua;
      final res = await client.send(req);
      final total = res.contentLength ?? 0;

      final file =
          File('${Directory.systemTemp.path}\\Sona-update-setup.exe');
      final sink = file.openWrite();
      int received = 0;
      await for (final chunk in res.stream) {
        sink.add(chunk);
        received += chunk.length;
        if (total > 0) onProgress?.call(received / total);
      }
      await sink.close();


      await Process.start(file.path, ['/SILENT'],
          mode: ProcessStartMode.detached);
      await windowManager.destroy();
      exit(0);
    } finally {
      client.close();
    }
  }

  static bool _isNewer(String remote, String local) {
    List<int> p(String v) =>
        v.split('.').map((e) => int.tryParse(e.trim()) ?? 0).toList();
    final r = p(remote), l = p(local);
    for (int i = 0; i < 3; i++) {
      final rv = i < r.length ? r[i] : 0;
      final lv = i < l.length ? l[i] : 0;
      if (rv != lv) return rv > lv;
    }
    return false;
  }
}