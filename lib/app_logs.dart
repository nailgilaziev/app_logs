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

enum _Level {
  VRB, // verbose
  INF, // informational
  SIG, // significant / success
  WRN, // warning
  ERR, // error
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
  factory AppLogger.forTag(String tag) {
    if (_tagsLength == null) initTagsLength(DEFAULT_TAG_LENGTH);
    assert(tag.length == _tagsLength, 'logger tag[$tag] length must be $_tagsLength');
    final t = tag.toUpperCase();
    final l = _shared.putIfAbsent(t, () => AppLogger._(t));
    return l;
  }

  AppLogger._(String tag)
      : activenessOfLevels = List.filled(_Level.values.length, true),
        super.forTag(tag);

  static const DEFAULT_TAG_LENGTH = 4;
  static int? _tagsLength;

  static void initTagsLength(int length) {
    if (_tagsLength != null)
      print(
          'AppLogger.initTagsLength can be called only once. tagsLength=$_tagsLength');
    else
      _tagsLength = length;
  }

  static final Map<String, AppLogger> _shared = {};

  static final DoubleLinkedQueue<String> _lru = DoubleLinkedQueue();

  static Iterable<String> items() {
    return _lru.toList().reversed;
  }

  /// Switch to on only in debug mode, for safety reasons
  static var printToConsole = false;

  /// msg and payloads are truncated if exceed this value. 0 means no truncating applied
  static var truncateLength = 360;

  List<bool> activenessOfLevels;

  @override
  void v(String msg, [Object? payload]) {
    toLruAndConsole(_Level.VRB, msg, payload);
  }

  @override
  void i(String msg, [Object? payload]) {
    toLruAndConsole(_Level.INF, msg, payload);
  }

  @override
  void s(String msg, [Object? payload]) {
    toLruAndConsole(_Level.SIG, msg, payload);
  }

  @override
  void w(String msg, [Object? payload]) {
    toLruAndConsole(_Level.WRN, msg, payload);
  }

  @override
  void e(String msg, [Object? payload]) {
    toLruAndConsole(_Level.ERR, msg, payload);
  }

  void toLruAndConsole(_Level level, String msg, [Object? payload]) {
    if (!activenessOfLevels[level.index]) return;
    final s = _s(level, msg, payload);
    if (_lru.length > 5000) _lru.removeFirst();
    _lru.add(s.replaceAll('\n', ' ↵ '));
    if (printToConsole) print(s);
  }

  String _s(_Level level, String msg, Object? payload) {
    String d2s(int d) => d < 10 ? '0$d' : d.toString();
    String? trunc(String? s) => s == null || s.length < truncateLength
        ? s
        : s.substring(0, truncateLength) + '<...>';
    final n = DateTime.now();
    final ms = d2s(n.millisecond).toString().substring(0, 2);
    final time = '${d2s(n.hour)}:${d2s(n.minute)}:${d2s(n.second)}.$ms';
    final l = level.toString().split('.')[1];
    final p = trunc(payload?.toString());
    return '$time $_tag/$l  ${trunc(msg)}${p == null ? '' : ': ' + p}';
  }
}
