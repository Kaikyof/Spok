import '../entities/slash_command.dart';

/// Команда передачи со подставленными аргументами.
///
/// Раньше строка была зашита — `/opsx-sprint <группа> handover`. Это
/// команда avtoto: у спеки без неё экран показывал предпросмотр и кнопку,
/// которая запустила бы то, чего в спеке нет. Собираем из сигнатуры самой
/// команды: слот группы получает её id, слот с вариантом `handover` —
/// само слово, флаг стека — выбранный стек.
///
/// Чего в сигнатуре нет, того и в команде не будет: угадывать аргументы
/// чужой спеки нельзя.
class BuildHandoverCommand {
  const BuildHandoverCommand();

  /// [stack] пустой — работа без разделения на стеки, флаг не добавляем.
  String call(SlashCommand command,
      {required String groupId, String stack = ''}) {
    final parts = [command.invocation];
    for (final slot in command.slots) {
      final flag = RegExp(r'^(--[a-z-]+)(?:\s+(.*))?$').firstMatch(slot);
      if (flag != null) {
        // Флаг стека — единственный, который мы умеем заполнить сами.
        final mentionsStack = '${flag.group(1)} ${flag.group(2) ?? ''}'
            .contains('stack');
        if (mentionsStack && stack.isNotEmpty) {
          parts.addAll([flag.group(1)!, stack]);
        }
        continue;
      }
      final options = [
        for (final option in slot.split('|')) option.trim(),
      ];
      if (options.contains('handover')) {
        parts.add('handover');
        continue;
      }
      if (options.any((option) =>
          const ['sprint', 'group', 'doc'].contains(option))) {
        parts.add(groupId);
      }
    }
    return parts.join(' ');
  }
}
