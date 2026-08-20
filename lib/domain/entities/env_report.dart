import 'env_check.dart';

class EnvReport {
  final List<EnvCheck> keys;
  final List<EnvCheck> repos;
  final List<EnvCheck> systems;

  const EnvReport({
    required this.keys,
    required this.repos,
    required this.systems,
  });

  List<EnvCheck> get all => [...keys, ...repos, ...systems];

  int get problemCount =>
      all.where((check) => check.level != CheckLevel.ok).length;
}
