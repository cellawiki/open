import 'dart:convert';
import 'dart:io';

import 'package:cella_eco/cella_eco.dart';
import 'package:cella_lints/cella_lints.dart';
import 'package:path/path.dart';

/// Test all child repos inside the [monorepo].
/// This function is designed for faster execution
/// that all testings are executed concurrently.
/// But attention that the reported path is related to the child repo,
/// that it's inconvenient to trace errors.
/// When testing for development propose rather than validate,
/// it's more recommended to call the command in specified child repo.
Future<void> testMonorepo(String monorepo, {bool log = true}) async {
  await Future.wait(
    detectWorkspace(monorepo).map((repo) {
      final root = join(monorepo, repo);
      return runCommand('dart', ['test'], workingDirectory: root, log: log);
    }),
  );
}

/// Encapsulation of running a [command] with [arguments],
/// and redirect its output to stdout and stderr.
Future<void> runCommand(
  String command,
  List<String> arguments, {
  String? workingDirectory,
  bool log = true,
}) async {
  if (log) stdout.writeln('${'test in'.blue} ${(workingDirectory ?? '.').dim}');
  (await Process.start(command, arguments, workingDirectory: workingDirectory))
    ..stdout.transform(utf8.decoder).listen(stdout.write)
    ..stderr.transform(utf8.decoder).listen(stderr.write);
}
