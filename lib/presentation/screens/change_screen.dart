import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:path/path.dart' as p;

import '../../core/theme.dart';
import '../../domain/entities/entities.dart';
import '../bloc/console_bloc.dart';
import '../widgets/common.dart';

/// Список change'ей → карточка change'а → просмотр документации.
class ChangeScreen extends StatelessWidget {
  const ChangeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ConsoleBloc>().state;
    if (state.selectedDoc != null) return const _DocViewer();
    if (state.selectedChange != null) {
      return _ChangeCard(change: state.selectedChange!);
    }
    return const _ChangeList();
  }
}

class _ChangeList extends StatelessWidget {
  const _ChangeList();

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<ConsoleBloc>();
    final changes = bloc.state.snapshot?.changes ?? [];
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        for (final c in changes)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: InkWell(
              onTap: () => bloc.add(ChangeOpened(c)),
              borderRadius: BorderRadius.circular(9),
              child: SectionCard(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(children: [
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(c.title,
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: C.text)),
                          const SizedBox(height: 3),
                          Text(c.id, style: mono(10.5, color: C.text3)),
                        ]),
                  ),
                  for (final s in c.stacks) ...[
                    SizedBox(
                        width: 210,
                        child: StatusBadge(
                            status: s.redmineStatus,
                            prefix: s.stack == 'ios' ? 'iOS' : 'Android')),
                    MarksIndicator(stack: s),
                    const SizedBox(width: 16),
                  ],
                ]),
              ),
            ),
          ),
      ],
    );
  }
}

class _ChangeCard extends StatelessWidget {
  final ChangeUnit change;
  const _ChangeCard({required this.change});

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<ConsoleBloc>();
    final artifacts = _artifacts(change);
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        InkWell(
          onTap: () => bloc.add(ChangeOpened(null)),
          child: const Text('← Ко всем change\'ам',
              style: TextStyle(fontSize: 12, color: C.text3)),
        ),
        const SizedBox(height: 10),
        Text(change.title,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600, color: C.text)),
        const SizedBox(height: 6),
        Row(children: [
          Text(change.id, style: mono(11.5, color: C.text3)),
          const SizedBox(width: 16),
          for (final s in change.stacks) ...[
            StatusBadge(
                status: s.redmineStatus,
                prefix: s.stack == 'ios' ? 'iOS' : 'Android'),
            const SizedBox(width: 20),
          ],
        ]),
        const SizedBox(height: 20),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            flex: 62,
            child: Column(children: [
              for (final s in change.stacks) ...[
                _TaskChecklist(stack: s),
                const SizedBox(height: 16),
              ],
            ]),
          ),
          const SizedBox(width: 20),
          Expanded(
            flex: 38,
            child: SectionCard(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Артефакты',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: C.text)),
                    const SizedBox(height: 8),
                    for (final a in artifacts)
                      _ArtifactRow(
                          artifact: a,
                          onOpen: a.exists
                              ? () => bloc.add(DocOpened(a))
                              : null),
                  ]),
            ),
          ),
        ]),
      ],
    );
  }

  List<DocArtifact> _artifacts(ChangeUnit c) => [
        for (final (label, file) in [
          ('Спека', 'proposal.md'),
          ('Дизайн-решения', 'design.md'),
          ('Задачи iOS', 'tasks_ios.md'),
          ('Задачи Android', 'tasks_android.md'),
        ])
          DocArtifact(label, file, p.join(c.dir, file),
              File(p.join(c.dir, file)).existsSync()),
      ];
}

class _ArtifactRow extends StatelessWidget {
  final DocArtifact artifact;
  final VoidCallback? onOpen;
  const _ArtifactRow({required this.artifact, this.onOpen});

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: Row(children: [
            Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                    color: artifact.exists ? C.ok : C.text3,
                    shape: BoxShape.circle)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(artifact.label,
                        style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: C.text)),
                    Text(artifact.fileName, style: mono(10.5, color: C.text3)),
                  ]),
            ),
            if (artifact.exists)
              const Icon(Icons.chevron_right, size: 16, color: C.text3),
          ]),
        ),
      );
}

class _TaskChecklist extends StatelessWidget {
  final StackState stack;
  const _TaskChecklist({required this.stack});

  @override
  Widget build(BuildContext context) {
    final open = stack.openTasks;
    return SectionCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Text('Задачи стека ${stack.stack == 'ios' ? 'iOS' : 'Android'}',
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600, color: C.text)),
          ),
          Text('${stack.doneCount} / ${stack.tasks.length}',
              style: mono(12.5,
                  color: open.isEmpty ? C.text2 : C.warn,
                  weight: FontWeight.w500)),
        ]),
        const SizedBox(height: 10),
        for (final t in stack.tasks)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: t.done
                ? null
                : BoxDecoration(
                    color: C.warnBg, borderRadius: BorderRadius.circular(6)),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(t.done ? Icons.check_box : Icons.check_box_outline_blank,
                  size: 15, color: t.done ? C.ok : C.warn),
              const SizedBox(width: 10),
              Text(t.num,
                  style: mono(12, color: t.done ? C.text3 : C.warn)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(t.title,
                    style: TextStyle(
                        fontSize: 12.5,
                        color: t.done ? C.text2 : C.text,
                        fontWeight:
                            t.done ? FontWeight.w400 : FontWeight.w500)),
              ),
              if (!t.done)
                const Text('блокирует передачу',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: C.warn)),
            ]),
          ),
      ]),
    );
  }
}

class _DocViewer extends StatelessWidget {
  const _DocViewer();

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<ConsoleBloc>();
    final state = bloc.state;
    final doc = state.selectedDoc!;
    return Column(children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Row(children: [
          InkWell(
            onTap: () => bloc.add(DocOpened(null)),
            child: Text('← ${state.selectedChange?.title ?? 'Назад'}',
                style: const TextStyle(fontSize: 12, color: C.text3)),
          ),
          const Spacer(),
          Text(doc.fileName, style: mono(11.5, color: C.text3)),
        ]),
      ),
      Expanded(
        child: Container(
          margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          decoration: BoxDecoration(
            color: C.card,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: C.borderSoft),
          ),
          child: Markdown(
            data: state.docContent ?? '',
            padding: const EdgeInsets.all(24),
            styleSheet: MarkdownStyleSheet(
              p: const TextStyle(fontSize: 13, color: C.text2, height: 1.5),
              h1: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w700, color: C.text),
              h2: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w600, color: C.text),
              h3: const TextStyle(
                  fontSize: 13.5, fontWeight: FontWeight.w600, color: C.text),
              code: mono(12, color: C.mono),
              codeblockDecoration: BoxDecoration(
                  color: C.logBg, borderRadius: BorderRadius.circular(7)),
              listBullet: const TextStyle(fontSize: 13, color: C.text2),
              blockquoteDecoration: BoxDecoration(
                  color: C.bg,
                  borderRadius: BorderRadius.circular(7),
                  border: const Border(
                      left: BorderSide(color: C.accent, width: 3))),
              tableBorder: TableBorder.all(color: C.borderSoft),
              tableBody: const TextStyle(fontSize: 12, color: C.text2),
            ),
          ),
        ),
      ),
    ]);
  }
}
