// Regenerates assets/whats_new.json from CHANGELOG.md (English only).
//
//   dart run tool/sync_whats_new.dart [--release 0.1.8] [--date 2026-10-23]
//
// Optional banner summary, inside the version section (invisible on GitHub):
//   <!-- summary: Playlist search and a customizable player bar. -->
// Versions only in the JSON (written before release) are kept.
// --release/--date set the date of the version being released.

import 'dart:convert';
import 'dart:io';

class ChangelogRelease {
  ChangelogRelease(this.version);
  final String version;
  final Map<String, List<String>> groups = {'added': [], 'changed': [], 'fixed': []};
  String? summary;
}

final _header = RegExp(r'^Release Sona V(\d+\.\d+\.\d+)\s*$');
final _group = RegExp(r'^###\s*(Added|Changed|Fixed)\b', caseSensitive: false);
final _item = RegExp(r'^\s*[*-]\s+(.*)$');
final _comment = RegExp(r'<!--.*?-->');
final _summary = RegExp(r'^\s*<!--\s*summary(?:-en)?:\s*(.*?)\s*-->\s*$');

/// Releases in the CHANGELOG, in file order.
List<ChangelogRelease> parseChangelog(String md) {
  final out = <ChangelogRelease>[];
  ChangelogRelease? cur;
  String? group;
  for (final raw in const LineSplitter().convert(md.replaceFirst('﻿', ''))) {
    final line = raw.trimRight();
    final h = _header.firstMatch(line.trim());
    if (h != null) {
      out.add(cur = ChangelogRelease(h.group(1)!));
      group = null;
      continue;
    }
    if (cur == null) continue;
    final s = _summary.firstMatch(line);
    if (s != null) {
      if (s.group(1)!.isNotEmpty) cur.summary = s.group(1);
      continue;
    }
    final g = _group.firstMatch(line);
    if (g != null) {
      group = g.group(1)!.toLowerCase();
      continue;
    }
    final m = _item.firstMatch(line);
    if (m == null || group == null) continue;

    var text = m.group(1)!
        .replaceAll(_comment, '')
        .replaceFirst(RegExp(r'^\\?-\s*'), '') // "* \- text" bullets
        .replaceAll(RegExp(r'\s*\(#(\d+|N)\)'), '') // issue references
        // commit prefixes ("feat: ...", "fix(ui): ...")
        .replaceFirst(RegExp(r'^(feat|fix|refactor|perf|chore|docs|style)(\([^)]*\))?:\s*'), '')
        .trim();
    if (text.isEmpty || RegExp(r'^[-–]+$').hasMatch(text)) continue; // empty bullet
    text = text[0].toUpperCase() + text.substring(1);
    cur.groups[group]!.add(text);
  }
  return out;
}

int compareVersions(String a, String b) {
  List<int> p(String v) => v.split('.').map((x) => int.tryParse(x) ?? 0).toList();
  final x = p(a), y = p(b);
  for (var i = 0; i < 3; i++) {
    final d = x[i] - y[i];
    if (d != 0) return d.sign;
  }
  return 0;
}

/// Merges the CHANGELOG into the existing JSON, keeping dates and summaries.
Map<String, dynamic> merge(
  List<ChangelogRelease> changelog,
  Map<String, dynamic> existing, {
  String? release,
  String? date,
}) {
  final old = <String, Map<String, dynamic>>{
    for (final r in (existing['releases'] as List? ?? const []).whereType<Map>())
      '${r['version']}': r.cast<String, dynamic>(),
  };

  final releases = <Map<String, dynamic>>[];
  final seen = <String>{};
  for (final c in changelog) {
    if (!seen.add(c.version)) continue; // duplicate version: first wins
    final prev = old[c.version];
    final oldSummary = prev?['summary'];
    final summary = c.summary ??
        (oldSummary is Map ? oldSummary['en'] as String? : oldSummary as String?);
    final d = c.version == release ? (date ?? prev?['date']) : prev?['date'];

    releases.add({
      'version': c.version,
      'date': ?d,
      'summary': ?summary,
      for (final g in ['added', 'changed', 'fixed'])
        if (c.groups[g]!.isNotEmpty) g: c.groups[g],
    });
  }
  // Notes written in the JSON for a version not in the CHANGELOG yet.
  for (final e in old.entries) {
    if (!seen.contains(e.key)) releases.add(e.value);
  }
  releases.sort((a, b) => compareVersions('${b['version']}', '${a['version']}'));
  return {'releases': releases};
}

void main(List<String> args) {
  String? opt(String name) {
    final i = args.indexOf(name);
    return i >= 0 && i + 1 < args.length ? args[i + 1] : null;
  }

  final changelog = File('CHANGELOG.md');
  final jsonFile = File('assets/whats_new.json');
  if (!changelog.existsSync()) {
    stderr.writeln('CHANGELOG.md non trovato (avvia lo script dalla cartella del progetto)');
    exit(1);
  }
  final existing = jsonFile.existsSync()
      ? jsonDecode(jsonFile.readAsStringSync().replaceFirst('﻿', '')) as Map<String, dynamic>
      : <String, dynamic>{};

  final out = merge(
    parseChangelog(changelog.readAsStringSync()),
    existing,
    release: opt('--release'),
    date: opt('--date'),
  );
  jsonFile.writeAsStringSync('${const JsonEncoder.withIndent('  ').convert(out)}\n');
  stdout.writeln('assets/whats_new.json aggiornato: ${(out['releases'] as List).length} versioni');
}
