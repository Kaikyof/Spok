import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../domain/entities/entities.dart';

/// Бейдж статуса Redmine: точка + текст. Цвет — по стадии.
class StatusBadge extends StatelessWidget {
  final String? status; // null — статус недоступен
  final String? prefix;
  const StatusBadge({super.key, required this.status, this.prefix});

  @override
  Widget build(BuildContext context) {
    final s = status;
    final color = s == null ? C.text3 : C.statusColor(s);
    final label = s ?? 'нет доступа';
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 6),
      Flexible(
        child: Text(
          prefix == null ? label : '$prefix · $label',
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: s == null ? C.text3 : C.text),
        ),
      ),
    ]);
  }
}

/// Индикатор отметок «10/11»: важна не доля, а какая задача не закрыта.
class MarksIndicator extends StatelessWidget {
  final StackState stack;
  final bool diverged;
  const MarksIndicator({super.key, required this.stack, this.diverged = false});

  @override
  Widget build(BuildContext context) {
    final open = stack.openTasks;
    final incomplete = open.isNotEmpty;
    final color = diverged || incomplete ? C.warn : C.text2;
    final marks = Text('${stack.doneCount}/${stack.tasks.length}',
        style: mono(12.5, color: color, weight: FontWeight.w500));
    if (!incomplete && !diverged) return marks;
    return Tooltip(
      message: incomplete
          ? 'не закрыто: ${open.map((t) => '${t.num} ${t.title}').join('\n')}'
          : 'есть расхождение',
      child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Row(mainAxisSize: MainAxisSize.min, children: [
          marks,
          if (diverged) ...const [
            SizedBox(width: 5),
            Icon(Icons.warning_amber_rounded, size: 14, color: C.warn),
          ],
        ]),
        if (incomplete)
          Text('открыта ${open.first.num}',
              style: const TextStyle(fontSize: 10.5, color: C.text3)),
      ]),
    );
  }
}

/// Карточка-секция в стиле макета.
class SectionCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final Color? color;
  final Color? borderColor;
  const SectionCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: padding,
        decoration: BoxDecoration(
          color: color ?? C.card,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: borderColor ?? C.borderSoft),
        ),
        child: child,
      );
}

/// Строка проверки окружения: точка состояния, имя, пояснение, результат.
class CheckRow extends StatelessWidget {
  final EnvCheck check;
  final bool monoName;
  const CheckRow({super.key, required this.check, this.monoName = true});

  @override
  Widget build(BuildContext context) {
    final color = switch (check.level) {
      CheckLevel.ok => C.ok,
      CheckLevel.warn => C.warn,
      CheckLevel.error => C.danger,
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(children: [
        Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 12),
        SizedBox(
          width: 280,
          child: Text(check.name,
              style: monoName
                  ? mono(12.5, color: C.text, weight: FontWeight.w500)
                  : const TextStyle(
                      fontSize: 12.5,
                      color: C.text,
                      fontWeight: FontWeight.w500)),
        ),
        Expanded(
          child: Text(check.detail,
              style: const TextStyle(fontSize: 12, color: C.text2)),
        ),
        Text(check.result,
            style: TextStyle(
                fontSize: 11.5,
                color: check.level == CheckLevel.ok ? C.text3 : color,
                fontWeight: check.level == CheckLevel.ok
                    ? FontWeight.w400
                    : FontWeight.w500)),
      ]),
    );
  }
}

/// Плашка следующего шага: одна на экран, с командой и причиной.
class NextStepBanner extends StatelessWidget {
  final String title;
  final String reason;
  final String command;
  const NextStepBanner(
      {super.key,
      required this.title,
      required this.reason,
      required this.command});

  @override
  Widget build(BuildContext context) => SectionCard(
        color: C.accentDim,
        borderColor: const Color(0xFF31456B),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        child: Row(children: [
          const Text('→',
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600, color: C.accent)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w500, color: C.text)),
              const SizedBox(height: 3),
              Text(reason,
                  style: const TextStyle(fontSize: 11.5, color: C.text2)),
            ]),
          ),
          const SizedBox(width: 16),
          SelectableText(command, style: mono(12)),
        ]),
      );
}
