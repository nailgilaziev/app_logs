import 'package:app_logs/app_logs.dart';
import 'package:flutter/material.dart';

class LogsViewer extends StatefulWidget {
  const LogsViewer({super.key});

  @override
  State<LogsViewer> createState() => _LogsViewerState();
}

class _LogsViewerState extends State<LogsViewer> {
  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}

void showLogsViewer(BuildContext context, String msg, [List<LogItem>? logs]) =>
    showDialog<String>(
        context: context,
        builder: (BuildContext context) {
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minWidth: 200,
                maxWidth: 800,
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Card(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: errorInfoWidget(
                          msg, logs?.reversed ?? [], context),
                    ),
                  ),
                ),
              ),
            ),
          );
        });

Column errorInfoWidget(String msg, Iterable<LogItem> logs,
    BuildContext context) {
  Color levelColor(String? l) {
    final darkMode = false;
    // MediaQuery.of(context).platformBrightness == Brightness.dark;
    switch (l) {
      case 'E':
        return darkMode ? Colors.red[400]! : Colors.red[700]!;
      case 'W':
        return darkMode ? Colors.orange[300]! : Colors.orange[800]!;
      case 'S':
        return darkMode ? Colors.green[300]! : Colors.green[800]!;
      case 'I':
        return darkMode ? Colors.white : Colors.black;
      default:
        return darkMode ? Colors.grey[400]! : Colors.grey[800]!;
    }
  }

  return Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Text(
          msg,
          textScaleFactor: 0.9,
          style: TextStyle(color: Colors.red[700]),
        ),
      ),
      ...logs.map(
            (l) =>
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: RichText(
                textAlign: TextAlign.left,
                text: TextSpan(
                  text: l.toString().substring(0, 22),
                  style: TextStyle(fontSize: 6, color: levelColor(null)),
                  children: [
                    TextSpan(
                      text: l.toString().substring(22, l
                          .toString()
                          .length),
                      style: TextStyle(
                        fontSize: 8,
                        color: levelColor(l.toString()[17]),
                      ),
                    )
                  ],
                ),
              ),
            ),
      ),
    ],
  );
}

