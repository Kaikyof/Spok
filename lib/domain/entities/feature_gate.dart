/// Природа нехватки. Путать их нельзя: иначе человек пойдёт править общий
/// файл спеки там, где ему надо просто ввести свой ключ.
enum RequirementScope {
  /// Не предусмотрено процессом спеки — правится через её шаблоны и команды.
  spec,

  /// Не настроено на этой машине — правится за полминуты в форме ключей.
  personal,

  /// Настроено, но система не отвечает или отклонила ключ.
  runtime,
}

/// Что именно ищет приложение. Id — код, текст даёт локализация.
enum RequirementId {
  grouping,
  statusSemantics,
  buildsFile,
  handoverCommand,
  recipientsScript,
  gitlabTokenDeclared,
  gitlabTokenFilled,
  gitlabReachable,
  services,
  chatKeysDeclared,
  chatKeysFilled,
  stacks,
}

/// Одно требование фичи: выполнено ли и где искали.
class FeatureRequirement {
  final RequirementId id;
  final RequirementScope scope;
  final bool satisfied;

  /// Без него фича работает, но часть экрана гаснет.
  final bool optional;

  /// Где искали — путь, ключ или источник; показывается рядом.
  final String lookedIn;

  /// Подробность отказа: код ответа, хост, имя ключа.
  final String detail;

  const FeatureRequirement({
    required this.id,
    required this.scope,
    required this.satisfied,
    this.optional = false,
    this.lookedIn = '',
    this.detail = '',
  });
}

/// Фича и её требования. Экран не прячется — он объясняет, чего не хватает.
class FeatureGate {
  final List<FeatureRequirement> requirements;

  const FeatureGate(this.requirements);

  static const empty = FeatureGate([]);

  List<FeatureRequirement> get mandatory =>
      [for (final r in requirements) if (!r.optional) r];

  List<FeatureRequirement> get optional =>
      [for (final r in requirements) if (r.optional) r];

  bool get available => mandatory.every((r) => r.satisfied);

  /// Сколько требований не выполнено — счётчик в навигации.
  int get unmetCount => requirements.where((r) => !r.satisfied).length;

  int get satisfiedCount => requirements.where((r) => r.satisfied).length;

  /// Первое невыполненное обязательное — им объясняется отказ.
  FeatureRequirement? get blocker =>
      mandatory.where((r) => !r.satisfied).firstOrNull;
}
