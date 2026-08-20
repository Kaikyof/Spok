import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/theme.dart';
import '../../domain/entities/entities.dart';
import '../bloc/console_bloc.dart';
import '../widgets/common.dart';

/// Экран «Окружение»: поймать проблему до запуска, а не в середине.
class EnvScreen extends StatelessWidget {
  const EnvScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bloc = context.watch<ConsoleBloc>();
    final env = bloc.state.snapshot?.env;
    if (env == null) return const Center(child: CircularProgressIndicator());
    final problems = env.problems;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Row(children: [
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Проверки окружения',
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600, color: C.text)),
              const SizedBox(height: 4),
              Text(
                problems == 0
                    ? 'всё готово к работе'
                    : '$problems ${_plural(problems)} — часть действий не сработает',
                style: TextStyle(
                    fontSize: 12, color: problems == 0 ? C.ok : C.danger),
              ),
            ]),
          ),
          OutlinedButton(
            onPressed: () => bloc.add(ConsoleRefreshed()),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: C.border),
              backgroundColor: C.cardHi,
              foregroundColor: C.text,
            ),
            child: const Text('Перепроверить всё',
                style: TextStyle(fontSize: 12)),
          ),
        ]),
        const SizedBox(height: 20),
        _section('Ключи в .env — показывается только наличие, не значения',
            env.keys),
        const SizedBox(height: 16),
        _section('Репозитории', env.repos),
        const SizedBox(height: 16),
        _section('Внешние системы', env.systems, monoName: false),
      ],
    );
  }

  String _plural(int n) =>
      n == 1 ? 'проблема' : (n < 5 ? 'проблемы' : 'проблем');

  Widget _section(String title, List<EnvCheck> checks,
          {bool monoName = true}) =>
      SectionCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600, color: C.text)),
          const SizedBox(height: 8),
          for (final (i, c) in checks.indexed) ...[
            if (i > 0) const Divider(height: 1),
            CheckRow(check: c, monoName: monoName),
          ],
        ]),
      );
}
