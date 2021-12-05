import 'logger_levels.dart';
import 'utils.dart';

class LogItem {
  LoggerLevel level;
  String tag;
  String? functionName;
  String? functionArguments;
  String message;
  String? payload;

  LogItem(this.level, this.tag, this.functionName, this.functionArguments,
      this.message, this.payload);

  String exportToString({
    bool showPayload = true,
    bool showFunctionArguments = true,
    int functionInfoMaxLength = 64,
  }) {
    String d2s(int d) => d < 10 ? '0$d' : d.toString();
    final n = DateTime.now();
    final ms = d2s(n.millisecond).toString().substring(0, 2);
    final time = '${d2s(n.hour)}:${d2s(n.minute)}:${d2s(n.second)}.$ms';
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
