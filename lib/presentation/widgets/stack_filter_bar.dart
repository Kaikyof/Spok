import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../l10n/gen/app_localizations.dart';
import '../bloc/console_bloc.dart';
import '../localization/text_formatters.dart';
import '../ui_kit/stack_filter_control.dart';

/// Переключатель стеков спеки. Стеки приходят из схемы, поэтому переключатель
/// строится по ним и при одном стеке не рисуется вовсе.
class StackFilterBar extends StatelessWidget {
  const StackFilterBar({super.key});

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);
    return BlocBuilder<ConsoleBloc, ConsoleState>(
      buildWhen: (previous, current) =>
          previous.stackFilter != current.stackFilter ||
          previous.stacks != current.stacks,
      builder: (context, state) {
        if (!state.profile.showStackFilter) return const SizedBox.shrink();
        return StackFilterControl<String>(
          options: [
            ('', texts.stackFilterAll),
            for (final stack in state.stacks) (stack, texts.stackLabel(stack)),
          ],
          selected: state.stackFilter,
          onChanged: (stack) =>
              context.read<ConsoleBloc>().add(StackFilterChanged(stack)),
        );
      },
    );
  }
}
