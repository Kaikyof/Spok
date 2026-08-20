import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../core/resources/app_colors.dart';
import '../core/resources/app_dimens.dart';
import '../core/resources/app_text_styles.dart';
import '../l10n/gen/app_localizations.dart';
import 'bloc/console_bloc.dart';
import 'localization/text_formatters.dart';
import 'screens/change_screen.dart';
import 'screens/env_screen.dart';
import 'screens/handoff_screen.dart';
import 'screens/placeholder_screen.dart';
import 'screens/setup_screen.dart';
import 'screens/sprint_screen.dart';
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
            previous.needsSetup != current.needsSetup,
        builder: (context, state) {
          if (state.isFirstLoad) {
            return AppLoader(message: texts.loaderMessage);
          }
          if (state.needsSetup) return const SetupScreen();
          return Row(
            children: const [
              _Sidebar(),
              Expanded(
                child: Column(
                  children: [
                    _Header(),
                    Expanded(child: _ScreenSwitcher()),
                  ],
                ),
              ),
            ],
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
    final texts = AppLocalizations.of(context);
    return BlocBuilder<ConsoleBloc, ConsoleState>(
      buildWhen: (previous, current) => previous.screen != current.screen,
      builder: (context, state) => switch (state.screen) {
        ConsoleScreen.sprint => const SprintScreen(),
        ConsoleScreen.changes => const ChangeScreen(),
        ConsoleScreen.env => const EnvScreen(),
        ConsoleScreen.handoff => const HandoffScreen(),
        ConsoleScreen.sessions => PlaceholderScreen(
            title: texts.sessionsTitle, note: texts.sessionsNote),
      },
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar();

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);
    final navItems = [
      (ConsoleScreen.sprint, texts.navSprint),
      (ConsoleScreen.changes, texts.navChanges),
      (ConsoleScreen.handoff, texts.navHandoff),
      (ConsoleScreen.env, texts.navEnv),
      (ConsoleScreen.sessions, texts.navSessions),
    ];
    return Container(
      width: AppDimens.sidebarWidth,
      color: AppColors.panel,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 40),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(texts.appBadge,
                style: AppTextStyles.sectionLabel
                    .copyWith(letterSpacing: 1.2, fontSize: 10.5)),
          ),
          const SizedBox(height: AppDimens.gapL),
          BlocBuilder<ConsoleBloc, ConsoleState>(
            buildWhen: (previous, current) => previous.screen != current.screen,
            builder: (context, state) => Column(
              children: [
                for (final (screen, label) in navItems)
                  _NavItem(
                    label: label,
                    active: state.screen == screen,
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

class _NavItem extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _NavItem(
      {required this.label, required this.active, required this.onTap});

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
                        borderRadius: BorderRadius.circular(2)),
                  ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                    color: active
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                  ),
                ),
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
    final role = context.read<ConsoleBloc>().repository.role;
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
          Text(texts.machineRoleLabel,
              style: AppTextStyles.sectionLabel.copyWith(fontSize: 9.5)),
          const SizedBox(height: 6),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                    color: roleKnown ? AppColors.success : AppColors.danger,
                    shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(roleKnown ? texts.roleLabel(role) : texts.roleNotSet,
                  style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary)),
            ],
          ),
          const SizedBox(height: 4),
          Text(texts.machineRoleEnvVar,
              style:
                  AppTextStyles.monospace(10, color: AppColors.textMuted)),
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
        final sprint = state.sprint;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const _SprintSwitcher(),
            if (sprint != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Text(sprint.branchIos ?? '—',
                      style: AppTextStyles.monospace(12)),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      _sprintMeta(texts, sprint),
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

  String _sprintMeta(AppLocalizations texts, sprint) {
    final parts = [
      sprint.delivery == 'batch'
          ? texts.deliveryBatch
          : texts.deliveryPerChange,
      if (sprint.buildIos != null)
        texts.buildIosLabel(sprint.buildIos!.versionName),
      if (sprint.buildAndroid != null)
        texts.buildAndroidLabel(sprint.buildAndroid!.versionName),
    ];
    return '· ${parts.join('  · ')}';
  }
}

class _SprintSwitcher extends StatelessWidget {
  const _SprintSwitcher();

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);
    return BlocBuilder<ConsoleBloc, ConsoleState>(
      builder: (context, state) {
        final sprints = state.snapshot?.sprints ?? [];
        final sprint = state.sprint;
        final title = sprint == null
            ? texts.sprintNone
            : texts.sprintTitlePrefix(sprint.title);
        final titleText = Text(title,
            overflow: TextOverflow.ellipsis, style: AppTextStyles.screenTitle);
        if (sprints.length <= 1) return titleText;
        return PopupMenuButton<String>(
          tooltip: texts.sprintSwitcherTooltip,
          color: AppColors.cardHighlight,
          onSelected: (sprintId) =>
              context.read<ConsoleBloc>().add(SprintSelected(sprintId)),
          itemBuilder: (_) => [
            for (final candidate in sprints)
              PopupMenuItem(
                value: candidate.id,
                child: Row(
                  children: [
                    Expanded(child: Text(candidate.title)),
                    if (candidate.id == sprint?.id)
                      const Icon(Icons.check,
                          size: 16, color: AppColors.accent),
                  ],
                ),
              ),
          ],
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(child: titleText),
              const SizedBox(width: 8),
              const Icon(Icons.expand_more,
                  size: 18, color: AppColors.textMuted),
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
            child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    final refreshedAt = state.snapshot?.refreshedAt;
    if (refreshedAt == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Text(texts.updatedAt(DateFormat.Hm().format(refreshedAt)),
          style: AppTextStyles.caption),
    );
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
          child:
              const Icon(Icons.refresh, size: 16, color: AppColors.textSecondary),
        ),
      );
}
