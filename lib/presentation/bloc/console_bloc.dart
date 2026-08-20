import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/change_unit.dart';
import '../../domain/entities/console_snapshot.dart';
import '../../domain/entities/doc_artifact.dart';
import '../../domain/entities/sprint.dart';
import '../../domain/repositories/platform_repository.dart';

part 'console_event.dart';
part 'console_state.dart';

class ConsoleBloc extends Bloc<ConsoleEvent, ConsoleState> {
  final PlatformRepository repository;

  ConsoleBloc(this.repository) : super(const ConsoleState()) {
    on<ConsoleRefreshed>(_onRefresh);
    on<ScreenSelected>(
        (event, emit) => emit(state.copyWith(screen: event.screen)));
    on<SprintSelected>(
        (event, emit) => emit(state.copyWith(selectedSprintId: event.sprintId)));
    on<ChangeOpened>((event, emit) => emit(state.copyWith(
          screen: ConsoleScreen.changes,
          selectedChange: () => event.change,
          selectedDoc: () => null,
          docContent: () => null,
        )));
    on<DocOpened>(_onDocOpened);
    add(ConsoleRefreshed());
  }

  Future<void> _onRefresh(
      ConsoleRefreshed event, Emitter<ConsoleState> emit) async {
    emit(state.copyWith(status: LoadStatus.loading));
    final snapshot = await repository.load();
    // Change'и пересозданы заново — найдём выбранный в свежем слепке.
    final keptChange = snapshot.changes
        .where((change) => change.id == state.selectedChange?.id)
        .firstOrNull;
    emit(state.copyWith(
      status: LoadStatus.ready,
      snapshot: snapshot,
      selectedChange: () => keptChange,
    ));
  }

  Future<void> _onDocOpened(
      DocOpened event, Emitter<ConsoleState> emit) async {
    final doc = event.doc;
    if (doc == null) {
      emit(state.copyWith(selectedDoc: () => null, docContent: () => null));
      return;
    }
    String? content;
    try {
      content = await repository.readDoc(doc.path);
    } catch (_) {
      content = null; // экран покажет локализованную ошибку
    }
    emit(state.copyWith(selectedDoc: () => doc, docContent: () => content));
  }
}
