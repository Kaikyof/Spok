part of 'console_bloc.dart';

enum ConsoleScreen { group, changes, handoff, env, sessions }

enum LoadStatus { initial, loading, ready }

class ConsoleState {
  final LoadStatus status;
  final ConsoleScreen screen;
  final ConsoleSnapshot? snapshot;
  final String selectedGroupId;
  final ChangeUnit? selectedChange;
  final DocArtifact? selectedDoc;
  final String? docContent;

  /// Спека открытого change'а (`proposal.md`) — главный текст карточки.
  /// null — ещё читается или файла нет.
  final String? changeSpec;
  final bool pathRejected;

  /// Человек открыл подключение спеки из шапки — показываем экран настройки.
  final bool switchingSpec;

  /// Подключённые спеки: между ними переключаются из шапки.
  final List<String> knownSpecs;

  /// Форма ключей; null — не открыта или ещё читается с диска.
  final EnvForm? envForm;

  final bool envSaving;

  /// Выбранный стек; пусто — показываются все стеки спеки.
  final String stackFilter;

  final List<IssueComment>? comments; // null — ещё грузятся
  final List<MergeRequestInfo>? mergeRequests;
  final HandoffRecipients? recipients; // null — ещё не подбирали
  final String recipientsStack;
  final bool recipientsLoading;

  const ConsoleState({
    this.status = LoadStatus.initial,
    this.screen = ConsoleScreen.group,
    this.snapshot,
    this.selectedGroupId = '',
    this.selectedChange,
    this.selectedDoc,
    this.docContent,
    this.changeSpec,
    this.pathRejected = false,
    this.switchingSpec = false,
    this.knownSpecs = const [],
    this.envForm,
    this.envSaving = false,
    this.stackFilter = '',
    this.comments,
    this.mergeRequests,
    this.recipients,
    this.recipientsStack = '',
    this.recipientsLoading = false,
  });

  ProjectProfile get profile => snapshot?.profile ?? const ProjectProfile();

  /// Стеки спеки; пусто — работа без разделения на стеки.
  List<String> get stacks => profile.stacks;

  bool allowsStack(String stack) =>
      stackFilter.isEmpty || stackFilter == stack;

  /// Change'и выбранной группы: переключение группы меняет и список.
  List<ChangeUnit> get groupChanges {
    final all = snapshot?.changes ?? const <ChangeUnit>[];
    final current = group;
    if (current == null) return all;
    return [
      for (final id in current.changeIds)
        ...all.where((change) => change.id == id),
    ];
  }

  /// Нужен экран настройки: спека не найдена либо человек меняет её сам.
  bool get needsSetup =>
      snapshot?.redmineProblem == RedmineProblem.platformNotFound ||
      switchingSpec;

  /// Спека не найдена вовсе — отменить настройку некуда.
  bool get specMissing =>
      snapshot?.redmineProblem == RedmineProblem.platformNotFound;

  /// Первая загрузка ещё идёт — показываем полноэкранный лоадер.
  bool get isFirstLoad => snapshot == null;

  Group? get group {
    final current = snapshot;
    if (current == null || current.groups.isEmpty) return null;
    return current.groups.firstWhere(
        (candidate) => candidate.id == selectedGroupId,
        orElse: () => current.groups.first);
  }

  /// Стек, для которого собирается передача: выбранный либо первый.
  String get handoffStack =>
      stackFilter.isNotEmpty ? stackFilter : (stacks.firstOrNull ?? '');

  ConsoleState copyWith({
    LoadStatus? status,
    ConsoleScreen? screen,
    ConsoleSnapshot? snapshot,
    String? selectedGroupId,
    ChangeUnit? Function()? selectedChange,
    DocArtifact? Function()? selectedDoc,
    String? Function()? docContent,
    String? Function()? changeSpec,
    bool? pathRejected,
    bool? switchingSpec,
    List<String>? knownSpecs,
    EnvForm? Function()? envForm,
    bool? envSaving,
    String? stackFilter,
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
        selectedGroupId: selectedGroupId ?? this.selectedGroupId,
        selectedChange:
            selectedChange != null ? selectedChange() : this.selectedChange,
        selectedDoc: selectedDoc != null ? selectedDoc() : this.selectedDoc,
        docContent: docContent != null ? docContent() : this.docContent,
        changeSpec: changeSpec != null ? changeSpec() : this.changeSpec,
        pathRejected: pathRejected ?? this.pathRejected,
        switchingSpec: switchingSpec ?? this.switchingSpec,
        knownSpecs: knownSpecs ?? this.knownSpecs,
        envForm: envForm != null ? envForm() : this.envForm,
        envSaving: envSaving ?? this.envSaving,
        stackFilter: stackFilter ?? this.stackFilter,
        comments: comments != null ? comments() : this.comments,
        mergeRequests:
            mergeRequests != null ? mergeRequests() : this.mergeRequests,
        recipients: recipients != null ? recipients() : this.recipients,
        recipientsStack: recipientsStack ?? this.recipientsStack,
        recipientsLoading: recipientsLoading ?? this.recipientsLoading,
      );
}
