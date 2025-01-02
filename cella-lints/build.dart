import 'dart:io';

import 'package:path/path.dart';
import 'package:yaml/yaml.dart';
import 'package:yaml_edit/yaml_edit.dart';

void main() {
  final current = Platform.script.toFilePath();
  final root = dirname(current);
  final monorepo = dirname(root);

  // Copy license file into current child repo.
  final license = 'license'.toUpperCase();
  File(join(monorepo, license)).copySync(join(root, license));

  // Sync contributors into current child repo.
  final name = basename(root);
  final contributors = '${'contributors'.toUpperCase()}.yaml';
  final path = join(monorepo, contributors);
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
  File(join(root, contributors)).writeAsStringSync('$editor\n');

  // Auto generate .pubignore.
  final content = [
    contributors.toLowerCase(),
    license.toLowerCase(),
  ].map((item) => '!$item').join('\n');
  File(join(root, '.pubignore')).writeAsStringSync('$content\n');
}
