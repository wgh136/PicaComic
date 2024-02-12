import 'package:flutter/foundation.dart';

void log(String content, [String title = "debug", LogLevel level = LogLevel.info]){
  LogManager.addLog(level, title, content);
}

class LogManager {
  static final List<Log> _logs = <Log>[];

  static List<Log> get logs => _logs;

  static const maxLogLength = 3000;

  static const maxLogNumber = 400;

  static bool ignoreLimitation = false;

  static void addLog(LogLevel level, String title, String content) {
    if (kDebugMode) {
      print(content);
    }

    if (!ignoreLimitation && content.length > maxLogLength) {
      content = "${content.substring(0, maxLogLength)}...";
    }

    _logs.add(Log(level, title, content));
    if (_logs.length > maxLogNumber) {
      _logs.removeAt(0);
    }
  }

  static void clear() => _logs.clear();

  @override
  String toString() {
    var res = "Logs\n\n";
    for (var log in _logs) {
      res += log.toString();
    }
    return res;
  }
}

@immutable
class Log {
  final LogLevel level;
  final String title;
  final String content;
  final DateTime time = DateTime.now();

  @override
  toString() => "${level.name} $title $time \n$content\n\n";

  Log(this.level, this.title, this.content);
}

enum LogLevel { error, warning, info }
