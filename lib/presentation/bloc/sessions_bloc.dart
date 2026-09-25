import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/sources/agent_cli_source.dart';
import '../../data/sources/app_config_source.dart';
import '../../domain/entities/agent_session.dart';
import '../../domain/entities/slash_command.dart';
import '../../domain/repositories/command_log.dart';
import '../../domain/repositories/platform_repository.dart';

part 'sessions_event.dart';
part 'sessions_state.dart';

/// Агентные сессии: запуск Claude Code поверх репозитория платформы.
/// Сообщения продолжают один диалог, а не плодят новые сессии.
class SessionsBloc extends Bloc<SessionsEvent, SessionsState> {
  final PlatformRepository repository;
  final CommandLog? commandLog;
  final AppConfigSource config;
  final Map<String, AgentCliSource> _runningSources = {};

  /// [cliAvailable] — есть ли на машине бинарь агента. По умолчанию блок
  /// спрашивает саму машину, но тест обязан задавать значение явно: иначе
  /// он проверяет не экран, а установлен ли Claude Code у того, кто его
  /// запускает, и падает на чистой машине и в CI.
  SessionsBloc(
    this.repository, {
    this.commandLog,
    AppConfigSource? config,
    bool? cliAvailable,
  })  : config = config ?? AppConfigSource(),
        super(_initialState(repository, cliAvailable)) {
    on<SessionMessageSent>(_onMessageSent);
    on<SessionCreated>(_onCreated);
    on<SessionDeleted>(_onDeleted);
    on<SessionSelected>((event, emit) {
      final session = _sessionById(event.sessionId);
      // Контекст сессии: её модель и усилия становятся текущими.
      emit(state.copyWith(
        selectedSessionId: event.sessionId,
        model: session?.model,
        effort: session?.effort,
        permissionMode: session?.permissionMode,
      ));
    });
    on<SessionStopRequested>(_onStopRequested);
    on<SessionModelChanged>((event, emit) {
      // Своё имя модели остаётся в списке: человек ввёл его один раз.
      final models = state.models.contains(event.model)
          ? state.models
          : [...state.models, event.model];
      emit(state.copyWith(model: event.model, models: models));
      _rememberSettings();
    });
    on<SessionEffortChanged>((event, emit) {
      emit(state.copyWith(effort: event.effort));
      _rememberSettings();
    });
    on<SessionPermissionModeChanged>((event, emit) {
      emit(state.copyWith(permissionMode: event.mode));
      _rememberSettings();
    });
    on<SessionTerminalHeightChanged>((event, emit) {
      emit(state.copyWith(terminalHeight: event.height));
      if (event.remember) _rememberSettings();
    });
    on<SessionPaletteToggled>(
        (event, emit) => emit(state.copyWith(paletteOpen: event.open)));
    on<SessionDraftSet>((event, emit) => emit(state.copyWith(
          draft: event.text,
          revision: state.revision + 1,
        )));
    on<SessionsContextChanged>(_onContextChanged);
    on<HandoffRunRequested>(_onHandoffRun);
    on<_SettingsRestored>((event, emit) => emit(state.copyWith(
          model: event.model,
          models: event.models,
          effort: event.effort,
          permissionMode: event.permissionMode,
          terminalHeight: event.terminalHeight,
        )));
    on<_SessionEventReceived>(_onEventReceived);
    on<_SessionCliIdReceived>(_onCliIdReceived);
    on<_SessionFinished>(_onFinished);
    _restoreSettings();
  }

  /// Настройки сессии живут по проекту: модель, доступ, усилия и высота
  /// терминала у каждой спеки свои. Ключ без проекта остаётся запасным —
  /// конфиги, написанные до разделения, не теряются.
  String _key(String key) =>
      AppConfigSource.scoped(key, repository.rootPath);

  Future<void> _restoreSettings() async {
    final saved = await config.readAll();
    String? valueOf(String key) => saved[_key(key)] ?? saved[key];
    final model = valueOf(AppConfigSource.sessionModelKey);
    final effort = AgentEffort.values
        .where((value) => value.name == valueOf(AppConfigSource.sessionEffortKey))
        .firstOrNull;
    final permission = AgentPermissionMode.values
        .where((value) =>
            value.name == valueOf(AppConfigSource.sessionPermissionKey))
        .firstOrNull;
    final models = (valueOf(AppConfigSource.sessionModelsKey) ?? '')
        .split(',')
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList();
    final terminal =
        double.tryParse(valueOf(AppConfigSource.sessionTerminalKey) ?? '');
    if (isClosed) return;
    add(_SettingsRestored(
      (model ?? '').isEmpty ? state.model : model!,
      models.isEmpty ? state.models : models,
      effort ?? state.effort,
      permission ?? state.permissionMode,
      terminal ?? state.terminalHeight,
    ));
  }

  void _rememberSettings() {
    config.write(_key(AppConfigSource.sessionModelKey), state.model);
    config.write(
        _key(AppConfigSource.sessionModelsKey), state.models.join(','));
    config.write(_key(AppConfigSource.sessionEffortKey), state.effort.name);
    config.write(_key(AppConfigSource.sessionPermissionKey),
        state.permissionMode.name);
    config.write(_key(AppConfigSource.sessionTerminalKey),
        state.terminalHeight.round().toString());
  }

