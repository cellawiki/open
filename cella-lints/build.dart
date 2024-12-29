import 'dart:io';

import 'package:path/path.dart';
import 'package:yaml/yaml.dart';
import 'package:yaml_edit/yaml_edit.dart';

void main() {
  final current = Platform.script.toFilePath();
  final root = dirname(current);
  final monorepo = dirname(root);

  // Copy license file into current child repo.
  final licenseFilename = 'license'.toUpperCase();
  File(join(monorepo, licenseFilename)).copySync(join(root, licenseFilename));

  // Sync contributors into current child repo.
  final repoName = basename(root);
  final contributorsFilename = '${'contributors'.toUpperCase()}.yaml';
  final path = join(monorepo, contributorsFilename);
  final raw = loadYaml(File(path).readAsStringSync());
  if (raw is! Map) throw Exception('invalid structure: $path');
  final handler = <String, dynamic>{};
  for (final username in raw.keys) {
    // Copy contributor of such repo only.
    if (username is! String) continue;
    final contributor = raw[username];
    if (contributor is! Map) continue;
    final repos = contributor['repo'];
    if (repos is! List<dynamic>) continue;
    if (repos.contains(repoName)) {
      handler[username] = {...contributor}..remove('repo');
    }
  }
  final editor = YamlEditor('')..update([], handler);
  File(join(root, contributorsFilename)).writeAsStringSync('$editor\n');

  // Auto generate .pubignore.
  final content = [
    contributorsFilename.toLowerCase(),
    licenseFilename.toLowerCase(),
    'build.dart',
  ].map((item) => '!$item').join('\n');
  File(join(root, '.pubignore')).writeAsStringSync('$content\n');
}
