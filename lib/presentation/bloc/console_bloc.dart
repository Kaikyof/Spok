import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/change_unit.dart';
import '../../domain/entities/console_snapshot.dart';
import '../../domain/entities/doc_artifact.dart';
import '../../domain/entities/env_field.dart';
import '../../domain/entities/handoff_recipient.dart';
import '../../domain/entities/issue_comment.dart';
import '../../domain/entities/merge_request_info.dart';
import '../../domain/entities/group.dart';
import '../../domain/entities/project_profile.dart';
import '../../domain/repositories/platform_repository.dart';

part 'console_event.dart';
part 'console_state.dart';

class ConsoleBloc extends Bloc<ConsoleEvent, ConsoleState> {
  final PlatformRepository repository;

  ConsoleBloc(this.repository) : super(const ConsoleState()) {
    on<ConsoleRefreshed>(_onRefresh);
    on<ScreenSelected>(
        (event, emit) => emit(state.copyWith(screen: event.screen)));
    // Смена группы меняет и состав работы: открытая карточка change'а,
    // её спека, комментарии, MR и подобранные получатели — из прежней
    // группы, и показывать их дальше значило бы врать.
    on<GroupSelected>((event, emit) => emit(state.copyWith(
          selectedGroupId: event.groupId,
          selectedChange: () => null,
          selectedDoc: () => null,
          docContent: () => null,
          changeSpec: () => null,
          comments: () => null,
          mergeRequests: () => null,
          recipients: () => null,
          recipientsStack: '',
          recipientsLoading: false,
        )));
    on<ChangeOpened>(_onChangeOpened);
    on<_ChangeSpecLoaded>((event, emit) =>
        emit(state.copyWith(changeSpec: () => event.content)));
    on<_CommentsLoaded>((event, emit) =>
        emit(state.copyWith(comments: () => event.comments)));
    on<_MergeRequestsLoaded>((event, emit) =>
        emit(state.copyWith(mergeRequests: () => event.mergeRequests)));
    on<RecipientsRequested>(_onRecipientsRequested);
    on<_RecipientsLoaded>((event, emit) => emit(state.copyWith(
          recipients: () => event.recipients,
          recipientsStack: event.stack,
          recipientsLoading: false,
        )));
    on<EnvFormRequested>(_onEnvFormRequested);
    on<_EnvFormLoaded>(
        (event, emit) => emit(state.copyWith(envForm: () => event.form)));
    on<EnvSaved>(_onEnvSaved);
    on<DocOpened>(_onDocOpened);
    on<PlatformPathSubmitted>(_onPathSubmitted);
    on<SpecSwitchRequested>((event, emit) => emit(
        state.copyWith(switchingSpec: event.open, pathRejected: false)));
    on<StackFilterChanged>(
        (event, emit) => emit(state.copyWith(stackFilter: event.stack)));
    add(ConsoleRefreshed());
  }

  Future<void> _onPathSubmitted(
      PlatformPathSubmitted event, Emitter<ConsoleState> emit) async {
    final accepted = await repository.setPlatformDir(event.path);
    if (!accepted) {
      emit(state.copyWith(pathRejected: true));
      return;
    }
    // Спека сменилась — выбранные группа, change и стек относились к старой.
    emit(ConsoleState(screen: state.screen));
    add(ConsoleRefreshed());
  }

  Future<void> _onRefresh(
      ConsoleRefreshed event, Emitter<ConsoleState> emit) async {
    emit(state.copyWith(status: LoadStatus.loading));
    final snapshot = await repository.load();
    final knownSpecs = await repository.knownSpecs();
    // Change'и пересозданы заново — найдём выбранный в свежем слепке.
    final keptChange = snapshot.changes
        .where((change) => change.id == state.selectedChange?.id)
        .firstOrNull;
    emit(state.copyWith(
      status: LoadStatus.ready,
      snapshot: snapshot,
      knownSpecs: knownSpecs,
      selectedChange: () => keptChange,
    ));
  }

  Future<void> _onChangeOpened(
      ChangeOpened event, Emitter<ConsoleState> emit) async {
    emit(state.copyWith(
      screen: ConsoleScreen.changes,
      selectedChange: () => event.change,
      selectedDoc: () => null,
      docContent: () => null,
      changeSpec: () => null,
      comments: () => null,
      mergeRequests: () => null,
    ));
    final change = event.change;
    if (change == null) return;
    // Главный текст карточки — спека изменения, а не список задач:
    // сначала «что меняем и зачем», потом «что осталось сделать».
    final specPath = state.profile.schema.specPathFor(change.dir);
    if (specPath != null) {
      unawaited(repository.readDoc(specPath).then((content) {
        if (isClosed || state.selectedChange?.id != change.id) return;
        add(_ChangeSpecLoaded(content));
      }).catchError((_) {}));
    }
    // Лента комментариев — там общаются разработчик и тестировщик (бриф §5.2),
    // MR — ярлык GitLab рядом с фактом влития (бриф §3.2).
    final issueIds =
        change.stacks.map((stack) => stack.issueId).nonNulls.toList();
    unawaited(repository.issueComments(issueIds).then((comments) {
      if (isClosed || state.selectedChange?.id != change.id) return;
      add(_CommentsLoaded(comments));
    }));
    unawaited(repository
        .mergeRequests(change.id, groupId: state.group?.id ?? '')
        .then((mergeRequests) {
      if (isClosed || state.selectedChange?.id != change.id) return;
      add(_MergeRequestsLoaded(mergeRequests));
    }));
  }

  /// Получателей подбирает скрипт платформы — он ходит в Redmine
  /// и Mattermost, поэтому запускаем по запросу экрана, а не при refresh.
  Future<void> _onRecipientsRequested(
      RecipientsRequested event, Emitter<ConsoleState> emit) async {
    if (state.recipientsLoading && state.recipientsStack == event.stack) return;
    emit(state.copyWith(recipientsLoading: true, recipientsStack: event.stack));
    final recipients = await repository.handoffRecipients(event.stack);
    if (isClosed) return;
    add(_RecipientsLoaded(event.stack, recipients));
  }

  /// Форма читается с диска при каждом открытии: .env могли поправить
  /// руками или другой сессией.
  Future<void> _onEnvFormRequested(
      EnvFormRequested event, Emitter<ConsoleState> emit) async {
    emit(state.copyWith(envForm: () => null));
    final form = await repository.envForm();
    if (isClosed) return;
    add(_EnvFormLoaded(form));
  }

  Future<void> _onEnvSaved(EnvSaved event, Emitter<ConsoleState> emit) async {
    emit(state.copyWith(envSaving: true));
    await repository.saveEnv(event.values);
    emit(state.copyWith(envSaving: false, envForm: () => null));
    // Проверки окружения и статусы Redmine зависят от ключей — пересобираем.
    add(ConsoleRefreshed());
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
