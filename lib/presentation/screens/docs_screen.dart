import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../core/resources/app_colors.dart';
import '../../core/resources/app_dimens.dart';
import '../../core/resources/app_text_styles.dart';
import '../../domain/entities/doc_artifact.dart';
import '../../domain/entities/doc_node.dart';
import '../../domain/entities/doc_state.dart';
import '../../l10n/gen/app_localizations.dart';
import '../bloc/console_bloc.dart';
import '../localization/text_formatters.dart';
import '../ui_kit/doc_markdown.dart';

/// Экран «Документы»: дерево спеки слева, текст документа справа.
///
/// Дерево повторяет устройство спеки, а не выдумывает своё: группа (спринт
/// или мастер-спека одним файлом), её change'и, файлы артефактов схемы и
/// отдельный узел архива с датой сдачи.
class DocsScreen extends StatelessWidget {
  const DocsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConsoleBloc, ConsoleState>(
      builder: (context, state) {
        final tree = state.docTree;
        final hasDocs = tree.any((node) => node.declaredCount > 0);
        if (!hasDocs) return const _NoDocs();
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _DocTree(nodes: tree, state: state),
            const VerticalDivider(
                width: 1, thickness: 1, color: AppColors.borderSoft),
            Expanded(child: _DocPane(state: state)),
          ],
        );
      },
    );
  }
}

/// В спеке нет ни одного документа — объясняем, откуда они берутся,
/// а не показываем пустую рамку.
class _NoDocs extends StatelessWidget {
  const _NoDocs();

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(texts.docsEmpty,
                textAlign: TextAlign.center,
                style: AppTextStyles.sectionTitle),
            const SizedBox(height: AppDimens.gapS),
            Text(texts.docsEmptyHint,
                textAlign: TextAlign.center,
                style: AppTextStyles.captionMuted.copyWith(height: 1.5)),
          ],
        ),
      ),
    );
  }
}

class _DocTree extends StatelessWidget {
  final List<DocNode> nodes;
  final ConsoleState state;

  const _DocTree({required this.nodes, required this.state});

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);
    return Container(
      width: 304,
      color: AppColors.panel,
      child: ListView(
        padding: const EdgeInsets.symmetric(
            horizontal: AppDimens.gapS, vertical: AppDimens.gapM),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, AppDimens.gapS),
            child: Text(texts.docsTitle, style: AppTextStyles.sectionLabel),
          ),
          for (final node in nodes) ..._nodeRows(context, node, depth: 0),
        ],
      ),
    );
  }

  /// Узел и его содержимое одним плоским списком: дерево неглубокое
  /// (группа → change → файл), а ListView так остаётся ленивым.
  List<Widget> _nodeRows(BuildContext context, DocNode node,
      {required int depth}) {
    // Узел без единого объявленного файла ничего не даёт — не показываем.
    if (node.declaredCount == 0) return const [];
    final collapsed = state.collapsedDocNodes.contains(_nodeKey(node, depth));
    return [
      _NodeHeader(
        node: node,
        depth: depth,
        collapsed: collapsed,
        onTap: () => context
            .read<ConsoleBloc>()
            .add(DocsNodeToggled(_nodeKey(node, depth))),
      ),
      if (!collapsed) ...[
        for (final doc in node.docs)
          _DocRow(
            doc: doc,
            depth: depth + 1,
            selected: state.openedDoc?.path == doc.path,
          ),
        for (final child in node.children)
          ..._nodeRows(context, child, depth: depth + 1),
      ],
    ];
  }

  /// Ключ свёрнутости: id change'а не уникален между группой и архивом,
  /// поэтому в ключ входит и глубина узла.
  static String _nodeKey(DocNode node, int depth) => '$depth/${node.id}';
}

/// Строка дерева с подсветкой под курсором.
///
/// Подсветку рисуем сами, а не `InkWell`: чернила расходятся по ближайшему
/// `Material`, а он лежит за панелью дерева — эффекта не видно. Строку,
/// по которой нельзя кликнуть (файла нет), не подсвечиваем и курсор не
/// меняем: наведение не должно обещать того, чего не будет.
class _HoverRow extends StatefulWidget {
  final VoidCallback? onTap;
  final bool selected;
  final EdgeInsets padding;
  final EdgeInsets margin;
  final Widget child;

