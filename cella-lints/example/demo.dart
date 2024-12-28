import 'dart:io';

import 'package:cella_lints/cella_lints.dart';

Future<void> main() async => (await getOptions()).forEach(stdout.writeln);
