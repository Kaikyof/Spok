import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../core/theme.dart';
import 'bloc/console_bloc.dart';
import 'screens/change_screen.dart';
import 'screens/env_screen.dart';
import 'screens/placeholder_screen.dart';
import 'screens/sprint_screen.dart';

const _nav = [
  (ConsoleScreen.sprint, 'Спринт'),
  (ConsoleScreen.changes, "Change'и"),
  (ConsoleScreen.handoff, 'Передача'),
  (ConsoleScreen.env, 'Окружение'),
  (ConsoleScreen.sessions, 'Сессии'),
];

class Shell extends StatelessWidget {
  const Shell({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ConsoleBloc>().state;
    return Scaffold(
      body: Row(children: [
        _Sidebar(state: state),
        Expanded(
          child: Column(children: [
            _Header(state: state),
            Expanded(child: _body(state)),
          ]),
        ),
      ]),
    );
  }

  Widget _body(ConsoleState state) => switch (state.screen) {
        ConsoleScreen.sprint => const SprintScreen(),
        ConsoleScreen.changes => const ChangeScreen(),
        ConsoleScreen.env => const EnvScreen(),
        ConsoleScreen.handoff => const PlaceholderScreen(
            title: 'Передача спринта',
            note:
                'Мастер из четырёх шагов: готовность, сборка, получатели, предпросмотр. '
                'Следующий этап реализации.'),
        ConsoleScreen.sessions => const PlaceholderScreen(
            title: 'Агентные сессии',
            note:
                'Диалоги Claude Code в headless-режиме появятся после экранов состояния.'),
      };
}

class _Sidebar extends StatelessWidget {
  final ConsoleState state;
  const _Sidebar({required this.state});

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<ConsoleBloc>();
    final role = _roleLabel(context);
    return Container(
      width: 216,
      color: C.panel,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const SizedBox(height: 40),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text('AVTOTO · КОНСОЛЬ',
              style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                  color: C.text3)),
        ),
        const SizedBox(height: 20),
        for (final (screen, label) in _nav)
          _NavItem(
            label: label,
            active: state.screen == screen,
            onTap: () => bloc.add(ScreenSelected(screen)),
          ),
        const Spacer(),
        Container(
          margin: const EdgeInsets.all(8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: C.card,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: C.borderSoft),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('РОЛЬ МАШИНЫ',
                style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                    color: C.text3)),
            const SizedBox(height: 6),
            Row(children: [
              Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                      color: role == null ? C.danger : C.ok,
                      shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Text(role ?? 'роль не задана',
                  style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: C.text)),
            ]),
            const SizedBox(height: 4),
            Text('AVTOTO_ROLE', style: mono(10, color: C.text3)),
          ]),
        ),
      ]),
    );
  }

  String? _roleLabel(BuildContext context) {
    final role = context.read<ConsoleBloc>().repo.role;
    return switch (role) {
      'ios' => 'iOS-разработчик',
      'android' => 'Android-разработчик',
      'qa' => 'Тестировщик',
      'dev' => 'Разработчик (оба стека)',
      '' => null,
      _ => role,
    };
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
          borderRadius: BorderRadius.circular(7),
          child: Container(
            height: 34,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: active ? C.cardHi : null,
              borderRadius: BorderRadius.circular(7),
            ),
            child: Row(children: [
              if (active)
                Container(
                    width: 3,
                    height: 16,
                    margin: const EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(
                        color: C.accent,
                        borderRadius: BorderRadius.circular(2))),
              Text(label,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                      color: active ? C.text : C.text2)),
            ]),
          ),
        ),
      );
}

class _Header extends StatelessWidget {
  final ConsoleState state;
  const _Header({required this.state});

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<ConsoleBloc>();
    final sprint = state.sprint;
    final fresh = state.snapshot?.refreshedAt;
    return Container(
      height: 88,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: C.panel,
        border: Border(bottom: BorderSide(color: C.borderSoft)),
      ),
      child: Row(children: [
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _SprintSwitcher(state: state),
                const SizedBox(height: 6),
                if (sprint != null)
                  Row(children: [
                    Text(sprint.branchIos ?? '—', style: mono(12)),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        '· сдача ${sprint.delivery == 'batch' ? 'целиком (batch)' : 'по change\'ам'}'
                        '${sprint.buildIos != null ? '  · iOS ${sprint.buildIos!.versionName}' : ''}'
                        '${sprint.buildAndroid != null ? '  · Android ${sprint.buildAndroid!.versionName}' : ''}',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, color: C.text2),
                      ),
                    ),
                  ]),
              ]),
        ),
        if (state.status == LoadStatus.loading)
          const Padding(
            padding: EdgeInsets.only(right: 12),
            child: SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2)),
          )
        else if (fresh != null)
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Text('обновлено ${DateFormat.Hm().format(fresh)}',
                style: const TextStyle(fontSize: 12, color: C.text2)),
          ),
        Tooltip(
          message: 'Обновить (⌘R)',
          child: OutlinedButton(
            onPressed: () => bloc.add(ConsoleRefreshed()),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(52, 30),
              padding: EdgeInsets.zero,
              side: const BorderSide(color: C.border),
              backgroundColor: C.card,
            ),
            child: const Icon(Icons.refresh, size: 16, color: C.text2),
          ),
        ),
      ]),
    );
  }
}

class _SprintSwitcher extends StatelessWidget {
  final ConsoleState state;
  const _SprintSwitcher({required this.state});

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<ConsoleBloc>();
    final sprints = state.snapshot?.sprints ?? [];
    final sprint = state.sprint;
    final title =
        sprint == null ? 'Нет активного спринта' : 'Спринт: ${sprint.title}';
    if (sprints.length <= 1) {
      return Text(title,
          style: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.w600, color: C.text));
    }
    return PopupMenuButton<String>(
      tooltip: 'Переключить спринт · openspec/doc',
      color: C.cardHi,
      onSelected: (id) => bloc.add(SprintSelected(id)),
      itemBuilder: (_) => [
        for (final s in sprints)
          PopupMenuItem(
            value: s.id,
            child: Row(children: [
              Expanded(child: Text(s.title)),
              if (s.id == sprint?.id)
                const Icon(Icons.check, size: 16, color: C.accent),
            ]),
          ),
      ],
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Flexible(
          child: Text(title,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w600, color: C.text)),
        ),
        const SizedBox(width: 8),
        const Icon(Icons.expand_more, size: 18, color: C.text3),
      ]),
    );
  }
}
