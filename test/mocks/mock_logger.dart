import 'package:preparatorio_concursos/core/utils/logger.dart';

class MockLogger implements Logger {
  int verboseCalls = 0;
  int debugCalls = 0;
  int infoCalls = 0;
  int warningCalls = 0;
  int errorCalls = 0;
  
  List<String> messages = [];
  List<String> tags = [];
  List<dynamic> errors = [];
  List<StackTrace?> stackTraces = [];

  @override
  void verbose(String message, {String? tag, Map<String, dynamic>? data}) {
    verboseCalls++;
    messages.add(message);
    if (tag != null) tags.add(tag);
  }

  @override
  void debug(String message, {String? tag, Map<String, dynamic>? data}) {
    debugCalls++;
    messages.add(message);
    if (tag != null) tags.add(tag);
  }

  @override
  void info(String message, {String? tag, Map<String, dynamic>? data}) {
    infoCalls++;
    messages.add(message);
    if (tag != null) tags.add(tag);
  }

  @override
  void warning(String message, {String? tag, dynamic error, StackTrace? stackTrace, Map<String, dynamic>? data}) {
    warningCalls++;
    messages.add(message);
    if (tag != null) tags.add(tag);
    if (error != null) errors.add(error);
    stackTraces.add(stackTrace);
  }

  @override
  void error(String message, {String? tag, dynamic error, StackTrace? stackTrace, Map<String, dynamic>? data}) {
    errorCalls++;
    messages.add(message);
    if (tag != null) tags.add(tag);
    if (error != null) errors.add(error);
    stackTraces.add(stackTrace);
  }

  @override
  void setLogLevel(LogLevel level) {
    // Não faz nada no mock
  }

  @override
  LogLevel get currentLogLevel => LogLevel.verbose;

  @override
  List<LogEntry> get recentLogs => [];

  @override
  Future<void> exportLogs({String? filePath}) async {
    // Não faz nada no mock
  }

  void reset() {
    verboseCalls = 0;
    debugCalls = 0;
    infoCalls = 0;
    warningCalls = 0;
    errorCalls = 0;
    messages.clear();
    tags.clear();
    errors.clear();
    stackTraces.clear();
  }
}
