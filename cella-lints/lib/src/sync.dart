import 'dart:convert';
import 'dart:io';

import 'package:cella_lints/src/option.dart';
import 'package:html/dom.dart';
import 'package:http/http.dart' as http;
import 'package:yaml/yaml.dart';
import 'package:yaml_edit/yaml_edit.dart';

const site = 'https://dart.dev/tools/linter-rules';

/// Get the options from the [site]:
///
/// 1. The default site is 'https://dart.dev/tools/linter-rules'.
/// 2. You may also use a mirror site by providing the [site] parameter.
/// 3. All sites must have the same valid structure.
Future<Set<Option>> getOptions({String site = site}) async {
  final response = await http.get(Uri.parse(site));
  if (response.statusCode != 200) throw Exception('fail to load: $site');
  return parseOptions(Document.html(response.body));
}

/// Parse [Option]s from the given [document],
/// which is the HTML document get from a site of API documentations.
Set<Option> parseOptions(Document document) {
  const query = 'body > main#page-content > article > div.content';
  final root = document.querySelector(query);
  if (root == null) throw Exception('fail to parse: $query');

  final handler = <Option>{};
  for (final element in root.children) {
    final option = Option.parse(element);
    if (option != null) handler.add(option);
  }
  return handler;
}

/// Read options from a given "analysis_options.yaml" file
/// or other files with the same schema.
///
/// 1. It will return all configured linter rules options in a map.
/// 2. The rules in the file can be either a list or a map of bool values.
/// 3. If the yaml structure is invalid, it will throw an exception.
Map<String, bool> readOptions(File file, {Encoding encoding = utf8}) {
  // Read from file.
  final content = file.readAsStringSync(encoding: encoding);
  final document = loadYaml(content) as Map<String, dynamic>?;
  final rules = (document?['linter'] as Map<String, dynamic>?)?['rules'];
  if (rules == null) throw Exception('invalid file structure: $file');

  // Parse values.
  final handler = <String, bool>{};
  if (rules is YamlList) {
    for (final item in rules) {
      if (item is String) handler[item] = true;
    }
  } else if (rules is YamlMap) {
    for (final entry in rules.entries) {
      if (entry.key is String && entry.value is bool) {
        handler[entry.key as String] = entry.value as bool;
      }
    }
  }
  return handler;
}

const recommendedOverrides = {
  '': true,
};

extension ProcessOptions on Iterable<Option> {
  /// Process and get what rules should be enabled in the final output
  /// according to the given parameters.
  Map<String, bool?> filter({
    bool core = true,
    bool flutter = true,
    bool recommended = true,
    bool experimental = true,
    bool deprecated = false,
    bool removed = false,
    Map<String, bool?> overrides = const {},
  }) {
    final handler = <String, bool?>{};
    for (final option in this) {
      if (!core && option.sets.contains(Sets.core) ||
          !flutter && option.sets.contains(Sets.flutter) ||
          !recommended && option.sets.contains(Sets.recommended) ||
          !experimental && option.status == Status.experimental ||
          !deprecated && option.status == Status.deprecated ||
          !removed && option.status == Status.removed ||
          option.status == Status.unreleased) {
        continue;
      }
      handler[option.name] = true;
    }
    for (final name in overrides.keys) {
      if (overrides[name] == null) {
        handler.remove(name);
      } else {
        handler[name] = overrides[name];
      }
    }
    return handler;
  }
}

extension ApplyOptions on Map<String, bool?> {
  /// Apply the given options to a given "analysis_options.yaml" file.
  /// All the rules will be overridden, while all other fields remain.
  void apply(File file, {Encoding encoding = utf8}) {
    final content = file.readAsStringSync(encoding: encoding);
    final editor = YamlEditor(content)..update(['linter', 'rules'], this);
    file.writeAsStringSync(editor.toString(), encoding: encoding);
  }
}
