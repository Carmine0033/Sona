import 'package:flutter/services.dart';

class SmtcChannel {
  static const _method = MethodChannel('sona/smtc');
  static const _events = EventChannel('sona/smtc/events');

  static Future<Map<String, dynamic>?> getCurrentMedia() async {
    return _method.invokeMapMethod<String, dynamic>('getCurrentMedia');
  }

  static Stream<Map<String, dynamic>?> get updates =>
      _events.receiveBroadcastStream().map((e) {
        if (e == null) return null;
        return (e as Map).cast<String, dynamic>();
      });
  

  //commands
  static Future<bool> playPause() async =>
      await _method.invokeMethod<bool>('playPause') ?? false;

  static Future<bool> next() async =>
      await _method.invokeMethod<bool>('next') ?? false;

  static Future<bool> previous() async =>
      await _method.invokeMethod<bool>('previous') ?? false;

  static Future<bool> seek(Duration position) async =>
      await _method.invokeMethod<bool>(
          'seek', {'positionMs': position.inMilliseconds}) ??
      false;
}