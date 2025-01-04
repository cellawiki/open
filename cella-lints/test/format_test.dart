import 'package:cella_lints/cella_lints.dart';
import 'package:path/path.dart';
import 'package:test/test.dart';

void main() {
  group('remove parenthesis', () {
    test('normal', () => expect('(demo)'.removeParenthesis, 'demo'));
    test('inner space', () => expect('( demo )'.removeParenthesis, ' demo '));
    test('outer space', () => expect(' (demo) '.removeParenthesis, ' (demo) '));
  });

  group('path move parse', () {
    test('all common', () {
      final info = PathMove.from(
        ['common', 'path'].join(separator),
        ['common', 'path'].join(separator),
      );
      expect(info.common, ['common', 'path'].join(separator));
      expect(info.from, isNull);
      expect(info.to, isNull);
    });

    test('both diff', () {
      final info = PathMove.from(
        ['common', 'path', 'a', 'diff'].join(separator),
        ['common', 'path', 'b', 'diff'].join(separator),
      );
      expect(info.common, ['common', 'path'].join(separator));
      expect(info.from, ['a', 'diff'].join(separator));
      expect(info.to, ['b', 'diff'].join(separator));
    });

    test('from diff', () {
      final info = PathMove.from(
        ['common', 'path', 'a'].join(separator),
        ['common', 'path'].join(separator),
      );
      expect(info.common, ['common', 'path'].join(separator));
      expect(info.from, ['a'].join(separator));
      expect(info.to, null);
    });

    test('to diff', () {
      final info = PathMove.from(
        ['common', 'path'].join(separator),
        ['common', 'path', 'b'].join(separator),
      );
      expect(info.common, ['common', 'path'].join(separator));
      expect(info.from, null);
      expect(info.to, ['b'].join(separator));
    });
  });
}
