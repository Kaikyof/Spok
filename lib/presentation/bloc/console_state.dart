part of 'console_bloc.dart';

enum ConsoleScreen { sprint, changes, handoff, env, sessions }

enum LoadStatus { initial, loading, ready }

class ConsoleState {
  final LoadStatus status;
  final ConsoleScreen screen;
  final ConsoleSnapshot? snapshot;
  final String selectedSprintId;
  final ChangeUnit? selectedChange;
  final DocArtifact? selectedDoc;
  final String? docContent;

  const ConsoleState({
    this.status = LoadStatus.initial,
    this.screen = ConsoleScreen.sprint,
    this.snapshot,
    this.selectedSprintId = '',
    this.selectedChange,
    this.selectedDoc,
    this.docContent,
  });

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
      );
}