  const _HoverRow({
    required this.onTap,
    required this.child,
    this.selected = false,
    this.padding = EdgeInsets.zero,
    this.margin = EdgeInsets.zero,
  });

  @override
  State<_HoverRow> createState() => _HoverRowState();
}

class _HoverRowState extends State<_HoverRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final clickable = widget.onTap != null;
    final highlight = widget.selected
        ? AppColors.cardHighlight
        : (_hovered && clickable ? AppColors.card : null);
    return MouseRegion(
      cursor: clickable ? SystemMouseCursors.click : MouseCursor.defer,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          margin: widget.margin,
          padding: widget.padding,
          decoration: BoxDecoration(
            color: highlight,
            borderRadius: BorderRadius.circular(AppDimens.controlRadius),
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

class _NodeHeader extends StatelessWidget {
  final DocNode node;
  final int depth;
  final bool collapsed;
  final VoidCallback onTap;

  const _NodeHeader({
    required this.node,
    required this.depth,
    required this.collapsed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);
    final subtitle = _subtitle(texts);
    return _HoverRow(
      onTap: onTap,
      margin: const EdgeInsets.symmetric(vertical: 1),
      padding: EdgeInsets.fromLTRB(8 + depth * 14, 6, 8, 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(collapsed ? Icons.chevron_right : Icons.expand_more,
              size: 15, color: AppColors.textMuted),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _title(texts),
                  style: depth == 0
                      ? AppTextStyles.sectionTitle
                      : AppTextStyles.rowTitle.copyWith(fontSize: 12.5),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: AppTextStyles.monospace(10.5,
                          color: AppColors.textMuted)),
                ],
              ],
            ),
          ),
          const SizedBox(width: 6),
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Text(
              texts.docsTreeCount(node.presentCount, node.declaredCount),
              style: AppTextStyles.monospace(10.5, color: AppColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }

  String _title(AppLocalizations texts) => switch (node.kind) {
        DocNodeKind.archivedChange when node.children.isNotEmpty =>
          texts.docsArchiveTitle,
        DocNodeKind.group when node.title.isEmpty => texts.docsUngrouped,
        _ => node.title.isEmpty ? node.id : node.title,
      };

  /// Под заголовком — то, чем узел отличается: id, ветка или дата архива.
  /// Заголовком уже стал id (у change'а без спеки и задач другого имени
  /// нет) — не повторяем его второй строкой.
  String _subtitle(AppLocalizations texts) {
    final id = node.title == node.id ? '' : node.id;
    if (node.archivedAt case final archivedAt?) {
      final date =
          texts.docsArchivedAt(DateFormat('d MMMM y', 'ru').format(archivedAt));
      return id.isEmpty ? date : '$id · $date';
    }
    return switch (node.kind) {
      DocNodeKind.archivedChange when node.children.isNotEmpty => '',
      DocNodeKind.archivedChange =>
        id.isEmpty ? texts.docsArchivedNoDate : '$id · ${texts.docsArchivedNoDate}',
      DocNodeKind.change => id,
      DocNodeKind.group => node.branch,
    };
  }
}

class _DocRow extends StatelessWidget {
  final DocArtifact doc;
  final int depth;
  final bool selected;

  const _DocRow({
    required this.doc,
    required this.depth,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);
    // Объявленный схемой, но ещё не написанный файл остаётся в дереве:
    // так видно, что спеке полагается, а чего в ней нет.
    return _HoverRow(
      onTap: doc.exists
          ? () => context.read<ConsoleBloc>().add(DocsFileOpened(doc))
          : null,
      selected: selected,
      margin: const EdgeInsets.symmetric(vertical: 1),
      padding: EdgeInsets.fromLTRB(8 + depth * 14, 5, 8, 5),
      child: Row(
        children: [
          Icon(
            doc.exists ? Icons.description_outlined : Icons.remove,
            size: 14,
            color: doc.exists
                ? (selected ? AppColors.accent : AppColors.textMuted)
                : AppColors.textMuted,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  texts.docLabel(doc),
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    color: doc.exists
                        ? AppColors.textPrimary
                        : AppColors.textMuted,
                  ),
                ),
                if (!doc.exists) ...[
                  const SizedBox(height: 2),
                  Text(texts.artifactMissing, style: AppTextStyles.hint),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Правая половина: шапка документа и его текст.
class _DocPane extends StatelessWidget {
  final ConsoleState state;

  const _DocPane({required this.state});

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);
    final doc = state.openedDoc;
    if (doc == null) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(texts.docsNothingOpened,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.sectionTitle),
              const SizedBox(height: AppDimens.gapS),
              Text(texts.docsNothingOpenedHint,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.captionMuted.copyWith(height: 1.5)),
            ],
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DocHeader(doc: doc, docState: state.openedDocState),
        Expanded(
          child: Container(
            margin: const EdgeInsets.fromLTRB(
                AppDimens.gapXl, 0, AppDimens.gapXl, AppDimens.gapXl),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(AppDimens.cardRadius),
              border: Border.all(color: AppColors.borderSoft),
            ),
            child: _DocBody(doc: doc, content: state.openedDocContent),
          ),
        ),
      ],
    );
  }
}

