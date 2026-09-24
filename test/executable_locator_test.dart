import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:spok/data/sources/executable_locator.dart';

void main() {
  group('Поиск утилит', () {
    test('находит node при урезанном PATH, как у .app из Finder', () {
      // Так выглядит PATH процесса, запущенного из Finder.
      final node = ExecutableLocator.locate('node');
      expect(node, isNotNull, reason: 'node должен быть найден на машине сборки');
      expect(File(node!).existsSync(), isTrue);
      expect(isAbsolutePath(node), isTrue);
    });

    test('для ненайденной утилиты resolve возвращает само имя', () {
      expect(ExecutableLocator.resolve('no-such-binary-xyz'),
          'no-such-binary-xyz');
    });
  });
}

bool isAbsolutePath(String path) => path.startsWith('/');
