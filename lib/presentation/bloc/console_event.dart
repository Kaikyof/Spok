part of 'console_bloc.dart';

sealed class ConsoleEvent {}

class ConsoleRefreshed extends ConsoleEvent {}

class ScreenSelected extends ConsoleEvent {
  final ConsoleScreen screen;
  ScreenSelected(this.screen);
}

class SprintSelected extends ConsoleEvent {
  final String sprintId;
  SprintSelected(this.sprintId);
}

class ChangeOpened extends ConsoleEvent {
  final ChangeUnit? change;
  ChangeOpened(this.change);
}

class DocOpened extends ConsoleEvent {
  final DocArtifact? doc;
  DocOpened(this.doc);
}

class PlatformPathSubmitted extends ConsoleEvent {
  final String path;
  PlatformPathSubmitted(this.path);
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

class StackFilterChanged extends ConsoleEvent {
  final StackFilter filter;
  StackFilterChanged(this.filter);
}
