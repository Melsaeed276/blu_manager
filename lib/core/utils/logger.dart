import 'dart:developer' as dev;

/// Simple application logger to replace scattered print statements.
/// Uses dart:developer log so messages integrate with Observatory / IDE tools.
class AppLogger {
  AppLogger._();

  static const String _name = 'BluManager';

  static void debug(String message, {Object? error, StackTrace? stackTrace}) =>
      _log(message, level: LogLevel.debug, error: error, stackTrace: stackTrace);
  static void info(String message, {Object? error, StackTrace? stackTrace}) =>
      _log(message, level: LogLevel.info, error: error, stackTrace: stackTrace);
  static void warn(String message, {Object? error, StackTrace? stackTrace}) =>
      _log(message, level: LogLevel.warning, error: error, stackTrace: stackTrace);
  static void error(String message, {Object? error, StackTrace? stackTrace}) =>
      _log(message, level: LogLevel.error, error: error, stackTrace: stackTrace);

  static void _log(String message, {required LogLevel level, Object? error, StackTrace? stackTrace}) {
    // Numeric levels similar to logging package conventions
    final numericLevel = switch (level) {
      LogLevel.debug => 500,
      LogLevel.info => 800,
      LogLevel.warning => 900,
      LogLevel.error => 1000,
    };
    dev.log(message, name: _name, level: numericLevel, error: error, stackTrace: stackTrace);
  }
}

enum LogLevel { debug, info, warning, error }

