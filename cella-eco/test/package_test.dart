import 'dart:io';

import 'package:cella_eco/cella_eco.dart';
import 'package:path/path.dart';
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';
import 'package:yaml_edit/yaml_edit.dart';

const licenseContent = 'license content';
const workspaceRepos = ['child-repo-1', 'child-repo-2'];
const otherRepos = 'other-repos';
const username1 = 'username1';
const username2 = 'username2';
const username3 = 'username3';
const name = 'name';
const mail = 'mail';
const repo = 'repo';
const contributors = {
  username1: {
    name: 'name1',
    mail: 'mail1@example.com',
    repo: [...workspaceRepos, 'another'],
  },
  username2: {
    name: ['name2', 'Name2'],
    mail: ['mail2@example.com', 'mail2@example.dev'],
    repo: [...workspaceRepos, 'another'],
  },
  username3: {
    name: 'name3',
    mail: 'mail3@example.com',
    repo: 'another',
  },
};

void main() {
  // Such folder is not between the script, but inside a temp folder outside.
  final root = join(dirname(Platform.script.path), 'workspace');
  Directory(root).createSync(recursive: true);
  File(join(root, licenseFilename)).writeAsStringSync(licenseContent);
  File(join(root, contributorsFilename)).writeAsStringSync(contributors.yaml);
  final manifest = {
    'name': 'monorepo',
    'version': '0.0.0',
    'publish_to': 'none',
    'environment': {'sdk': '^3.6.0'},
    'workspace': [...workspaceRepos, otherRepos],
  }.yaml;
  File(join(root, manifestFilename)).writeAsStringSync(manifest);

  test('copy license', () {
    for (final name in workspaceRepos) {
      final path = join(root, name);
      Directory(path).createSync(recursive: true);
      copyLicense(root: path, monorepo: root, log: false);
      final file = File(join(path, licenseFilename));
      expect(file.readAsStringSync(), licenseContent);
      file.deleteSync();
    }
  });

  test('sync contributors', () {
    for (final childRepo in workspaceRepos) {
      final path = join(root, childRepo);
      Directory(path).createSync(recursive: true);
      syncContributors(root: path, monorepo: root, log: false);
      final file = File(join(path, contributorsFilename));
      final yaml = loadYaml(file.readAsStringSync()) as Map;
      expect((yaml[username1] as Map)[name], contributors[username1]?[name]);
      expect((yaml[username1] as Map)[mail], contributors[username1]?[mail]);
      expect((yaml[username1] as Map)[repo], null);
      expect((yaml[username2] as Map)[name], contributors[username2]?[name]);
      expect((yaml[username2] as Map)[mail], contributors[username2]?[mail]);
      expect((yaml[username2] as Map)[repo], null);
      expect(yaml[username3], isNull);
      file.deleteSync();
    }
  });

  test('detect workspace', () {
    final repos = detectWorkspace(root);
    expect([...repos], [...workspaceRepos, otherRepos]);
  });
}

extension AsYaml on Map<String, dynamic> {
  String get yaml => (YamlEditor('')..update([], this)).toString();
}
