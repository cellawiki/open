import 'package:cella_lints/cella_lints.dart';
import 'package:html/dom.dart';
import 'package:test/test.dart';

void main() {
  // The case of name won't be changed.
  const names = ['name', 'snake_case', 'camelCase'];

  group('parse name', () {
    test('normal', () {
      for (final name in names) {
        final element = Element.tag('a')
          ..attributes['href'] = '/tools/linter-rules/$name'
          ..children.add(Element.tag('code')..text = name);
        expect(Option.parseName(element), name);
      }
    });

    test('spaces', () {
      for (final name in names) {
        final element = Element.tag('a')
          ..attributes['href'] = ' /tools/linter-rules/$name '
          ..children.add(Element.tag('code')..text = ' $name ');
        expect(Option.parseName(element), name);
      }
    });

    test('more attributes', () {
      for (final name in names) {
        final code = Element.tag('code')
          ..attributes['inner-attribute'] = 'example'
          ..text = ' $name ';
        final element = Element.tag('a')
          ..attributes['href'] = ' /tools/linter-rules/$name '
          ..attributes['another'] = 'example'
          ..children.add(code);
        expect(Option.parseName(element), name);
      }
    });

    test('invalid outer element', () {
      for (final name in names) {
        final element = Element.tag('span')
          ..attributes['href'] = '/tools/linter-rules/$name'
          ..children.add(Element.tag('code')..text = name);
        expect(Option.parseName(element), isNull);
      }
    });

    test('invalid inner element', () {
      for (final name in names) {
        final element = Element.tag('a')
          ..attributes['href'] = '/tools/linter-rules/$name'
          ..children.add(Element.tag('span')..text = name);
        expect(Option.parseName(element), isNull);
      }
    });

    test('more children', () {
      for (final name in names) {
        final element = Element.tag('a')
          ..attributes['href'] = '/tools/linter-rules/$name'
          ..children.add(Element.tag('code')..text = name)
          ..children.add(Element.tag('code')..text = name);
        expect(Option.parseName(element), isNull);
      }
    });
  });

  group('parse status', () {
    test('normal', () {
      for (final status in Status.values.toSet()..remove(Status.stable)) {
        final element = Element.tag('em')..text = '(${status.display})';
        expect(Status.parse(element), status);
      }
    });

    test('spaces', () {
      for (final status in Status.values.toSet()..remove(Status.stable)) {
        final element = Element.tag('em')..text = ' ( ${status.display} ) ';
        expect(Status.parse(element), status);
      }
    });

    test('no parenthesis', () {
      for (final status in Status.values.toSet()..remove(Status.stable)) {
        final element = Element.tag('em')..text = status.display;
        expect(Status.parse(element), Status.stable);
      }
    });

    test('invalid text', () {
      final element = Element.tag('em')..text = '(invalid)';
      expect(Status.parse(element), Status.stable);
    });

    test('invalid element', () {
      for (final status in Status.values.toSet()..remove(Status.stable)) {
        final element = Element.tag('code')..text = '(${status.display})';
        expect(Status.parse(element), Status.stable);
      }
    });
  });

  group('parse has fix', () {
    test('normal', () {
      final img = Element.tag('img')
        ..attributes['src'] = '/assets/img/tools/linter/has-fix.svg';
      final element = Element.tag('a')
        ..attributes['href'] = '/tools/linter-rules#quick-fixes'
        ..children.add(img);
      expect(Option.parseHasFix(element), isTrue);
    });

    test('spaces', () {
      final img = Element.tag('img')
        ..attributes['src'] = ' /assets/img/tools/linter/has-fix.svg ';
      final element = Element.tag('a')
        ..attributes['href'] = ' /tools/linter-rules#quick-fixes '
        ..children.add(img);
      expect(Option.parseHasFix(element), isTrue);
    });

    test('more attributes', () {
      final img = Element.tag('img')
        ..attributes['src'] = ' /assets/img/tools/linter/has-fix.svg '
        ..attributes['another'] = 'example';
      final element = Element.tag('a')
        ..attributes['href'] = ' /tools/linter-rules#quick-fixes '
        ..attributes['alt'] = 'example'
        ..children.add(img);
      expect(Option.parseHasFix(element), isTrue);
    });

    test('invalid outer element', () {
      final img = Element.tag('img')
        ..attributes['src'] = '/assets/img/tools/linter/has-fix.svg';
      final element = Element.tag('span')
        ..attributes['href'] = '/tools/linter-rules#quick-fixes'
        ..children.add(img);
      expect(Option.parseHasFix(element), isFalse);
    });

    test('invalid inner element', () {
      final img = Element.tag('code')
        ..attributes['src'] = '/assets/img/tools/linter/has-fix.svg';
      final element = Element.tag('a')
        ..attributes['href'] = '/tools/linter-rules#quick-fixes'
        ..children.add(img);
      expect(Option.parseHasFix(element), isFalse);
    });

    test('more children', () {
      final img = Element.tag('img')
        ..attributes['src'] = '/assets/img/tools/linter/has-fix.svg';
      final element = Element.tag('a')
        ..attributes['href'] = '/tools/linter-rules#quick-fixes'
        ..children.add(img)
        ..children.add(Element.tag('img')..attributes['src'] = 'example');
      expect(Option.parseHasFix(element), isFalse);
    });
  });

  group('parse sets', () {
    test('normal', () {
      for (final value in Sets.values) {
        final img = Element.tag('img')
          ..attributes['src'] = '/assets/img/tools/linter/${value.imgName}.svg';
        final element = Element.tag('a')
          ..attributes['href'] = '/tools/linter-rules#${value.setName}'
          ..children.add(img);
        expect(Sets.parse(element), value);
      }
    });

    test('spaces', () {
      for (final value in Sets.values) {
        final img = Element.tag('img')
          ..attributes['src'] =
              ' /assets/img/tools/linter/${value.imgName}.svg ';
        final element = Element.tag('a')
          ..attributes['href'] = ' /tools/linter-rules#${value.setName} '
          ..children.add(img);
        expect(Sets.parse(element), value);
      }
    });

    test('more attributes', () {
      for (final value in Sets.values) {
        final img = Element.tag('img')
          ..attributes['src'] =
              ' /assets/img/tools/linter/${value.imgName}.svg '
          ..attributes['another'] = 'example';
        final element = Element.tag('a')
          ..attributes['href'] = ' /tools/linter-rules#${value.setName} '
          ..attributes['alt'] = 'example'
          ..children.add(img);
        expect(Sets.parse(element), value);
      }
    });

    test('more children', () {
      for (final value in Sets.values) {
        final img = Element.tag('img')
          ..attributes['src'] = '/assets/img/tools/linter/${value.imgName}.svg';
        final element = Element.tag('a')
          ..attributes['href'] = '/tools/linter-rules#${value.setName}'
          ..children.add(img)
          ..children.add(Element.tag('img')..attributes['src'] = 'example');
        expect(Sets.parse(element), isNull);
      }
    });

    test('invalid outer element', () {
      for (final value in Sets.values) {
        final img = Element.tag('img')
          ..attributes['src'] = '/assets/img/tools/linter/${value.imgName}.svg';
        final element = Element.tag('span')
          ..attributes['href'] = '/tools/linter-rules#${value.setName}'
          ..children.add(img);
        expect(Sets.parse(element), isNull);
      }
    });

    test('invalid inner element', () {
      for (final value in Sets.values) {
        final img = Element.tag('code')
          ..attributes['src'] = '/assets/img/tools/linter/${value.imgName}.svg';
        final element = Element.tag('a')
          ..attributes['href'] = '/tools/linter-rules#${value.setName}'
          ..children.add(img);
        expect(Sets.parse(element), isNull);
      }
    });
  });
}
