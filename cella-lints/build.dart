import 'dart:io';

import 'package:cella_lints/cella_lints.dart';
import 'package:path/path.dart';
import 'package:yaml/yaml.dart';
import 'package:yaml_edit/yaml_edit.dart';

void main() {
  final counter = TimeCounter.now();

  // Get current repo and monorepo path.
  final current = Platform.script.toFilePath();
  final root = dirname(current);
  final monorepo = dirname(root);

  // Sync license and contributors.
  final license = 'license'.toUpperCase();
  final contributors = '${'contributors'.toUpperCase()}.yaml';
  copyLicense(root: root, monorepo: monorepo, licenseFilename: license);
  syncContributors(
    root: root,
    monorepo: monorepo,
    contributorsFilename: contributors,
  );

  // Auto generate .pubignore.
  final content = [
    contributors.toLowerCase(),
    license.toLowerCase(),
  ].map((item) => '!$item').join('\n');
  final pubignorePath = join(root, '.pubignore');
  File(pubignorePath).writeAsStringSync('$content\n');
  stdout.writeln(
    '${'pub ignore generated'.green.dim} '
    '${pubignorePath.formatPath(style: (raw) => raw.blue)}',
  );

  counter.logDuration(message: 'done');
}

void copyLicense({
  required String root,
  required String monorepo,
  required String licenseFilename,
}) {
  final pathFrom = join(monorepo, licenseFilename);
  final pathTo = join(root, licenseFilename);
  File(pathFrom).copySync(pathTo);
  stdout.writeln(
    '${'license copied'.green.dim} '
    '${PathMove.from(pathFrom, pathTo).format((raw) => raw.magenta)}',
  );
}

void syncContributors({
  required String root,
  required String monorepo,
  required String contributorsFilename,
}) {
  final name = basename(root);
  final path = join(monorepo, contributorsFilename);
  final raw = loadYaml(File(path).readAsStringSync());
  if (raw is! Map) throw Exception('invalid structure: $path');
  final handler = <String, dynamic>{};
  for (final username in raw.keys) {
    // Copy contributor of such repo only.
    if (username is! String) continue;
    final contributor = raw[username];
    if (contributor is! Map) continue;
    final repo = contributor['repo'];
    if (repo == name || (repo is List<dynamic> && repo.contains(name))) {
      handler[username] = {...contributor}..remove('repo');
    }
  }
  final editor = YamlEditor('')..update([], handler);
  final pathTo = join(root, contributorsFilename);
  File(pathTo).writeAsStringSync('$editor\n');
  stdout.writeln(
    '${'contributors synced'.green.dim} '
    '${PathMove.from(path, pathTo).format((raw) => raw.magenta)}',
  );
}
