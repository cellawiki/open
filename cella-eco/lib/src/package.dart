import 'dart:io';

import 'package:cella_lints/cella_lints.dart';
import 'package:path/path.dart';
import 'package:yaml/yaml.dart';
import 'package:yaml_edit/yaml_edit.dart';

/// The license file name satisfy pub.dev specifications.
const licenseFilename = 'LICENSE';

/// The recommended contributors filename.
const contributorsFilename = 'CONTRIBUTORS.yaml';

/// Sync package manifest files including the license file,
/// the contributors file, and the .pubignore file to unignore them,
/// because the aut-generated files are supposed to be ignored by Git,
/// and they are supposed to be uploaded onto the pub.dev registry.
///
/// 1. You must specify the [root] path, the folder of current path.
/// 2. You can specify the [monorepo] path, and if unspecified,
/// it will use the folder outside the [root] path.
/// 3. You can also specify the [licenseFilename] and [contributorsFilename].
void syncManifest({
  required String root,
  String? monorepo,
  String licenseFilename = licenseFilename,
  String contributorsFilename = contributorsFilename,
  bool log = true,
}) {
  final counter = TimeCounter.now();
  final monorepoRoot = monorepo ?? dirname(root);
  if (log) {
    final moveInfo = PathMove.from(monorepoRoot, root).format((r) => r.blue);
    stdout.writeln('${'sync manifest'.blue}${':'.dim} ${moveInfo}');
  }

  copyLicense(
    root: root,
    monorepo: monorepoRoot,
    licenseFilename: licenseFilename,
    log: log,
  );
  syncContributors(
    root: root,
    monorepo: monorepoRoot,
    contributorsFilename: contributorsFilename,
    log: log,
  );
  generatePubignore(
    root: root,
    licenseFilename: licenseFilename,
    contributorsFilename: contributorsFilename,
    log: log,
  );

  if (!log) return;
  counter.logDuration(message: 'done');
}

/// Copy the license file from the [monorepo] to the [root].
///
/// 1. [root]: path to the folder where current "pubspec.yaml" locates.
/// 2. [monorepo]: path to the folder where monorepo's "pubspec.yaml" locates.
/// 3. The [licenseFilename] must be specified, such as "LICENSE.txt".
/// "LICENSE" is the the specified license file name of the pub.dev ecosystem.
void copyLicense({
  required String root,
  required String monorepo,
  String licenseFilename = licenseFilename,
  bool log = true,
}) {
  final pathFrom = join(monorepo, licenseFilename);
  final pathTo = join(root, licenseFilename);
  File(pathFrom).copySync(pathTo);

  if (!log) return;
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
  bool log = true,
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

  if (!log) return;
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
  bool log = true,
}) {
  final content = [
    contributorsFilename.toLowerCase(),
    licenseFilename.toLowerCase(),
  ].map((item) => '!$item').join('\n');
  final pubignorePath = join(root, '.pubignore');
  File(pubignorePath).writeAsStringSync('$content\n');

  if (!log) return;
  stdout.writeln(
    '${'pub ignore generated'.green.dim} '
    '${pubignorePath.formatPath(style: (raw) => raw.blue)}',
  );
}

const manifestFilename = 'pubspec.yaml';

/// Detect what child repos are defined in the monorepo's "pubspec.yaml".
Iterable<String> detectWorkspace(String monorepo) {
  final file = File(join(monorepo, manifestFilename));
  final manifest = loadYaml(file.readAsStringSync());
  if (manifest is! YamlMap) throw Exception('invalid manifest: $manifest');
  final workspace = manifest['workspace'];
  if (workspace is! YamlList) throw Exception('invalid workspace: $workspace');
  return [for (final repo in workspace) repo.toString()];
}
