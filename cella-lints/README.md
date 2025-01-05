# Cella Lints

Shared linter options and the tool to sync from the Docs.

1. `dart.yaml` and `flutter.yaml` template for `analysis_options.yaml`.
2. Tools to sync data from the API docs at: https://dart.dev/tools/linter-rules.
3. Some basic formatter and colorizers, by the way.

## How to use

Introduce the template into your `analysis_options.yaml` file like this:

```yaml
# For Dart options.
include: package:cella_lints/dart.yaml
```

```yaml
# For Flutter options.
include: package:cella_lints/flutter.yaml
```
