import 'package:cella_lints/src/format.dart';
import 'package:html/dom.dart';

/// A linter rule defined in the Dart's API documentation
/// on https://dart.dev/tools/linter-rules or its mirrors.
class Option {
  const Option({
    required this.name,
    this.hasFix = false,
    this.status = Status.stable,
    this.sets = const {},
  });

  final String name;
  final bool hasFix;
  final Status status;
  final Set<Sets> sets;

  /// Parses the option from the following html structure:
  ///
  /// 1. There might be external children in the element which won't be checked.
  /// 2. The first child must be the name, and then followed by the status.
  /// 3. If the structure is invalid, it will return `null`.
  ///
  /// ```html
  /// <p>
  ///   <a href="/tools/linter-rules/name">
  ///     <code>name</code>
  ///   </a>
  ///   <em>(StatusName)</em>
  ///   <br>
  ///   <a href="/tools/linter-rules#set_name">
  ///     <img src="/assets/img/tools/linter/img-name.svg" alt="xxx">
  ///   </a>
  ///   <a href="/tools/linter-rules#set_name">
  ///     <img src="/assets/img/tools/linter/img-name.svg" alt="xxx">
  ///   </a>
  ///   <br>
  ///   The descriptions...
  /// </p>
  /// ```
  static Option? parse(Element element) {
    // Parse name.
    if (element.localName != 'p' || element.children.isEmpty) return null;
    final name = parseName(element.children.first);
    if (name == null) return null;
    if (element.children.length < 2) return Option(name: name);

    // Parse status.
    final second = element.children[1];
    final status = Status.parse(second);

    // Parse others.
    var hasFix = false;
    final setsHandler = <Sets>{};
    for (final child in element.children.sublist(2)) {
      if (!hasFix) hasFix = parseHasFix(child);
      final sets = Sets.parse(child);
      if (sets != null) setsHandler.add(sets);
    }
    return Option(
      name: name,
      hasFix: hasFix,
      status: status,
      sets: setsHandler,
    );
  }

  /// Parses the name of the option from the following html structure:
  ///
  /// 1. The element structure must be exactly the same.
  /// 2. It will only check the necessary attributes. The others are ignored.
  /// 3. All fields and inner text will be trimmed.
  /// 4. The name can be in any case, and the result will remain its case.
  /// 5. If it doesn't match the structure, it will return `null`.
  ///
  /// ```html
  /// <a href="/tools/linter-rules/name">
  ///   <code>name</code>
  /// </a>
  /// ```
  static String? parseName(Element element) {
    // Outer element and href.
    if (element.localName != 'a') return null;
    final href = element.attributes['href']?.trim();

    // Inner element.
    if (element.children.length != 1) return null;
    final code = element.children.first;
    if (code.localName != 'code') return null;

    // Check the name.
    final name = code.innerHtml.trim();
    return href == '/tools/linter-rules/$name' ? name : null;
  }

  /// Parses the status of the option from the following html structure:
  ///
  /// 1. The element structure must be exactly the same.
  /// 2. It will only check the necessary attributes. The others are ignored.
  /// 3. It won't check the "alt" attribute.
  /// 4. All fields and inner text will be trimmed.
  /// 5. If it doesn't match the structure, it will return `false`.
  ///
  /// ```html
  /// <a href="/tools/linter-rules#quick-fixes">
  ///   <img src="/assets/img/tools/linter/has-fix.svg" alt="Has a quick fix">
  /// </a>
  /// ```
  static bool parseHasFix(Element element) {
    const href = '/tools/linter-rules#quick-fixes';
    const src = '/assets/img/tools/linter/has-fix.svg';

    // Outer element, href and child number.
    if (element.localName != 'a' ||
        element.attributes['href']?.trim() != href ||
        element.children.length != 1) {
      return false;
    }

    // Inner element.
    final img = element.children.first;
    return img.localName == 'img' && img.attributes['src']?.trim() == src;
  }

  @override
  bool operator ==(Object other) =>
      other is Option &&
      other.name == name &&
      other.hasFix == hasFix &&
      other.status == status &&
      other.sets.length == sets.length &&
      other.sets.containsAll(sets);

  @override
  int get hashCode => Object.hashAll([name, hasFix, status, ...sets]);

  @override
  String toString() {
    final contents = [
      name,
      if (hasFix) 'fix',
      if (!status.isStable) status.name,
      for (final item in sets) item.name,
    ];
    return 'Option(${contents.join(', ')})';
  }
}

enum Status {
  stable('Stable'),
  experimental('Experimental'),
  deprecated('Deprecated'),
  removed('Removed'),
  unreleased('Unreleased');

  const Status(this.display);
  final String display;

  bool get isStable => this == Status.stable;

  /// Parses the status from the following html structure:
  ///
  /// 1. The element structure must be exactly the same.
  /// 2. It won't check the attributes.
  /// 3. There must be parenthesis.
  /// 4. The inner text will be trimmed.
  /// 5. If it doesn't match the structure, it will return [stable].
  ///
  /// ```html
  /// <em>(StatusName)</em>
  /// ```
  static Status parse(Element element) {
    // Check the element tag name.
    if (element.localName != 'em') return Status.stable;

    // Check whether there are parenthesis.
    final text = element.innerHtml.trim();
    if (!text.hasParenthesis) return Status.stable;

    // Check whether the status name matched.
    final bare = text.removeParenthesis.trim();
    for (final status in values.toSet()..remove(stable)) {
      if (status.display == bare) return status;
    }
    return Status.stable;
  }
}

enum Sets {
  core('lints', 'style-core'),
  recommended('lints', 'style-recommended'),
  flutter('flutter_lints', 'style-flutter');

  const Sets(this.setName, this.imgName);
  final String setName;
  final String imgName;

  /// Parses the sets from the following html structure:
  ///
  /// 1. The element structure must be exactly the same.
  /// 2. It will only check the necessary attributes. The others are ignored.
  /// 3. All fields will be trimmed.
  /// 4. If it doesn't match the structure, it will return `null`.
  ///
  /// ```html
  /// <a href="/tools/linter-rules#set_name">
  ///   <img src="/assets/img/tools/linter/img-name.svg" alt="xxx">
  /// </a>
  /// ```
  static Sets? parse(Element element) {
    // Outer element and href.
    if (element.localName != 'a') return null;
    final href = element.attributes['href']?.trim();

    // Inner element.
    if (element.children.length != 1) return null;
    final img = element.children.first;
    if (img.localName != 'img') return null;
    final src = img.attributes['src']?.trim();

    for (final value in Sets.values) {
      if (href == '/tools/linter-rules#${value.setName}' &&
          src == '/assets/img/tools/linter/${value.imgName}.svg') {
        return value;
      }
    }
    return null;
  }
}
