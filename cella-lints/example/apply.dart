import 'dart:io';

import 'package:cella_lints/cella_lints.dart';
import 'package:path/path.dart' as path;

Future<void> main() async {
  final counter = TimeCounter.now();

  final current = Platform.script.toFilePath();
  final root = path.dirname(path.dirname(current));
  final file = File(path.join(root, 'lib', 'dart.yaml'));

  stdout.writeln('${'updating into'.blue}${': ${file.path}'}'.dim);
  (await getOptions()).filter(overrides: recommendedOverrides).apply(file);
  counter.logDuration(message: 'done');
}
