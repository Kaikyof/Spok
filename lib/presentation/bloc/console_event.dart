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
