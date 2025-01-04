import 'dart:io';

import 'package:cella_eco/cella_eco.dart';
import 'package:path/path.dart';

void main() => syncManifest(root: dirname(Platform.script.toFilePath()));
