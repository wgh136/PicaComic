import 'package:flutter/foundation.dart';
import 'package:pica_comic/tools/extensions.dart';

void log(String content,
    [String title = "debug", LogLevel level = LogLevel.info]) {
  LogManager.addLog(level, title, content);
}

class LogManager {
  static final List<Log> _logs = <Log>[];

  static List<Log> get logs => _logs;

  static const maxLogLength = 3000;

  static const maxLogNumber = 500;

  static bool ignoreLimitation = false;

  static void printWarning(String text) {
    print('\x1B[33m$text\x1B[0m');
  }

  static void printError(String text) {
    print('\x1B[31m$text\x1B[0m');
  }

  static void addLog(LogLevel level, String title, String content) {
    if (!ignoreLimitation && content.length > maxLogLength) {
      content = "${content.substring(0, maxLogLength)}...";
    }

    if (kDebugMode) {
      switch (level) {
        case LogLevel.error:
          printError("$title: $content");
        case LogLevel.warning:
          printWarning("$title: $content");
        case LogLevel.info:
          print("$title: $content");
      }
    }

    var newLog = Log(level, title, content);

    if (newLog == _logs.lastOrNull) {
      return;
    }

    _logs.add(newLog);
    if (_logs.length > maxLogNumber) {
      var res = _logs.remove(
          _logs.firstWhereOrNull((element) => element.level == LogLevel.info));
      if (!res) {
        _logs.removeAt(0);
      }
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

class Log {
  final LogLevel level;
  final String title;
  final String content;
  final DateTime time = DateTime.now();

  @override
  toString() => "${level.name} $title $time \n$content\n\n";

  Log(this.level, this.title, this.content);

  static void info(String title, String message) {
    LogManager.addLog(LogLevel.info, title, message);
  }

  static void warning(String title, String message) {
    LogManager.addLog(LogLevel.warning, title, message);
  }

  static void error(String title, String message) {
    LogManager.addLog(LogLevel.error, title, message);
  }
}

enum LogLevel { error, warning, info }
