import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:spok/data/sources/platform_files_source.dart';

/// Клон Fission-AI/OpenSpec как третья проверочная спека: у него живой
/// `openspec/` с десятками change'ей, архивом и спецификациями.
///
/// Клон ищется по `OPENSPEC_UPSTREAM_DIR`, иначе в `~/OpenSpec`; нет ни того,
/// ни другого — тест пропускается, а не падает: в CI клона нет, и это
/// нормально. Числа привязаны к коммиту db23097 (v1.13.2); при обновлении
/// клона их пересчитывают осознанно, а не подгоняют.
void main() {
  Directory? locateClone() {
    final candidates = [
      ?Platform.environment['OPENSPEC_UPSTREAM_DIR'],
      if (Platform.environment['HOME'] case final home?)
        p.join(home, 'OpenSpec'),
    ];
    for (final candidate in candidates) {
      if (Directory(p.join(candidate, 'openspec', 'changes')).existsSync()) {
        return Directory(candidate);
      }
    }
    return null;
  }

  test('клон upstream читается целиком: change\'и, архив, спецификации', () {
    final clone = locateClone();
    if (clone == null) {
      markTestSkipped(
        'клон Fission-AI/OpenSpec не найден: задайте OPENSPEC_UPSTREAM_DIR '
        'или положите его в ~/OpenSpec',
      );
      return;
    }
    final source = PlatformFilesSource(clone);

    // Чтение не падает — главное, что проверяется на чужой спеке.
    final changes = source.loadChanges();
    final archived = source.loadArchivedChanges();
    final specs = Directory(p.join(clone.path, 'openspec', 'specs'))
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => p.basename(file.path) == 'spec.md')
        .length;

    expect(changes.length, 27, reason: 'change\'ей в работе на db23097');
    expect(archived.length, greaterThanOrEqualTo(5));
    expect(specs, greaterThanOrEqualTo(30));
    expect(changes.map((change) => change.id), contains('spec-diffs'));
  });
}
