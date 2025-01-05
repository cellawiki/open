import 'dart:async';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:cella_eco/cella_eco.dart';
import 'package:path/path.dart';

Future<void> main(List<String> arguments) async {
  final command = CommandRunner<void>(
    'cella-eco',
    'Monorepo helpers including syncing contributors and testing.',
  )..addCommand(TestCommand());
  return command.run(arguments);
}

class TestCommand extends Command<void> {
  @override
  final String name = 'test';

  @override
  final String description = 'Test all child repos inside current monorepo.';

  @override
  Future<void> run() async => testMonorepo(dirname(Platform.script.path));
}
