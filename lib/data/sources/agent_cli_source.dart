import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../domain/entities/agent_session.dart';
import '../../domain/repositories/command_log.dart';
import 'executable_locator.dart';

/// Запуск Claude Code как дочернего процесса в headless-режиме
/// (`claude -p --output-format stream-json`) и разбор его событий.
/// Приложение не прячет механику: сессия работает в репозитории платформы
/// под ключами и правами пользователя.
class AgentCliSource {
  final CommandLog? commandLog;
  Process? _process;

  AgentCliSource({this.commandLog});

  /// Путь к CLI агента. Хардкода `/opt/homebrew/bin/claude` здесь нет:
  /// на Linux его нет вовсе, а на macOS установка может быть и в volta,
  /// и в nvm. Ищет [ExecutableLocator] — он же знает, что запуск из
  /// Finder приходит с урезанным PATH.
  static String? locateBinary() => ExecutableLocator.locate('claude');

  bool get isRunning => _process != null;

  /// Запускает или продолжает сессию.
  /// [resumeSessionId] — id разговора Claude Code: с ним сообщение уходит
  /// в тот же диалог, без него начинается новый.
  /// [onSessionId] возвращает id, присвоенный CLI, чтобы продолжить позже.
  Future<void> start({
    required String binary,
    required String prompt,
    required String model,
    required String effort,
    String? permissionMode,
    required String workingDirectory,
    String? resumeSessionId,
    required void Function(String sessionId) onSessionId,
    required void Function(AgentEvent event) onEvent,
    required void Function(AgentSessionStatus status, Duration duration) onDone,
  }) async {
    final startedAt = DateTime.now();
    final arguments = [
      '-p', prompt,
      '--output-format', 'stream-json',
      '--verbose',
      '--model', model,
      '--effort', effort,
      if (permissionMode != null) ...['--permission-mode', permissionMode],
      if (resumeSessionId != null) ...['--resume', resumeSessionId],
    ];
    // Команда всегда видна: её можно скопировать и выполнить руками (бриф §3.5).
    final run = commandLog?.begin('claude ${arguments.join(' ')}');
    final transcript = StringBuffer();
    final process = await Process.start(
      binary,
      arguments,
      workingDirectory: workingDirectory,
    );
    _process = process;
    // CLI ждёт данные на stdin и предупреждает, если их нет: промпт передан
    // аргументом, поэтому вход закрываем сразу.
    await process.stdin.close();

    process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) => _parseLine(line, onEvent, onSessionId));
    process.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) {
      if (line.trim().isNotEmpty) {
        transcript.writeln(line);
        onEvent(AgentEvent(AgentEventKind.error, line));
      }
    });

    final exitCode = await process.exitCode;
    final wasStopped = _process == null;
    _process = null;
    if (run != null) {
      commandLog?.complete(run,
          output: transcript.toString().trim(), exitCode: exitCode);
    }
    onDone(
      wasStopped
          ? AgentSessionStatus.stopped
          : (exitCode == 0
              ? AgentSessionStatus.done
              : AgentSessionStatus.failed),
      DateTime.now().difference(startedAt),
    );
  }

  void stop() {
    final process = _process;
    _process = null;
    process?.kill();
  }

  void _parseLine(
    String line,
    void Function(AgentEvent event) onEvent,
    void Function(String sessionId) onSessionId,
  ) {
    if (line.trim().isEmpty) return;
    dynamic json;
    try {
      json = jsonDecode(line);
    } catch (_) {
      return; // служебный вывод, не событие
    }
    switch (json['type']) {
      case 'system':
        final sessionId = json['session_id']?.toString();
        if (json['subtype'] == 'init' && sessionId != null) {
          onSessionId(sessionId);
        }
      case 'assistant':
        _parseAssistantMessage(json['message'], onEvent);
      case 'result':
        final resultText = json['result']?.toString() ?? '';
        if (resultText.isNotEmpty) {
          onEvent(AgentEvent(AgentEventKind.result, resultText));
        }
    }
  }

  void _parseAssistantMessage(
      dynamic message, void Function(AgentEvent event) onEvent) {
    final content = message?['content'];
    if (content is! List) return;
    for (final block in content) {
      switch (block['type']) {
        case 'text':
          final text = block['text']?.toString().trim() ?? '';
          if (text.isNotEmpty) {
            onEvent(AgentEvent(AgentEventKind.assistantText, text));
          }
        case 'tool_use':
          onEvent(AgentEvent(
            AgentEventKind.toolAction,
            _toolSummary(block['name']?.toString() ?? '', block['input']),
            toolName: block['name']?.toString() ?? '',
          ));
      }
    }
  }

  /// Короткая строка о вызове инструмента — как в панели «выполнено по ходу».
  String _toolSummary(String toolName, dynamic input) {
    if (input is! Map) return toolName;
    final detail = input['command'] ??
        input['file_path'] ??
        input['pattern'] ??
        input['query'] ??
        input['url'] ??
        '';
    final detailText = detail.toString();
    if (detailText.isEmpty) return toolName;
    return '$toolName  ${detailText.length > 80 ? '${detailText.substring(0, 80)}…' : detailText}';
  }
}
