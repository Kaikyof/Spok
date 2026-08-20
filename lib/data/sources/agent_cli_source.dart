import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../domain/entities/agent_session.dart';

/// Запуск Claude Code как дочернего процесса в headless-режиме
/// (`claude -p --output-format stream-json`) и разбор его событий.
/// Приложение не прячет механику: сессия работает в репозитории платформы
/// под ключами и правами пользователя.
class AgentCliSource {
  static const _binaryCandidates = [
    '/opt/homebrew/bin/claude',
    '/usr/local/bin/claude',
  ];

  Process? _process;

  static String? locateBinary() {
    for (final candidate in _binaryCandidates) {
      if (File(candidate).existsSync()) return candidate;
    }
    return null;
  }

  bool get isRunning => _process != null;

  /// Запускает сессию; события транскрипта приходят в [onEvent],
  /// по завершении вызывается [onDone].
  Future<void> start({
    required String binary,
    required String prompt,
    required String model,
    required String workingDirectory,
    required void Function(AgentEvent event) onEvent,
    required void Function(AgentSessionStatus status, Duration duration)
        onDone,
  }) async {
    final startedAt = DateTime.now();
    final process = await Process.start(
      binary,
      [
        '-p', prompt,
        '--output-format', 'stream-json',
        '--verbose',
        '--model', model,
      ],
      workingDirectory: workingDirectory,
    );
    _process = process;

    process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) => _parseLine(line, onEvent));
    process.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) {
      if (line.trim().isNotEmpty) {
        onEvent(AgentEvent(AgentEventKind.error, line));
      }
    });

    final exitCode = await process.exitCode;
    final wasStopped = _process == null;
    _process = null;
    onDone(
      wasStopped
          ? AgentSessionStatus.stopped
          : (exitCode == 0 ? AgentSessionStatus.done : AgentSessionStatus.failed),
      DateTime.now().difference(startedAt),
    );
  }

  void stop() {
    final process = _process;
    _process = null;
    process?.kill();
  }

  void _parseLine(String line, void Function(AgentEvent event) onEvent) {
    if (line.trim().isEmpty) return;
    dynamic json;
    try {
      json = jsonDecode(line);
    } catch (_) {
      return; // служебный вывод, не событие
    }
    switch (json['type']) {
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
