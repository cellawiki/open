import 'dart:io';

import 'package:cella_lints/cella_lints.dart';
import 'package:path/path.dart';
import 'package:yaml/yaml.dart';
import 'package:yaml_edit/yaml_edit.dart';

void main() {
  final counter = TimeCounter.now();

  final current = Platform.script.toFilePath();
  final root = dirname(current);
  final monorepo = dirname(root);
  final moveInfo = PathMove.from(monorepo, root).format((r) => r.blue);
  stdout.writeln('${'sync manifest'.blue}${':'.dim} $moveInfo');

  copyLicense(root: root, monorepo: monorepo);
  syncContributors(root: root, monorepo: monorepo);
  generatePubignore(root: root);

  counter.logDuration(message: 'done');
}

// Default names.
const licenseFilename = 'LICENSE';
const contributorsFilename = 'CONTRIBUTORS.yaml';

/// Copy the license file from the [monorepo] to the [root].
///
/// 1. [root]: path to the folder where current "pubspec.yaml" locates.
/// 2. [monorepo]: path to the folder where monorepo's "pubspec.yaml" locates.
/// 3. The [licenseFilename] can be specified, such as "LICENSE.txt".
/// "LICENSE" is the the specified license file name of the pub.dev ecosystem.
void copyLicense({
  required String root,
  required String monorepo,
  String licenseFilename = licenseFilename,
}) {
  final pathFrom = join(monorepo, licenseFilename);
  final pathTo = join(root, licenseFilename);
  File(pathFrom).copySync(pathTo);
  stdout.writeln(
    '${'license copied'.green.dim} '
    '${PathMove.from(pathFrom, pathTo).format((raw) => raw.magenta)}',
  );
}

/// Sync contributors' information from the specified file in the monorepo root
/// to the specified file in the root of current monorepo.
///
/// The contributors' file is defined in such format in yaml:
///
/// ```yaml
/// username:
///   name: Your Name
///   mail: your-email@example.com
///   repo:
///     - root
///     - cella-lints
/// ```
///
/// - `username`: your GitHub username, in lowercase ascii string.
/// - `name`: Your name(s), string or list.
/// - `mail`: Your email(s), string or list.
/// - `repo`: The child-repos you contributed to, string or list.
/// The child-repo names defined here are the folder name of such child-repo.
///
/// 1. [root]: path to the folder where current "pubspec.yaml" locates.
/// 2. [monorepo]: path to the folder where monorepo's "pubspec.yaml" locates.
/// 3. The [contributorsFilename] can be specified, such as "LICENSE.txt".
/// "LICENSE" is the the specified license file name of the pub.dev ecosystem.
void syncContributors({
  required String root,
  required String monorepo,
  String contributorsFilename = contributorsFilename,
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

/// Generate the pubignore file to unignore the auto generated files
/// ignored by Git, to introduce them into the published package.
///
/// 1. You need to specify the [root] path where the .pubignore file locates.
/// 2. Both the [licenseFilename] and the [contributorsFilename]
/// can be specified, the default values are recommended,
/// but you must ensure they're exactly [copyLicense] and [syncContributors]
/// used, or the auto generated files won't be ignored.
void generatePubignore({
  required String root,
  String licenseFilename = licenseFilename,
  String contributorsFilename = contributorsFilename,
}) {
  final content = [
    contributorsFilename.toLowerCase(),
    licenseFilename.toLowerCase(),
  ].map((item) => '!$item').join('\n');
  final pubignorePath = join(root, '.pubignore');
  File(pubignorePath).writeAsStringSync('$content\n');
  stdout.writeln(
    '${'pub ignore generated'.green.dim} '
    '${pubignorePath.formatPath(style: (raw) => raw.blue)}',
  );
}
