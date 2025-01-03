/// Why those formatters and colorizers exist?
///
/// Dart cannot support cycle import yet, so that
/// if the formatters and colorizers are reused from another package,
/// such package cannot import the linter templates inside this package.
library;

import 'dart:io';
import 'dart:math';

import 'package:cella_lints/cella_lints.dart';
import 'package:path/path.dart' as path;

class TimeCounter {
  const TimeCounter(this.start);
  factory TimeCounter.now() => TimeCounter(DateTime.now());

  final DateTime start;

  /// Formats the duration between the start and the current time.
  /// It will only show the milliseconds and seconds (if necessary).
  String formatDuration(DateTime now) {
    final duration = now.difference(start);
    final seconds = duration.inSeconds;
    final ms = duration.inMilliseconds.toString();
    if (seconds == 0) return '${ms.cyan} ${'ms'.dim}';
    return '${seconds.toString().cyan} ${'s'.dim} ${ms.cyan} ${'ms'.dim}';
  }

  /// Log the duration since the [start] time.
  void logDuration({String message = ''}) {
    final prefix = message.isEmpty ? '' : '${message.green} ';
    final time = formatDuration(DateTime.now());
    stdout.writeln('$prefix${'in'.dim} $time');
  }
}

extension FormatOptions on Option {
  /// Format the options into a colorized string.
  String get format {
    final contents = [
      if (hasFix) 'fix'.green,
      if (!status.isStable) formatStatus,
      ...sets.map((s) => s.name.hiBlue.dim),
    ];
    return '${sets.isEmpty ? name : name.dim}'
        '${contents.isEmpty ? '' : ':'.dim} '
        '${contents.join(' ')}';
  }

  /// Map [Status] into colors for better display on command-line.
  String get formatStatus {
    if (status == Status.removed) return status.name.red;
    if (status == Status.deprecated) return status.name.yellow;
    if (status == Status.experimental) return status.name.blue;
    return status.name.dim;
  }
}

extension CaseConvert on String {
  /// Capitalize a string:
  /// Uppercase the first one, and
  /// the case of other characters are unchanged.
  String get capital => isEmpty ? '' : this[0].toUpperCase() + substring(1);

  /// All the words in the raw string are separated by whitespaces.
  /// Capitalize all the words, and connect them with a dash.
  String get header => words.join('-');

  /// Split the raw string by whitespaces.
  /// Such whitespaces might be more than one.
  List<String> get words => split(whitespaceRegex);

  /// The regex to split the raw string by whitespaces.
  /// The continuous whitespaces might be more than one.
  static final whitespaceRegex = RegExp(r'\s+');
}

extension FormatBrackets on String {
  /// Detect whether the string has a pair of parenthesis.
  /// Attention that the raw string are supposed to be trimmed.
  bool get hasParenthesis => startsWith('(') && endsWith(')');

  /// Remove parenthesis if exist,
  /// ensure that there's no parenthesis between the string.
  /// Attention that the raw string are supposed to be trimmed.
  /// If there's whitespaces between the string, the inner parenthesis
  /// won't be removed.
  String get removeParenthesis {
    int start = 0;
    int end = length;
    if (startsWith('(')) start++;
    if (endsWith(')')) end--;
    return substring(start, end);
  }
}

typedef TerminalStyler = String Function(String raw);

extension FormatPath on String {
  /// Colorize the path, especially for command-line output.
  String formatPath({TerminalStyler? style}) {
    final dirname = path.dirname(this);
    final basename = path.basename(this);
    return '${dirname.isEmpty ? '' : '$dirname${path.separator}'.dim}'
        '${style == null ? basename : style(basename)}';
  }

  /// If the path is empty, return `.` instead.
  String get resolveEmpty => isEmpty ? '.' : this;
}

class PathMove {
  const PathMove({
    required this.common,
    this.from,
    this.to,
  });

  /// Parse the difference info between two path strings.
  factory PathMove.from(String from, String to) {
    final fromPath = from.split(path.separator);
    final toPath = to.split(path.separator);
    for (int i = 0; i < max(fromPath.length, toPath.length); i++) {
      if (fromPath[i] == toPath[i]) continue;
      final from = fromPath.sublist(i).join(path.separator);
      final to = toPath.sublist(i).join(path.separator);
      return PathMove(
        common: fromPath.sublist(0, i).join(path.separator).resolveEmpty,
        from: from.isEmpty ? null : from,
        to: to.isEmpty ? null : to,
      );
    }
    return PathMove(common: from.resolveEmpty);
  }

  final String common;
  final String? from;
  final String? to;

  String format(TerminalStyler? style) {
    if (from == to) return '${common.formatPath(style: style)} ${'(self)'.dim}';
    final a = from ?? '.';
    final b = to ?? '.';
    return '${'$common ('.dim}${a.formatPath(style: style)} ${'=>'.dim} '
        '${b.formatPath(style: style)}${')'.dim}';
  }
}

/// Color decoration on strings, as extensions.
extension Colors on String {
  // Font styles.
  String get dim => '\x1b[2m$this\x1b[22m';
  String get bold => '\x1b[1m$this\x1b[22m';
  String get italic => '\x1b[3m$this\x1b[23m';
  String get underline => '\x1b[4m$this\x1b[24m';
  String get strikethrough => '\x1b[9m$this\x1b[29m';

  // Foreground colors.
  String get red => '\x1b[31m$this\x1b[39m';
  String get green => '\x1b[32m$this\x1b[39m';
  String get yellow => '\x1b[33m$this\x1b[39m';
  String get blue => '\x1b[34m$this\x1b[39m';
  String get magenta => '\x1b[35m$this\x1b[39m';
  String get cyan => '\x1b[36m$this\x1b[39m';

  // Highlighted foreground colors.
  String get hiRed => '\x1b[91m$this\x1b[39m';
  String get hiGreen => '\x1b[92m$this\x1b[39m';
  String get hiYellow => '\x1b[93m$this\x1b[39m';
  String get hiBlue => '\x1b[94m$this\x1b[39m';
  String get hiMagenta => '\x1b[95m$this\x1b[39m';
  String get hiCyan => '\x1b[96m$this\x1b[39m';
}
