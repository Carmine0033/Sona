import 'package:flutter/painting.dart';

const _accents = {
  'à': 'a', 'á': 'a', 'â': 'a', 'ä': 'a', 'ã': 'a', 'å': 'a',
  'è': 'e', 'é': 'e', 'ê': 'e', 'ë': 'e',
  'ì': 'i', 'í': 'i', 'î': 'i', 'ï': 'i',
  'ò': 'o', 'ó': 'o', 'ô': 'o', 'ö': 'o', 'õ': 'o',
  'ù': 'u', 'ú': 'u', 'û': 'u', 'ü': 'u',
  'ñ': 'n', 'ç': 'c',
};

String normalizeSearch(String s) {
  final b = StringBuffer();
  for (final ch in s.toLowerCase().split('')) {
    b.write(_accents[ch] ?? ch);
  }
  return b.toString();
}

TextSpan highlightMatch(String text, String query, TextStyle base, TextStyle match) {
  final nt= normalizeSearch(text);
  final nq= normalizeSearch(query.trim());

  final i= (nq.isEmpty || nt.length != text.length) ?-1 : nt.indexOf(nq);
  if(i<0) return TextSpan(text: text, style: base);
  return TextSpan(style: base, children: [
    TextSpan(text: text.substring(0, i)),
    TextSpan(text: text.substring(i, i + nq.length), style: match),
    TextSpan(text: text.substring(i + nq.length)),
  ]);
}