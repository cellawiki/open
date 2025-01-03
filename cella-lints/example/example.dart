import 'dart:io';

import 'package:cella_lints/cella_lints.dart';

Future<void> main() async {
  final counter = TimeCounter.now();
  stdout.writeln('${'parsing options from'.blue}${': $site'.dim}');
  (await getOptions()).map((option) => option.format).forEach(stdout.writeln);
  counter.logDuration(message: 'done');
}
