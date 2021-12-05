import 'dart:collection';

import 'log_item.dart';
import 'logger_levels.dart';
import 'utils.dart';

abstract class Logger {
  Logger.forTag(this._tag);

  final String _tag;

  String? _localFunction;
  String? _localFunctionArguments;

  /// Получить локальную копию логгера для использования внутри функции
  /// Приписывает префикс с именем функции перед выводом тела сообщения
  AppLogger localLogger(Function localFunction, [Object? callArguments]) {
    final logger = AppLogger._(_tag, true);
    var s = localFunction.toString();
    s = s.substring(s.indexOf("'") + 1);
    s = s.substring(0, s.indexOf("'"));
    if (s.contains('@')) {
      s = s.substring(0, s.indexOf("@"));
    }
    logger._localFunction = s;
    logger._localFunctionArguments = callArguments.toString();
    return logger;
  }

  void v(String msg, [Object payload]);

  void i(String msg, [Object payload]);

  void w(String msg, [Object payload]);

  void e(String msg, [Object payload]);

  void s(String msg, [Object payload]);
}

///*
/// По задумке логгером можно будет управлять с сервера (какие теги/уровни активировать, trunc on/off)
/// Включать трансляцию логов на сервер онлайн в одну из сущностей
/// Выкачивать логи с девайса по запросу в том числе
/// Необходимости отправлять логи по почте/мессенджеру должно быть не много
/// последние 2 пункта обязывают хранить логи в файловой системе, но содержимое не должно быть plain text
/// чтобы нельзя было просто так без усилий реверс инжинирить приложение
///*/

// TODO(n): (^ look above) save logs to a secured place on device in a secured way to protect from rooted devices abd sending logs in a secured way (pub sd tmp dir + encryption / internal storage + encryption + rotation)
class AppLogger extends Logger {
  factory AppLogger.noTag() {
    return AppLogger.forTag('');
  }

  factory AppLogger.forType(Type type, {bool enabled = true}) {
    return AppLogger.forTag(type.toString(), enabled: enabled);
  }

  /// Если логгера еще в списке нет (его уровни еще никто не преднастраивал)
  /// то аргумент [enabled] настроит инициальное состояние для всех уровней
  /// если до использования логгера уровни настроили или после, [enabled] не будет мешать
  factory AppLogger.forTag(String tag, {bool enabled = true}) {
    if (_tagsLength == null) initTagsLength(kDefaultTagLength);
    final configuredLength = _tagsLength!;
    String t;
    if (configuredLength < 6) {
      t = 'L';
    } else if (tag.length < configuredLength) {
      t = tag.padLeft(configuredLength);
    } else {
      t = truncateFromCenter(tag, configuredLength);
    }
    final l = _shared.putIfAbsent(t, () => AppLogger._(t, enabled));
    return l;
  }

  AppLogger._(String tag, bool levelsState)
      : _activenessOfLevels =
            List.filled(LoggerLevel.values.length, levelsState),
        super.forTag(tag);

  static const kDefaultTagLength = 24;
  static int? _tagsLength;

  static void initTagsLength(int length) {
    if (_tagsLength != null) {
      // ignore: avoid_print
      print('AppLogger.initTagsLength can be called only once.'
          ' tagsLength=$_tagsLength');
    } else {
      _tagsLength = length;
    }
  }

  static final Map<String, AppLogger> _shared = {};

  static Iterable<AppLogger> get allLoggers => _shared.values;

  static final DoubleLinkedQueue<LogItem> _lru = DoubleLinkedQueue();

  static Iterable<String> items() {
    return _lru.map((e) => e.toString()).toList().reversed;
  }

  /// Switch to on only in debug mode, for safety reasons
  /// import 'package:flutter/foundation.dart';
  /// AppLogger.printToConsole = !kReleaseMode;
  static bool printToConsole = false;

  /// msg and payloads are truncated if exceed this value. 0 means no truncating applied
  static int truncateLength = 360;

  String? _truncate(String? s) {
    return s == null || s.length < truncateLength
        ? s
        : '${s.substring(0, truncateLength)}<...>';
  }

  List<bool> _activenessOfLevels;

  /// Можно для всех логгеров [allLoggers] (или части логгеров) включить или выключить определенные уровни
  /// Для более точечного конфигурирования каждого логгера или группы можно вызывать эту функцию несколько раз для разных логгеров
  /// А для точечной настройки каждого логгера использовать функцию [.configureLevels()] для каждого логгера по отдельности
  static void configureLoggersWithEqualLevels({
    required Iterable<AppLogger> loggers,
    List<LoggerLevel>? enable,
    List<LoggerLevel>? disable,
  }) {
    for (final logger in loggers) {
      logger.configureLevels(
        enable: enable,
        disable: disable,
      );
    }
  }

  /// Настройка уровней для конкретного логгера
  void configureLevels({
    List<LoggerLevel>? enable,
    List<LoggerLevel>? disable,
  }) {
    // ignore: avoid_function_literals_in_foreach_calls
    enable?.forEach((e) {
      _activenessOfLevels[e.index] = true;
    });
    // ignore: avoid_function_literals_in_foreach_calls
    disable?.forEach((e) {
      _activenessOfLevels[e.index] = false;
    });
  }

  @override
  void v(String msg, [Object? payload]) {
    toLruAndConsole(LoggerLevel.vrb, msg, payload);
  }

  @override
  void i(String msg, [Object? payload]) {
    toLruAndConsole(LoggerLevel.inf, msg, payload);
  }

  @override
  void s(String msg, [Object? payload]) {
    toLruAndConsole(LoggerLevel.sig, msg, payload);
  }

  @override
  void w(String msg, [Object? payload]) {
    toLruAndConsole(LoggerLevel.wrn, msg, payload);
  }

  @override
  void e(String msg, [Object? payload]) {
    toLruAndConsole(LoggerLevel.err, msg, payload);
  }

  void vBuild([String? msg, Object? payload]) {
    v('.build() ${msg ?? ''}', payload);
  }

  void vConstructor([String? msg, Object? payload]) {
    v('.constructor() ${msg ?? ''}', payload);
  }

  void vInitState([String? msg, Object? payload]) {
    v('.initState() ${msg ?? ''}', payload);
  }

  void toLruAndConsole(LoggerLevel level, String msg, [Object? payload]) {
    if (!_activenessOfLevels[level.index]) return;
    final log = LogItem(
      level,
      _tag,
      _localFunction,
      _localFunctionArguments,
      _truncate(msg)!,
      _truncate(payload.toString()),
    );
    if (_lru.length > 5000) _lru.removeFirst();
    _lru.add(log);
    // ignore: avoid_print
    if (printToConsole) print(log.toString());
  }
}
