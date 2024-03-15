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
    if (!ignoreLimitation && content.length > maxLogLength) {
      content = "${content.substring(0, maxLogLength)}...";
    }

    if (kDebugMode) {
      print(content);
    }

    var newLog = Log(level, title, content);

    if(newLog == _logs.last){
      return;
    }

    _logs.add(newLog);
    if (_logs.length > maxLogNumber) {
      _logs.remove(_logs.firstWhere((element) => element.level == LogLevel.info));
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
