import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/theme.dart';
import '../../domain/entities/entities.dart';
import '../bloc/console_bloc.dart';
import '../widgets/common.dart';

/// Главный экран: за пять секунд показать, где спринт и что мешает.
class SprintScreen extends StatelessWidget {
  const SprintScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ConsoleBloc>().state;
    final snapshot = state.snapshot;
    if (snapshot == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (snapshot.changes.isEmpty) {
      return const Center(
        child: Text('Нет активного спринта.\nСоздайте его командой /opsx:doc.',
            textAlign: TextAlign.center,
            style: TextStyle(color: C.text2, fontSize: 13)),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        if (snapshot.redmineProblem != null) ...[
          _PartialErrorBar(problem: snapshot.redmineProblem!),
          const SizedBox(height: 16),
        ],
        if (snapshot.divergences.isNotEmpty) ...[
          _DivergenceBlock(divergences: snapshot.divergences),
          const SizedBox(height: 20),
        ],
        _ChangesTable(changes: snapshot.changes),
        const SizedBox(height: 20),
        ..._nextStep(snapshot.changes),
      ],
    );
  }

  /// Одна плашка на экран: самая частая незакрытая задача.
  List<Widget> _nextStep(List<ChangeUnit> changes) {
    final counts = <String, (TaskItem, int)>{};
    for (final c in changes) {
      for (final s in c.stacks) {
        for (final t in s.openTasks) {
          final cur = counts[t.num];
          counts[t.num] = (t, (cur?.$2 ?? 0) + 1);
        }
      }
    }
    if (counts.isEmpty) return const [];
    final top = counts.values.reduce((a, b) => a.$2 >= b.$2 ? a : b);
    return [
      NextStepBanner(
        title:
            'Следующий шаг: закрыть задачу ${top.$1.num} «${top.$1.title}» — открыта в ${top.$2} стеках',
        reason: 'иначе спринт не пройдёт проверку готовности при передаче',
        command: 'открыть tasks_*.md в change\'ах',
      ),
    ];
  }
}

class _PartialErrorBar extends StatelessWidget {
  final String problem;
  const _PartialErrorBar({required this.problem});

  @override
  Widget build(BuildContext context) => SectionCard(
        color: C.card,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(children: [
          const Icon(Icons.cloud_off, size: 15, color: C.text3),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
                'Статусы Redmine недоступны ($problem) — показаны данные файлов',
                style: const TextStyle(fontSize: 12, color: C.text2)),
          ),
        ]),
      );
}

class _DivergenceBlock extends StatelessWidget {
  final List<Divergence> divergences;
  const _DivergenceBlock({required this.divergences});

  @override
  Widget build(BuildContext context) => SectionCard(
        color: C.warnBg,
        borderColor: C.warnBorder,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.warning_amber_rounded, size: 17, color: C.warn),
            const SizedBox(width: 10),
            Text('Расхождения — ${divergences.length}',
                style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: C.warn)),
          ]),
          const SizedBox(height: 8),
          for (final d in divergences)
            Padding(
              padding: const EdgeInsets.only(left: 27, top: 4),
              child: Text(
                  '${d.changeTitle} — ${d.stack == 'ios' ? 'iOS' : 'Android'}: ${d.message}',
                  style: const TextStyle(fontSize: 13, color: C.text)),
            ),
        ]),
      );
}

class _ChangesTable extends StatelessWidget {
  final List<ChangeUnit> changes;
  const _ChangesTable({required this.changes});

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<ConsoleBloc>();
    final divergences = bloc.state.snapshot?.divergences ?? [];
    bool diverged(ChangeUnit c, String stack) =>
        divergences.any((d) => d.changeId == c.id && d.stack == stack);

    return SectionCard(
      padding: EdgeInsets.zero,
      child: Column(children: [
        Container(
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: C.borderSoft))),
          child: const Row(children: [
            Expanded(
                flex: 42,
                child: Text('CHANGE',
                    style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                        color: C.text3))),
            Expanded(
                flex: 29,
                child: Text('iOS',
                    style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: C.text2))),
            Expanded(
                flex: 29,
                child: Text('ANDROID',
                    style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                        color: C.text2))),
          ]),
        ),
        for (final (i, c) in changes.indexed)
          InkWell(
            onTap: () => bloc.add(ChangeOpened(c)),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                border: i == 0
                    ? null
                    : const Border(top: BorderSide(color: C.borderSoft)),
              ),
              child: Row(children: [
                Expanded(
                  flex: 42,
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: C.text)),
                        const SizedBox(height: 3),
                        Text(c.id, style: mono(10.5, color: C.text3)),
                      ]),
                ),
                for (final s in [c.ios, c.android])
                  Expanded(
                    flex: 29,
                    child: s == null
                        ? const Text('—',
                            style: TextStyle(color: C.text3, fontSize: 12))
                        : Row(children: [
                            Expanded(
                              child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    StatusBadge(status: s.redmineStatus),
                                    const SizedBox(height: 3),
                                    Text('#${s.issueId ?? '—'}',
                                        style: mono(10.5, color: C.text3)),
                                  ]),
                            ),
                            MarksIndicator(
                                stack: s, diverged: diverged(c, s.stack)),
                            const SizedBox(width: 8),
                          ]),
                  ),
              ]),
            ),
          ),
      ]),
    );
  }
}
