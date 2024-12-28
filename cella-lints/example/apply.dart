import 'dart:io';

import 'package:cella_lints/cella_lints.dart';
import 'package:path/path.dart';

const options = {
  'always_put_control_body_on_new_line': null, // Might make code ugly.
  'always_specify_types': null, // Might make code complex.
  'always_use_package_imports': null, // Might make code ugly.
  'avoid_equals_and_hash_code_on_mutable_classes': null, // Flutter only.
  'prefer_double_quotes': null, // Conflict: prefer_single_quotes.
  'prefer_expression_function_bodies': null, // Might make code ugly.
  'prefer_final_parameters': null, // Conflict: avoid_final_parameters.
  'prefer_relative_imports': null, // Might make code ugly.
  'public_member_api_docs': null, // Might make code complex.
  'omit_local_variable_types': null, // Might make code ugly.
  'specify_nonobvious_local_variable_types': null, // Might make code complex.
  'unnecessary_final': null, // Conflict: prefer_final_locals.
};

Future<void> main() async {
  final current = Platform.script.toFilePath();
  final root = dirname(dirname(current));
  final file = File(join(root, 'lib', 'dart.yaml'));

  (await getOptions()).filter(overrides: options).apply(file);
}
