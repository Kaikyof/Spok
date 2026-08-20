import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../core/resources/app_colors.dart';
import '../../core/resources/app_dimens.dart';
import '../../core/resources/app_text_styles.dart';
import '../../domain/entities/agent_session.dart';
import '../../l10n/gen/app_localizations.dart';
import '../bloc/sessions_bloc.dart';
import '../ui_kit/section_card.dart';

/// Агентные сессии: часть работы требует суждения и ведётся моделью
/// в диалоге (бриф §5.6). Визуально отличается от кнопок-действий.
class SessionsScreen extends StatelessWidget {
  const SessionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);
    return BlocBuilder<SessionsBloc, SessionsState>(
      builder: (context, state) {
        if (!state.cliAvailable) {
          return Center(
            child: Text(texts.sessionCliMissing,
                textAlign: TextAlign.center, style: AppTextStyles.body),
          );
        }
        return Padding(
          padding: AppDimens.screenPadding,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(width: 256, child: _SessionList(state: state)),
              const SizedBox(width: AppDimens.gapL),
              Expanded(child: _SessionPanel(state: state)),
            ],
          ),
        );
      },
    );
  }
}

class _SessionList extends StatelessWidget {
  final SessionsState state;

  const _SessionList({required this.state});

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);
    return SectionCard(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 10),
            child: Text(texts.sessionsListTitle,
                style: AppTextStyles.sectionTitle),
          ),
          Expanded(
            child: ListView(
              children: [
                for (final session in state.sessions)
                  _SessionListItem(
                      session: session,
                      active: session.id == state.selectedSessionId),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionListItem extends StatelessWidget {
  final AgentSession session;
  final bool active;

  const _SessionListItem({required this.session, required this.active});

  (Color, String) _statusOf(AppLocalizations texts) => switch (session.status) {
        AgentSessionStatus.running => (AppColors.warning, texts.sessionRunning),
        AgentSessionStatus.done => (AppColors.success, texts.sessionDone),
        AgentSessionStatus.failed => (AppColors.danger, texts.sessionFailed),
        AgentSessionStatus.stopped => (AppColors.textMuted, texts.sessionDone),
      };

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);
    final (statusColor, statusLabel) = _statusOf(texts);
    return InkWell(
      onTap: () =>
          context.read<SessionsBloc>().add(SessionSelected(session.id)),
      borderRadius: BorderRadius.circular(AppDimens.controlRadius),
      child: Container(
        padding: const EdgeInsets.all(10),
        margin: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          color: active ? AppColors.cardHighlight : null,
          borderRadius: BorderRadius.circular(AppDimens.controlRadius),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(session.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                    color: active
                        ? AppColors.textPrimary
                        : AppColors.textSecondary)),
            const SizedBox(height: 5),
            Row(
              children: [
                Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                        color: statusColor, shape: BoxShape.circle)),
                const SizedBox(width: 6),
                Text(
                    '$statusLabel · ${DateFormat.Hm().format(session.startedAt)}',
                    style: const TextStyle(
                        fontSize: 10.5, color: AppColors.textMuted)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SessionPanel extends StatelessWidget {
  final SessionsState state;

  const _SessionPanel({required this.state});

  @override
  Widget build(BuildContext context) {
    final session = state.selected;
    return SectionCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _PanelHeader(state: state, session: session),
          const Divider(height: 1),
          Expanded(
            child: session == null
                ? const _EmptyTranscript()
                : _Transcript(session: session),
          ),
          const Divider(height: 1),
          const _PromptInput(),
        ],
      ),
    );
  }
}

class _PanelHeader extends StatelessWidget {
  final SessionsState state;
  final AgentSession? session;

  const _PanelHeader({required this.state, required this.session});

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);
    final running = session?.status == AgentSessionStatus.running;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(session?.title ?? texts.sessionNew,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.sectionTitle),
          ),
          if (running)
            TextButton(
              onPressed: () =>
                  context.read<SessionsBloc>().add(SessionStopRequested()),
              child: Text(texts.sessionStop,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.danger)),
            ),
          const SizedBox(width: AppDimens.gapS),
          _ModelPicker(model: state.model, enabled: !running),
        ],
      ),
    );
  }
}

class _ModelPicker extends StatelessWidget {
  final String model;
  final bool enabled;

  const _ModelPicker({required this.model, required this.enabled});

