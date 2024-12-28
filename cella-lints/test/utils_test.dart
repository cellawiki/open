import 'package:cella_lints/src/utils.dart';
import 'package:test/test.dart';

void main() {
  group('remove parenthesis', () {
    test('normal', () => expect('(demo)'.removeParenthesis, 'demo'));
    test('inner space', () => expect('( demo )'.removeParenthesis, ' demo '));
    test('outer space', () => expect(' (demo) '.removeParenthesis, ' (demo) '));
  });
}
