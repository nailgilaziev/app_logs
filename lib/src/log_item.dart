import 'package:app_logs/app_logs.dart';

import 'logger_levels.dart';
import 'utils.dart';

class LogItem {
  DateTime createTime;
  LoggerLevel level;
  String tag;
  String? functionName;
  String? functionArguments;
  String message;
  String? payload;
  StackTrace? stackTrace;

  LogItem(this.createTime, this.level, this.tag, this.functionName,
      this.functionArguments, this.message, this.payload, this.stackTrace);

  String exportToString({
    bool showPayload = true,
    bool showFunctionArguments = true,
    int functionInfoMaxLength = 64,
  }) {
    String d2s(int d) => d < 10 ? '0$d' : d.toString();
    final n = createTime;
    final ms = d2s(n.millisecond).toString().substring(0, 2);
    final time = AppLogger.showTimeInLogs
        ? '${d2s(n.hour)}:${d2s(n.minute)}:${d2s(n.second)}.$ms'
        : '';
    final l = level.toString().split('.')[1];
    final p = showPayload ? payload?.toString() : null;
    final fa = showFunctionArguments ? functionArguments : null;
    final fn = functionName == null ? null : '.$functionName';
    final fInfo = fn == null ? '' : '$fn${fa == null ? '()' : '($fa)'} ';
    final f = truncateFromCenter(fInfo, functionInfoMaxLength);
    return '$time $l/$tag  $f$message${p == null ? '' : ': $p'}'
        .replaceAll('\n', ' ↵ ');
  }

  @override
  String toString() {
    return exportToString();
  }
}
