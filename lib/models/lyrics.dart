class LyricLine {
  final Duration time;
  final String text;
  const LyricLine(this.time, this.text);
}

List <LyricLine> parseLrc(String lrc) {
  final lines = <LyricLine>[];
  final reg = RegExp(r'\[(\d{1,2}):(\d{2})(?:[.:](\d{1,3}))?\]');

  for (final raw in lrc.split('\n')) {
    final matches = reg.allMatches(raw).toList();
    if (matches.isEmpty) continue;
    final text = raw.replaceAll(reg, '').trim();

    for (final m in matches) {
      final min = int.parse(m.group(1)!);
      final sec = int.parse(m.group(2)!);
      final frac = m.group(3);
      int ms = 0;
      if (frac != null) {
        ms = frac.length == 2
            ? int.parse(frac) * 10
            : int.parse(frac.padRight(3, '0').substring(0, 3));
      }
      lines.add(LyricLine(
          Duration(minutes: min, seconds: sec, milliseconds: ms), text));
    }
  }
  lines.sort((a, b) => a.time.compareTo(b.time));
  return lines;
}