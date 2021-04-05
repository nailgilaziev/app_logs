library app_logs;

import 'dart:collection';

abstract class Logger {
  Logger.forTag(this._tag);

  final String _tag;

  void v(String msg, [Object payload]);

  void i(String msg, [Object payload]);

  void w(String msg, [Object payload]);

  void e(String msg, [Object payload]);

  void s(String msg, [Object payload]);
}

enum LoggerLevel {
  vrb, // verbose
  inf, // informational
  sig, // significant / success
  wrn, // warning
  err, // error
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
  factory AppLogger.forTag(String tag, {bool enabled = true}) {
    if (_tagsLength == null) initTagsLength(kDefaultTagLength);
    final configuredLength = _tagsLength!;
    String t;
    if (configuredLength < 6) {
      t = 'L';
    } else if (tag.length > configuredLength) {
      final start = configuredLength ~/ 2;
      final shift = configuredLength.isEven ? 1 : 0;
      final end = tag.length - start + shift;
      t = tag.replaceRange(start, end, '…');
    } else if (tag.length < configuredLength) {
      t = tag.padLeft(configuredLength);
    } else {
      t = tag;
    }
    final l = _shared.putIfAbsent(t, () => AppLogger._(t, enabled));
    return l;
  }

  AppLogger._(String tag, bool levelsState)
      : _activenessOfLevels =
            List.filled(LoggerLevel.values.length, levelsState),
        super.forTag(tag);

  static const kDefaultTagLength = 20;
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

  static final DoubleLinkedQueue<String> _lru = DoubleLinkedQueue();

  static Iterable<String> items() {
    return _lru.toList().reversed;
  }

  /// Switch to on only in debug mode, for safety reasons
  /// import 'package:flutter/foundation.dart';
  /// AppLogger.printToConsole = !kReleaseMode;
  static bool printToConsole = false;

  /// msg and payloads are truncated if exceed this value. 0 means no truncating applied
  static int truncateLength = 360;

  List<bool> _activenessOfLevels;

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

  void toLruAndConsole(LoggerLevel level, String msg, [Object? payload]) {
    if (!_activenessOfLevels[level.index]) return;
    final s = _s(level, msg, payload);
    if (_lru.length > 5000) _lru.removeFirst();
    _lru.add(s.replaceAll('\n', ' ↵ '));
    // ignore: avoid_print
    if (printToConsole) print(s);
  }

  String _s(LoggerLevel level, String msg, Object? payload) {
    String d2s(int d) => d < 10 ? '0$d' : d.toString();
    String? trunc(String? s) => s == null || s.length < truncateLength
        ? s
        : s.substring(0, truncateLength) + '<...>';
    final n = DateTime.now();
    final ms = d2s(n.millisecond).toString().substring(0, 2);
    final time = '${d2s(n.hour)}:${d2s(n.minute)}:${d2s(n.second)}.$ms';
    final l = level.toString().split('.')[1];
    final p = trunc(payload?.toString());
    return '$time $l/$_tag  ${trunc(msg)}${p == null ? '' : ': ' + p}';
  }
}
