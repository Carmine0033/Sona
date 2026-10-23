import 'dart:io';

const _allowedHosts = {
  'open.spotify.com', 'music.youtube.com', 'www.youtube.com',
  'music.apple.com', 'www.deezer.com',
  'github.com', // release notes (What's new)
};

Future<void> openExternal(String url) async {
  if (!Platform.isWindows) return;
  final uri = Uri.tryParse(url);
  final safe = uri != null &&
      (uri.scheme == 'spotify' ||
          (uri.scheme == 'https' && _allowedHosts.contains(uri.host)));
  if (!safe) return;
  await Process.start('explorer.exe', [uri.toString()]);
}