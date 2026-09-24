import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;

import '../core/resources/app_colors.dart';
import '../core/resources/app_dimens.dart';
import '../core/resources/app_text_styles.dart';
import '../domain/entities/group.dart';
import '../domain/entities/project_profile.dart';
import '../domain/repositories/command_log.dart';
import '../l10n/gen/app_localizations.dart';
import '../main.dart';
import 'widgets/launch_panel.dart';
import 'bloc/console_bloc.dart';
import 'bloc/sessions_bloc.dart';
import 'localization/text_formatters.dart';
import 'screens/change_screen.dart';
import 'screens/docs_screen.dart';
import 'screens/env_screen.dart';
import 'screens/handoff_screen.dart';
import 'screens/group_screen.dart';
import 'screens/recognition_screen.dart';
import 'screens/sessions_screen.dart';
import 'screens/setup_screen.dart';
import 'ui_kit/app_loader.dart';

class Shell extends StatelessWidget {
  const Shell({super.key});

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);
    return Scaffold(
      body: BlocBuilder<ConsoleBloc, ConsoleState>(
        buildWhen: (previous, current) =>
            previous.isFirstLoad != current.isFirstLoad ||
            previous.needsSetup != current.needsSetup ||
            previous.recognitionReview != current.recognitionReview,
        builder: (context, state) {
          if (state.isFirstLoad) {
            return AppLoader(message: texts.loaderMessage);
          }
          // Спека только что подключена — шаг «Что распознано» стоит
          // перед экранами: сначала человек видит разбор, потом данные.
          if (state.recognitionReview) return const RecognitionScreen();
          if (state.needsSetup) return const SetupScreen();
          return BlocListener<ConsoleBloc, ConsoleState>(
            // Сменились спека или группа — сессии перечитывают команды,
            // change'и для подсказок и настройки нового проекта.
            listenWhen: (previous, current) =>
                previous.group?.id != current.group?.id ||
                previous.snapshot != current.snapshot,
            listener: (context, consoleState) =>
                context.read<SessionsBloc>().add(
                  SessionsContextChanged(
                    changeIds: [
                      for (final change in consoleState.groupChanges) change.id,
                    ],
                  ),
                ),
            child: Row(
              children: [
                const _Sidebar(),
                Expanded(
                  child: Column(
                    children: [
                      const _Header(),
                      // Любой текст на экране можно выделить и скопировать
                      // (⌘C): ветки, идентификаторы и комментарии уходят
                      // в переписку.
                      const Expanded(
                        child: SelectionArea(child: _ScreenSwitcher()),
                      ),
                      // Панель запуска — постоянный элемент вне зависимости
                      // от экрана (бриф §4).
                      LaunchPanel(
                        commandLog: getIt<CommandLog>(),
                        project: p.basename(
                          context.read<ConsoleBloc>().repository.rootPath ?? '',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ScreenSwitcher extends StatelessWidget {
  const _ScreenSwitcher();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConsoleBloc, ConsoleState>(
      buildWhen: (previous, current) => previous.screen != current.screen,
      builder: (context, state) => switch (state.screen) {
        ConsoleScreen.group => const GroupScreen(),
        ConsoleScreen.changes => const ChangeScreen(),
        ConsoleScreen.env => const EnvScreen(),
        ConsoleScreen.handoff => const HandoffScreen(),
        ConsoleScreen.docs => const DocsScreen(),
        ConsoleScreen.sessions => const SessionsScreen(),
      },
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar();

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);
    // У пункта выключенной фичи — счётчик невыполненных требований,
    // а не исчезновение пункта: фича не должна забываться.
    final navItems = [
      (ConsoleScreen.group, texts.navGroup, null),
      (ConsoleScreen.changes, texts.navChanges, null),
      (ConsoleScreen.handoff, texts.navHandoff, SpecFeature.handoff),
      (ConsoleScreen.env, texts.navEnv, null),
      (ConsoleScreen.sessions, texts.navSessions, null),
      (ConsoleScreen.docs, texts.navDocs, null),
    ];
    return Container(
      width: AppDimens.sidebarWidth,
      color: AppColors.panel,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 40),
          const _SpecSwitcher(),
          const SizedBox(height: AppDimens.gapL),
          BlocBuilder<ConsoleBloc, ConsoleState>(
            buildWhen: (previous, current) =>
                previous.screen != current.screen ||
                previous.profile != current.profile,
            builder: (context, state) => Column(
              children: [
                for (final (screen, label, feature) in navItems)
                  _NavItem(
                    label: label,
                    active: state.screen == screen,
                    unmetCount:
                        feature == null || state.profile.enabled(feature)
                        ? 0
                        : state.profile.unmetCount(feature),
                    onTap: () =>
                        context.read<ConsoleBloc>().add(ScreenSelected(screen)),
                  ),
              ],
            ),
          ),
          const Spacer(),
          const _MachineRoleCard(),
        ],
      ),
    );
  }
}

/// Бейдж спеки и переключатель между подключёнными: спек у человека
/// несколько, и путь не должен правиться руками в конфиге.
class _SpecSwitcher extends StatelessWidget {
  const _SpecSwitcher();

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);
    return BlocBuilder<ConsoleBloc, ConsoleState>(
      buildWhen: (previous, current) =>
          previous.knownSpecs != current.knownSpecs,
      builder: (context, state) {
        final current = context.read<ConsoleBloc>().repository.rootPath;
        return PopupMenuButton<String>(
          tooltip: texts.specSwitcherTooltip,
          color: AppColors.cardHighlight,
          onSelected: (value) => value.isEmpty
              ? context.read<ConsoleBloc>().add(SpecSwitchRequested(true))
              : context.read<ConsoleBloc>().add(PlatformPathSubmitted(value)),
          itemBuilder: (_) => [
            for (final path in state.knownSpecs)
              PopupMenuItem(
                value: path,
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.basename(path)),
                          Text(
                            path,
                            style: AppTextStyles.monospace(
                              10,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (path == current)
                      const Icon(
                        Icons.check,
                        size: 16,
                        color: AppColors.accent,
                      ),
                  ],
                ),
              ),
            if (state.knownSpecs.isNotEmpty) const PopupMenuDivider(),
            PopupMenuItem(value: '', child: Text(texts.specAdd)),
          ],
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    current == null
                        ? texts.appBadgeGeneric
                        : p.basename(current).toUpperCase(),
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.sectionLabel.copyWith(
                      letterSpacing: 1.2,
                      fontSize: 10.5,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(
                  Icons.unfold_more,
                  size: 13,
                  color: AppColors.textMuted,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _NavItem extends StatelessWidget {
  final String label;
  final bool active;

  /// Невыполненные требования фичи; 0 — фича работает.
  final int unmetCount;

  final VoidCallback onTap;

  const _NavItem({
    required this.label,
    required this.active,
    required this.onTap,
    this.unmetCount = 0,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimens.controlRadius),
      child: Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: active ? AppColors.cardHighlight : null,
          borderRadius: BorderRadius.circular(AppDimens.controlRadius),
        ),
        child: Row(
          children: [
            if (active)
              Container(
                width: 3,
                height: 16,
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                color: active
                    ? AppColors.textPrimary
                    : unmetCount > 0
                    ? AppColors.textMuted
                    : AppColors.textSecondary,
              ),
            ),
            if (unmetCount > 0) ...[
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.borderSoft),
                ),
                child: Text(
                  '$unmetCount',
                  style: AppTextStyles.monospace(
                    10.5,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

class _MachineRoleCard extends StatelessWidget {
  const _MachineRoleCard();

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);
    final repository = context.read<ConsoleBloc>().repository;
    final role = repository.role;
    final roleKey = repository.roleKey;
    final roleKnown = role.isNotEmpty;
    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            texts.machineRoleLabel,
            style: AppTextStyles.sectionLabel.copyWith(fontSize: 9.5),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 5),
                decoration: BoxDecoration(
                  color: roleKnown ? AppColors.success : AppColors.danger,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              // «Разработчик (оба стека)» длиннее карточки — переносим.
              Expanded(
                child: Text(
                  roleKnown ? texts.roleLabel(role) : texts.roleNotSet,
                  style: const TextStyle(
                    fontSize: 12.5,
                    height: 1.25,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          if (roleKey.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              roleKey,
              style: AppTextStyles.monospace(10, color: AppColors.textMuted),
            ),
          ],
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) => Container(
    height: AppDimens.headerHeight,
    padding: const EdgeInsets.symmetric(horizontal: AppDimens.gapXl),
    decoration: const BoxDecoration(
      color: AppColors.panel,
      border: Border(bottom: BorderSide(color: AppColors.borderSoft)),
    ),
    child: BlocBuilder<ConsoleBloc, ConsoleState>(
      builder: (context, state) => Row(
        children: [
          const Expanded(child: _HeaderTitle()),
          _FreshnessIndicator(state: state),
          _RefreshButton(),
        ],
      ),
    ),
  );
}

class _HeaderTitle extends StatelessWidget {
  const _HeaderTitle();

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);
    return BlocBuilder<ConsoleBloc, ConsoleState>(
      builder: (context, state) {
        final group = state.group;
        final branch = group?.branches.values.firstOrNull;
        final meta = _groupMeta(texts, group);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const _GroupSwitcher(),
            if (branch != null || meta.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  if (branch != null) ...[
                    Text(branch, style: AppTextStyles.monospace(12)),
                    const SizedBox(width: 12),
                  ],
                  Flexible(
                    child: Text(
                      meta,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption,
                    ),
                  ),
                ],
              ),
            ],
          ],
        );
      },
    );
  }

  /// Подпись группы: режим сдачи и сборки — только если спека их ведёт.
  String _groupMeta(AppLocalizations texts, Group? group) {
    if (group == null || group.kind != GroupingKind.sprintDir) return '';
    final parts = [
      group.delivery == 'batch' ? texts.deliveryBatch : texts.deliveryPerChange,
      for (final entry in group.builds.entries)
        '${texts.stackLabel(entry.key)} ${entry.value.versionName}',
    ];
    return '· ${parts.join('  · ')}';
  }
}

class _GroupSwitcher extends StatelessWidget {
  const _GroupSwitcher();

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);
    return BlocBuilder<ConsoleBloc, ConsoleState>(
      builder: (context, state) {
        final groups = state.snapshot?.groups ?? [];
        final group = state.group;
        final amongNamed = groups.any(
          (candidate) => candidate.kind != GroupingKind.none,
        );
        final titleText = Text(
          texts.groupTitle(group, amongNamed: amongNamed),
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.screenTitle,
        );
        if (groups.length <= 1) return titleText;
        return PopupMenuButton<String>(
          tooltip: texts.groupSwitcherTooltip,
          color: AppColors.cardHighlight,
          onSelected: (groupId) =>
              context.read<ConsoleBloc>().add(GroupSelected(groupId)),
          itemBuilder: (_) => [
            for (final candidate in groups)
              PopupMenuItem(
                value: candidate.id,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        texts.groupTitle(candidate, amongNamed: amongNamed),
                      ),
                    ),
                    if (candidate.id == group?.id)
                      const Icon(
                        Icons.check,
                        size: 16,
                        color: AppColors.accent,
                      ),
                  ],
                ),
              ),
          ],
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(child: titleText),
              const SizedBox(width: 8),
              const Icon(
                Icons.expand_more,
                size: 18,
                color: AppColors.textMuted,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FreshnessIndicator extends StatelessWidget {
  final ConsoleState state;

  const _FreshnessIndicator({required this.state});

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);
    if (state.status == LoadStatus.loading) {
      return const Padding(
        padding: EdgeInsets.only(right: 12),
        child: SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    final refreshedAt = state.snapshot?.refreshedAt;
    if (refreshedAt == null) return const SizedBox.shrink();
    final age = DateTime.now().difference(refreshedAt);
    final stale = age.inMinutes >= 15;
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Row(
        children: [
          Tooltip(
            message: texts.updatedAt(DateFormat.Hm().format(refreshedAt)),
            child: Text(
              _freshnessLabel(texts, age, stale),
              style: AppTextStyles.caption.copyWith(
                color: stale ? AppColors.warning : null,
              ),
            ),
          ),
          // Подсветка без кнопки оставляет человека искать обновление
          // глазами по шапке — кнопка стоит рядом с самой пометкой.
          if (stale)
            TextButton(
              onPressed: () =>
                  context.read<ConsoleBloc>().add(ConsoleRefreshed()),
              style: TextButton.styleFrom(
                minimumSize: const Size(0, 28),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                foregroundColor: AppColors.warning,
              ),
              child: Text(texts.freshRefresh,
                  style: const TextStyle(fontSize: 12)),
            ),
        ],
      ),
    );
  }

  /// Свежесть данных — часть интерфейса (бриф §3.6): относительное время,
  /// а устаревшие данные мягко подсвечиваются.
  String _freshnessLabel(AppLocalizations texts, Duration age, bool stale) {
    if (stale) return texts.freshStale;
    if (age.inMinutes < 1) return texts.freshJustNow;
    if (age.inHours < 1) return texts.freshMinutes(age.inMinutes);
    return texts.freshHours(age.inHours);
  }
}

class _RefreshButton extends StatelessWidget {
  const _RefreshButton();

  @override
  Widget build(BuildContext context) => Tooltip(
    message: AppLocalizations.of(context).refreshTooltip,
    child: OutlinedButton(
      onPressed: () => context.read<ConsoleBloc>().add(ConsoleRefreshed()),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(52, 30),
        padding: EdgeInsets.zero,
        side: const BorderSide(color: AppColors.border),
        backgroundColor: AppColors.card,
      ),
      child: const Icon(
        Icons.refresh,
        size: 16,
        color: AppColors.textSecondary,
      ),
    ),
  );
}
