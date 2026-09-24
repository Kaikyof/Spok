import 'feature_gate.dart';
import 'group.dart';
import 'spec_recognition.dart';
import 'spec_schema.dart';
import 'status_semantics.dart';

/// Фича приложения, которая может быть недоступна этой спеке.
enum SpecFeature { builds, handoff, mergeRequests, chat, multiStack }

/// Сервис спеки: репозиторий кода и его страница в хостинге.
typedef SpecService = ({String name, String stack, String webUrl});

/// Что приложение распознало в спеке: схема, статусы, группировка, фичи.
/// Экраны не исчезают — они объясняют, чего не хватает.
class ProjectProfile {
  final SpecSchema schema;
  final StatusSemantics statuses;
  final GroupingKind grouping;
  final List<String> stacks;
  final List<SpecService> services;

  /// Требования каждой фичи: выполнено — фича работает, нет — экран
  /// объясняет, чего не хватает.
  final Map<SpecFeature, FeatureGate> features;

  /// Что понято в устройстве спеки и что нет. Нераспознанное показывается
  /// человеку, а не заметается под ковёр.
  final SpecRecognition recognition;

  const ProjectProfile({
    this.schema = SpecSchema.empty,
    this.statuses = StatusSemantics.empty,
    this.grouping = GroupingKind.none,
    this.stacks = const [],
    this.services = const [],
    this.features = const {},
    this.recognition = SpecRecognition.empty,
  });

  /// Страница ветки в хостинге кода: собирается из адреса репозитория,
  /// поэтому работает и без токена API.
  String? branchUrl(String stack, String branch) {
    final service = services
            .where((candidate) => candidate.stack == stack)
            .firstOrNull ??
        services.firstOrNull;
    final webUrl = service?.webUrl ?? '';
    return webUrl.isEmpty ? null : '$webUrl/-/tree/$branch';
  }

  FeatureGate gate(SpecFeature feature) =>
      features[feature] ?? FeatureGate.empty;

  bool enabled(SpecFeature feature) => gate(feature).available;

  /// Сколько требований фичи не выполнено — бейдж у пункта навигации.
  int unmetCount(SpecFeature feature) => gate(feature).unmetCount;

  /// Переключатель стеков рисуется только при двух и более стеках.
  bool get showStackFilter => stacks.length >= 2;
}