  /// Спека или группа сменились. Команды и значения аргументов читаются
  /// заново, а при смене спеки сбрасываются сессии: их `--resume` живёт
  /// в прежнем репозитории и в новом ничего не продолжит.
  void _onContextChanged(
      SessionsContextChanged event, Emitter<SessionsState> emit) {
    final values = repository.argumentValues();
    final workingDirectory = repository.rootPath ?? '';
    final projectChanged = workingDirectory != state.workingDirectory;
    if (projectChanged) {
      for (final source in _runningSources.values) {
        source.stop();
      }
      _runningSources.clear();
    }
    emit(state.copyWith(
      commands: repository.slashCommands(),
      changeIds:
          event.changeIds.isEmpty ? values.changeIds : event.changeIds,
      groupIds: values.groupIds,
      workingDirectory: workingDirectory,
      sessions: projectChanged ? const [] : null,
      selectedSessionId: projectChanged ? '' : null,
      revision: state.revision + 1,
    ));
    // Модель, доступ, усилия и высота терминала — свои у каждой спеки.
    if (projectChanged) _restoreSettings();
  }

  /// Передача спринта: команда платформы запускается в новой сессии
  /// с полным доступом — иначе headless-агент упрётся в запрос разрешения.
  Future<void> _onHandoffRun(
      HandoffRunRequested event, Emitter<SessionsState> emit) async {
    emit(state.copyWith(
      permissionMode: AgentPermissionMode.bypass,
      selectedSessionId: '',
    ));
    add(SessionMessageSent(event.command));
  }

  static SessionsState _initialState(
      PlatformRepository repository, bool? cliAvailable) {
    final values = repository.argumentValues();
    return SessionsState(
      cliAvailable: cliAvailable ?? AgentCliSource.locateBinary() != null,
      commands: repository.slashCommands(),
      changeIds: values.changeIds,
      groupIds: values.groupIds,
      workingDirectory: repository.rootPath ?? '',
    );
  }

  Future<void> _onMessageSent(
      SessionMessageSent event, Emitter<SessionsState> emit) async {
    final binary = AgentCliSource.locateBinary();
    final workingDirectory = repository.rootPath;
    final prompt = event.prompt.trim();
    if (binary == null || workingDirectory == null || prompt.isEmpty) return;

    final session = state.selected ?? _newSession();
    final isNewSession = !state.sessions.contains(session);
    if (session.isRunning) return;

    session.events.add(AgentEvent(AgentEventKind.userMessage, prompt));
    session.status = AgentSessionStatus.running;
    if (session.isEmpty || session.messageCount == 1) {
      session.title = _titleFrom(prompt);
    }
    session.model = state.model;
    session.effort = state.effort;
    session.permissionMode = state.permissionMode;

    final source = AgentCliSource(commandLog: commandLog);
    _runningSources[session.id] = source;
    emit(state.copyWith(
      sessions: isNewSession ? [session, ...state.sessions] : state.sessions,
      selectedSessionId: session.id,
      revision: state.revision + 1,
    ));

    // Не await: процесс живёт минуты, события приходят через add().
    source.start(
      binary: binary,
      prompt: prompt,
      model: state.model,
      effort: state.effort.name,
      permissionMode: state.permissionMode.flagValue,
      workingDirectory: workingDirectory,
      resumeSessionId: session.cliSessionId,
      onSessionId: (cliSessionId) =>
          add(_SessionCliIdReceived(session.id, cliSessionId)),
      onEvent: (agentEvent) =>
          add(_SessionEventReceived(session.id, agentEvent)),
      onDone: (status, duration) =>
          add(_SessionFinished(session.id, status, duration)),
    );
  }

  void _onCreated(SessionCreated event, Emitter<SessionsState> emit) {
    // Пустая сессия уже открыта — второй такой не нужно.
    final existingEmpty =
        state.sessions.where((session) => session.isEmpty).firstOrNull;
    if (existingEmpty != null) {
      emit(state.copyWith(selectedSessionId: existingEmpty.id));
      return;
    }
    final session = _newSession();
    emit(state.copyWith(
      sessions: [session, ...state.sessions],
      selectedSessionId: session.id,
    ));
  }

  void _onDeleted(SessionDeleted event, Emitter<SessionsState> emit) {
    _runningSources.remove(event.sessionId)?.stop();
    final remaining = state.sessions
        .where((session) => session.id != event.sessionId)
        .toList();
    emit(state.copyWith(
      sessions: remaining,
      selectedSessionId: state.selectedSessionId == event.sessionId
          ? (remaining.firstOrNull?.id ?? '')
          : state.selectedSessionId,
      revision: state.revision + 1,
    ));
  }

  void _onStopRequested(
      SessionStopRequested event, Emitter<SessionsState> emit) {
    _runningSources[state.selectedSessionId]?.stop();
  }

  void _onEventReceived(
      _SessionEventReceived event, Emitter<SessionsState> emit) {
    final session = _sessionById(event.sessionId);
    if (session == null) return;
    session.events.add(event.event);
    emit(state.copyWith(revision: state.revision + 1));
  }

  void _onCliIdReceived(
      _SessionCliIdReceived event, Emitter<SessionsState> emit) {
    _sessionById(event.sessionId)?.cliSessionId = event.cliSessionId;
  }

  void _onFinished(_SessionFinished event, Emitter<SessionsState> emit) {
    final session = _sessionById(event.sessionId);
    if (session == null) return;
    session.status = event.status;
    session.duration = event.duration;
    _runningSources.remove(event.sessionId);
    emit(state.copyWith(revision: state.revision + 1));
  }

  AgentSession _newSession() => AgentSession(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        title: '',
        startedAt: DateTime.now(),
        model: state.model,
        effort: state.effort,
        permissionMode: state.permissionMode,
      );

  String _titleFrom(String prompt) =>
      prompt.length > 60 ? '${prompt.substring(0, 60)}…' : prompt;

  AgentSession? _sessionById(String sessionId) =>
      state.sessions.where((session) => session.id == sessionId).firstOrNull;

  @override
  Future<void> close() {
    for (final source in _runningSources.values) {
      source.stop();
    }
    return super.close();
  }
}
