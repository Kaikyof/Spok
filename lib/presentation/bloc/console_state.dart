part of 'console_bloc.dart';

enum ConsoleScreen { sprint, changes, handoff, env, sessions }

enum LoadStatus { initial, loading, ready }

/// Фильтр стеков: искать только iOS- или только Android-задачи.
enum StackFilter {
  all,
  ios,
  android;

  bool allows(String stack) => this == all || name == stack;
}

class ConsoleState {
  final LoadStatus status;
  final ConsoleScreen screen;
  final ConsoleSnapshot? snapshot;
  final String selectedSprintId;
  final ChangeUnit? selectedChange;
  final DocArtifact? selectedDoc;
  final String? docContent;
  final bool pathRejected;
  final StackFilter stackFilter;
  final List<IssueComment>? comments; // null — ещё грузятся
  final List<MergeRequestInfo>? mergeRequests;
  final HandoffRecipients? recipients; // null — ещё не подбирали
  final String recipientsStack;
  final bool recipientsLoading;

  const ConsoleState({
    this.status = LoadStatus.initial,
    this.screen = ConsoleScreen.sprint,
    this.snapshot,
    this.selectedSprintId = '',
    this.selectedChange,
    this.selectedDoc,
    this.docContent,
    this.pathRejected = false,
    this.stackFilter = StackFilter.all,
    this.comments,
    this.mergeRequests,
    this.recipients,
    this.recipientsStack = '',
    this.recipientsLoading = false,
  });

  /// Платформа не найдена — нужен экран первичной настройки.
  bool get needsSetup =>
      snapshot?.redmineProblem == RedmineProblem.platformNotFound;

  /// Первая загрузка ещё идёт — показываем полноэкранный лоадер.
  bool get isFirstLoad => snapshot == null;

  Sprint? get sprint {
    final current = snapshot;
    if (current == null || current.sprints.isEmpty) return null;
    return current.sprints.firstWhere(
        (candidate) => candidate.id == selectedSprintId,
        orElse: () => current.sprints.first);
  }

  ConsoleState copyWith({
    LoadStatus? status,
    ConsoleScreen? screen,
    ConsoleSnapshot? snapshot,
    String? selectedSprintId,
    ChangeUnit? Function()? selectedChange,
    DocArtifact? Function()? selectedDoc,
    String? Function()? docContent,
    bool? pathRejected,
    StackFilter? stackFilter,
    List<IssueComment>? Function()? comments,
    List<MergeRequestInfo>? Function()? mergeRequests,
    HandoffRecipients? Function()? recipients,
    String? recipientsStack,
    bool? recipientsLoading,
  }) =>
      ConsoleState(
        status: status ?? this.status,
        screen: screen ?? this.screen,
        snapshot: snapshot ?? this.snapshot,
        selectedSprintId: selectedSprintId ?? this.selectedSprintId,
        selectedChange:
            selectedChange != null ? selectedChange() : this.selectedChange,
        selectedDoc: selectedDoc != null ? selectedDoc() : this.selectedDoc,
        docContent: docContent != null ? docContent() : this.docContent,
        pathRejected: pathRejected ?? this.pathRejected,
        stackFilter: stackFilter ?? this.stackFilter,
        comments: comments != null ? comments() : this.comments,
        mergeRequests:
            mergeRequests != null ? mergeRequests() : this.mergeRequests,
        recipients: recipients != null ? recipients() : this.recipients,
        recipientsStack: recipientsStack ?? this.recipientsStack,
        recipientsLoading: recipientsLoading ?? this.recipientsLoading,
      );
}
