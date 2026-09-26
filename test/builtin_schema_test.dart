import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spok/data/sources/builtin_schemas.dart';
import 'package:spok/data/sources/schema_resolver.dart';

/// Встроенная схема существует в двух видах: файл в assets (источник
/// правды, обновляется копированием из upstream) и константа для чистого
/// Dart. Тест не даёт им разойтись и проверяет, что asset объявлен.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('константа совпадает с файлом в assets', () {
    final file = File('assets/openspec/schemas/spec-driven/schema.yaml');
    expect(file.existsSync(), isTrue);
    expect(builtinSpecDrivenSchema, file.readAsStringSync());
  });

  test('asset объявлен в pubspec и читается через rootBundle', () async {
    final text = await rootBundle.loadString(
      'assets/openspec/schemas/spec-driven/schema.yaml',
    );
    expect(text, contains('name: spec-driven'));
    expect(text, contains(builtinSchemaUpstreamVersion));
  });

  test('встроенная spec-driven разбирается: четыре артефакта и tasks.md', () {
    final schema = SchemaResolver.parse(
      defaultSchemaName,
      builtinSpecDrivenSchema,
    );
    expect(schema.artifacts.map((artifact) => artifact.id), [
      'proposal',
      'specs',
      'design',
      'tasks',
    ]);
    expect(schema.tracksFile, 'tasks.md');
    expect(schema.stacks, isEmpty);
    // Ветку upstream не диктует — и мы её не выдумываем.
    expect(schema.branchTemplate, isNull);
    expect(schema.branchFor('x'), isNull);
  });
}