class _DocBody extends StatelessWidget {
  final DocArtifact doc;
  final String? content;

  const _DocBody({required this.doc, required this.content});

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);
    if (!doc.exists) {
      return Padding(
        padding: const EdgeInsets.all(AppDimens.gapXl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(texts.docsMissingTitle, style: AppTextStyles.sectionTitle),
            const SizedBox(height: AppDimens.gapXs),
            Text(texts.docsMissingHint(doc.fileName),
                style: AppTextStyles.captionMuted),
          ],
        ),
      );
    }
    final text = content;
    if (text == null) {
      return Padding(
        padding: const EdgeInsets.all(AppDimens.gapXl),
        child: Text(texts.docsLoading, style: AppTextStyles.captionMuted),
      );
    }
    return DocMarkdown(data: text);
  }
}

class _DocHeader extends StatelessWidget {
  final DocArtifact doc;
  final DocState? docState;

  const _DocHeader({required this.doc, required this.docState});

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppDimens.gapXl, AppDimens.gapM, AppDimens.gapXl, AppDimens.gapM),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(texts.docLabel(doc), style: AppTextStyles.screenTitle),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(doc.fileName,
                        style: AppTextStyles.monospace(11.5,
                            color: AppColors.textMuted)),
                    if (docState case final branchState?) ...[
                      const SizedBox(width: 12),
                      _BranchChip(state: branchState),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (doc.exists)
            OutlinedButton.icon(
              onPressed: () => _openInEditor(context),
              icon: const Icon(Icons.open_in_new,
                  size: 14, color: AppColors.textSecondary),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.border),
                backgroundColor: AppColors.card,
                foregroundColor: AppColors.textPrimary,
              ),
              label: Text(texts.docsOpenInIde,
                  style: const TextStyle(fontSize: 12)),
            ),
        ],
      ),
    );
  }

  /// Редактор ищется на машине: если открыть нечем — говорим об этом,
  /// а не молчим о том, что кнопка ничего не сделала.
  Future<void> _openInEditor(BuildContext context) async {
    final texts = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final opened =
        await context.read<ConsoleBloc>().repository.openInEditor(doc.path);
    if (opened) return;
    messenger.showSnackBar(
        SnackBar(content: Text(texts.docsOpenInIdeFailed)));
  }
}

/// Состояние файла в ветке спеки: документы правит и агент, и человек,
/// поэтому «какую версию я читаю» — часть экрана, а не догадка.
class _BranchChip extends StatelessWidget {
  final DocState state;

  const _BranchChip({required this.state});

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);
    final dirty = state.file == DocFileState.modified ||
        state.file == DocFileState.untracked;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: dirty ? AppColors.warningBackground : AppColors.card,
        borderRadius: BorderRadius.circular(AppDimens.controlRadius),
        border: Border.all(
            color: dirty ? AppColors.warningBorder : AppColors.borderSoft),
      ),
      child: Text(
        texts.docStateLabel(state),
        style: AppTextStyles.monospace(10.5,
            color: dirty ? AppColors.warning : AppColors.textMuted),
      ),
    );
  }
}
