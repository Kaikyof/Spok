part of 'console_bloc.dart';

sealed class ConsoleEvent {}

class ConsoleRefreshed extends ConsoleEvent {}

class ScreenSelected extends ConsoleEvent {
  final ConsoleScreen screen;
  ScreenSelected(this.screen);
}

class GroupSelected extends ConsoleEvent {
  final String groupId;
  GroupSelected(this.groupId);
}

class ChangeOpened extends ConsoleEvent {
  final ChangeUnit? change;
  ChangeOpened(this.change);
}

/// Прочитана спека открытого change'а.
class _ChangeSpecLoaded extends ConsoleEvent {
  final String? content;
  _ChangeSpecLoaded(this.content);
}

class DocOpened extends ConsoleEvent {
  final DocArtifact? doc;
  DocOpened(this.doc);
}

/// Открыть документ на экране «Документы».
class DocsFileOpened extends ConsoleEvent {
  final DocArtifact doc;
  DocsFileOpened(this.doc);
}

class _DocsFileLoaded extends ConsoleEvent {
  final String path;
  final String? content;
  final DocState state;
  _DocsFileLoaded(this.path, this.content, this.state);
}

/// Свернуть или развернуть узел дерева документов.
class DocsNodeToggled extends ConsoleEvent {
  final String nodeId;
  DocsNodeToggled(this.nodeId);
}

/// Открыть или закрыть экран смены спеки.
class SpecSwitchRequested extends ConsoleEvent {
  final bool open;
  SpecSwitchRequested(this.open);
}

class PlatformPathSubmitted extends ConsoleEvent {
  final String path;
  PlatformPathSubmitted(this.path);
}

/// Открыть форму ключей: значения читаются с диска при каждом открытии.
class EnvFormRequested extends ConsoleEvent {}

class _EnvFormLoaded extends ConsoleEvent {
  final EnvForm form;
  _EnvFormLoaded(this.form);
}

/// Сохранить значения в .env спеки.
class EnvSaved extends ConsoleEvent {
  final Map<String, String> values;
  EnvSaved(this.values);
}

class _CommentsLoaded extends ConsoleEvent {
  final List<IssueComment> comments;
  _CommentsLoaded(this.comments);
}

class _MergeRequestsLoaded extends ConsoleEvent {
  final List<MergeRequestInfo> mergeRequests;
  _MergeRequestsLoaded(this.mergeRequests);
}

/// Подобрать получателей для стека (скрипт платформы).
class RecipientsRequested extends ConsoleEvent {
  final String stack;
  RecipientsRequested(this.stack);
}

class _RecipientsLoaded extends ConsoleEvent {
  final String stack;
  final HandoffRecipients recipients;
  _RecipientsLoaded(this.stack, this.recipients);
}

/// Выбран стек; пустая строка — показывать все.
class StackFilterChanged extends ConsoleEvent {
  final String stack;
  StackFilterChanged(this.stack);
}