  @override
  Widget build(BuildContext context) => PopupMenuButton<String>(
        enabled: enabled,
        color: AppColors.cardHighlight,
        onSelected: (selectedModel) => context
            .read<SessionsBloc>()
            .add(SessionModelChanged(selectedModel)),
        itemBuilder: (_) => [
          for (final candidate in agentModels)
            PopupMenuItem(
              value: candidate,
              child: Text(candidate,
                  style: const TextStyle(fontSize: 12.5)),
            ),
        ],
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.cardHighlight,
            borderRadius: BorderRadius.circular(13),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Claude · $model',
                  style: const TextStyle(
                      fontSize: 11.5, color: AppColors.textSecondary)),
              const Icon(Icons.expand_more,
                  size: 14, color: AppColors.textMuted),
            ],
          ),
        ),
      );
}

class _EmptyTranscript extends StatelessWidget {
  const _EmptyTranscript();

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Text(texts.sessionEmptyHint,
            textAlign: TextAlign.center,
            style: AppTextStyles.captionMuted.copyWith(height: 1.6)),
      ),
    );
  }
}

class _Transcript extends StatelessWidget {
  final AgentSession session;

  const _Transcript({required this.session});

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);
    return ListView(
      reverse: true,
      padding: const EdgeInsets.all(16),
      children: [
        if (session.status == AgentSessionStatus.running)
          const Padding(
            padding: EdgeInsets.only(top: 10),
            child: Row(
              children: [
                SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                        strokeWidth: 1.5, color: AppColors.warning)),
              ],
            ),
          ),
        for (final event in session.events.reversed)
          _TranscriptEntry(event: event, session: session, texts: texts),
      ],
    );
  }
}

class _TranscriptEntry extends StatelessWidget {
  final AgentEvent event;
  final AgentSession session;
  final AppLocalizations texts;

  const _TranscriptEntry(
      {required this.event, required this.session, required this.texts});

  @override
  Widget build(BuildContext context) => switch (event.kind) {
        AgentEventKind.userMessage => Align(
            alignment: Alignment.centerRight,
            child: Container(
              margin: const EdgeInsets.only(bottom: 10, left: 60),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.accentDim,
                borderRadius: BorderRadius.circular(10),
              ),
              child: SelectableText(event.text,
                  style: const TextStyle(
                      fontSize: 12.5, color: AppColors.textPrimary)),
            ),
          ),
        AgentEventKind.assistantText => Container(
            margin: const EdgeInsets.only(bottom: 10, right: 60),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.cardHighlight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: SelectableText(event.text,
                style: AppTextStyles.caption.copyWith(height: 1.5)),
          ),
        AgentEventKind.toolAction => Padding(
            padding: const EdgeInsets.only(bottom: 6, left: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('✓',
                    style: TextStyle(fontSize: 11, color: AppColors.success)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(event.text,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.monospace(11,
                          color: AppColors.monospaceText)),
                ),
              ],
            ),
          ),
        AgentEventKind.result => Container(
            margin: const EdgeInsets.only(bottom: 10, top: 4),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.logBackground,
              borderRadius: BorderRadius.circular(AppDimens.controlRadius),
              border: Border.all(color: AppColors.borderSoft),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    texts.sessionResultLabel(
                        ((session.duration?.inMilliseconds ?? 0) / 1000)
                            .toStringAsFixed(1)),
                    style: AppTextStyles.sectionLabel.copyWith(fontSize: 9.5)),
                const SizedBox(height: 6),
                SelectableText(event.text,
                    style: AppTextStyles.caption.copyWith(height: 1.5)),
              ],
            ),
          ),
        AgentEventKind.error => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(event.text,
                style: AppTextStyles.monospace(11, color: AppColors.danger)),
          ),
      };
}

class _PromptInput extends StatefulWidget {
  const _PromptInput();

  @override
  State<_PromptInput> createState() => _PromptInputState();
}

class _PromptInputState extends State<_PromptInput> {
  final _promptController = TextEditingController();

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  void _submit() {
    final prompt = _promptController.text.trim();
    if (prompt.isEmpty) return;
    context.read<SessionsBloc>().add(SessionStarted(prompt));
    _promptController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _promptController,
              onSubmitted: (_) => _submit(),
              style: const TextStyle(
                  fontSize: 12.5, color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: texts.sessionInputHint,
                hintStyle: AppTextStyles.captionMuted,
                filled: true,
                fillColor: AppColors.background,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 11),
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(AppDimens.controlRadius),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(AppDimens.controlRadius),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppDimens.gapS),
          IconButton(
            onPressed: _submit,
            icon: const Icon(Icons.arrow_upward,
                size: 18, color: AppColors.accent),
          ),
        ],
      ),
    );
  }
}
