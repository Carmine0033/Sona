typedef LocalizedText = Map<String, String>;

/// Text in the user's language, else English, else whatever is there.
String pickLang(LocalizedText t, String lang) =>
    t[lang] ?? t['en'] ?? (t.values.isEmpty ? '' : t.values.first);

/// Compares "x.y.z" versions (ignoring "+build"): > 0 if [a] is newer.
int compareVersions(String a, String b) {
  List<int> parts(String v) =>
      v.split('+').first.split('.').map((p) => int.tryParse(p) ?? 0).toList();
  final x = parts(a), y = parts(b);
  for (var i = 0; i < 3; i++) {
    final d = (i < x.length ? x[i] : 0) - (i < y.length ? y[i] : 0);
    if (d != 0) return d.sign;
  }
  return 0;
}

class ReleaseNotes {
  const ReleaseNotes({
    required this.version,
    this.date,
    this.summary = const {},
    this.added = const [],
    this.changed = const [],
    this.fixed = const [],
  });

  final String version;
  final DateTime? date;
  final LocalizedText summary;
  final List<LocalizedText> added, changed, fixed;

  static ReleaseNotes? tryParse(Map<String, dynamic> j) {
    try {
      // {"it": …, "en": …} or a plain string (taken as English).
      LocalizedText text(Object? o) => o is Map
          ? o.map((k, v) => MapEntry('$k', '$v'))
          : o is String
              ? {'en': o}
              : const {};
      List<LocalizedText> list(Object? o) =>
          o is List ? o.map(text).where((m) => m.isNotEmpty).toList() : const [];

      return ReleaseNotes(
        version: j['version'] as String,
        date: DateTime.tryParse('${j['date']}'),
        summary: text(j['summary']),
        added: list(j['added']),
        changed: list(j['changed']),
        fixed: list(j['fixed']),
      );
    } catch (_) {
      return null; // one malformed entry must not hide the others
    }
  }
}