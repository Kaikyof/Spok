import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/entities.dart';
import '../../domain/entities/snapshot.dart';
import '../../domain/repositories/platform_repository.dart';

enum ConsoleScreen { sprint, changes, handoff, env, sessions }

enum LoadStatus { initial, loading, ready }

// ─── События ─────────────────────────────────────────────────────────────────

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

// ─── Состояние ───────────────────────────────────────────────────────────────

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
    final s = snapshot;
    if (s == null || s.sprints.isEmpty) return null;
    return s.sprints.firstWhere((e) => e.id == selectedSprintId,
        orElse: () => s.sprints.first);
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

// ─── Блок ────────────────────────────────────────────────────────────────────

class ConsoleBloc extends Bloc<ConsoleEvent, ConsoleState> {
  final PlatformRepository repo;

  ConsoleBloc(this.repo) : super(const ConsoleState()) {
    on<ConsoleRefreshed>(_onRefresh);
    on<ScreenSelected>((e, emit) => emit(state.copyWith(screen: e.screen)));
    on<SprintSelected>(
        (e, emit) => emit(state.copyWith(selectedSprintId: e.sprintId)));
    on<ChangeOpened>((e, emit) => emit(state.copyWith(
          screen: ConsoleScreen.changes,
          selectedChange: () => e.change,
          selectedDoc: () => null,
          docContent: () => null,
        )));
    on<DocOpened>(_onDocOpened);
    add(ConsoleRefreshed());
  }

  Future<void> _onRefresh(
      ConsoleRefreshed e, Emitter<ConsoleState> emit) async {
    emit(state.copyWith(status: LoadStatus.loading));
    final snapshot = await repo.load();
    // Выбранный change пересоздан заново — найдём его в свежем слепке.
    final keptChange = snapshot.changes
        .where((c) => c.id == state.selectedChange?.id)
        .firstOrNull;
    emit(state.copyWith(
      status: LoadStatus.ready,
      snapshot: snapshot,
      selectedChange: () => keptChange,
    ));
  }

  Future<void> _onDocOpened(DocOpened e, Emitter<ConsoleState> emit) async {
    final doc = e.doc;
    if (doc == null) {
      emit(state.copyWith(selectedDoc: () => null, docContent: () => null));
      return;
    }
    String content;
    try {
      content = await repo.readDoc(doc.path);
    } catch (err) {
      content = 'Не удалось прочитать файл:\n\n$err';
    }
    emit(state.copyWith(
        selectedDoc: () => doc, docContent: () => content));
  }
}
