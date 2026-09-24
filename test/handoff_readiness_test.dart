import 'package:flutter_test/flutter_test.dart';
import 'package:spok/domain/entities/change_unit.dart';
import 'package:spok/domain/entities/group.dart';
import 'package:spok/domain/entities/handoff_blocker.dart';
import 'package:spok/domain/entities/stack_state.dart';
import 'package:spok/domain/entities/status_semantics.dart';
import 'package:spok/domain/entities/task_item.dart';
import 'package:spok/domain/usecases/assess_handoff_readiness.dart';

/// Спека объявила статус передачи — без него шаг «Готовность» вообще
/// не считается, а экран передачи закрыт воротами фичи.
const _semantics = StatusSemantics(statuses: [
  TrackerStatus(id: 7, name: 'Ожидает тестирования'),
  TrackerStatus(id: 3, name: 'В работе'),
]);

const _group = Group(id: 'sp-1', title: 'Спринт 1', kind: GroupingKind.sprintDir);

ChangeUnit _change({String? cachedStatus, String? liveStatus}) {
  final stack = StackState(
    stack: 'backend',
    tasks: const [TaskItem('1.1', 'Шаг', true)],
    cachedStatus: cachedStatus,
  );
  stack.liveStatus = liveStatus;
  return ChangeUnit(
      id: 'mtm-03',
      title: 'Рассылка',
      dir: '/tmp',
      stackStates: {'backend': stack});
}

void main() {
  HandoffReadiness assess(ChangeUnit change) => AssessHandoffReadiness()(
        group: _group,
        changes: [change],
        semantics: _semantics,
        stackVisible: (_) => true,
      );

  group('Готовность к передаче', () {
    test('статус не опрошен и кэша нет — блокер, а не молчаливое «готово»',
        () {
      final readiness = assess(_change());

      expect(readiness.blockers.map((blocker) => blocker.kind),
          contains(HandoffBlockerKind.statusUnknown));
      // Главное: такой стек не уезжает в готовые.
      expect(readiness.readyCount, 0);
      expect(readiness.ready, isFalse);
      expect(readiness.statusUnknown, isTrue);
    });

    test('статус из файла спеки — трекер спрашивать незачем', () {
      final readiness = assess(_change(cachedStatus: 'Ожидает тестирования'));

      expect(readiness.blockers, isEmpty);
      expect(readiness.readyCount, 1);
      expect(readiness.statusUnknown, isFalse);
    });

    test('живой статус не тот — прежний блокер остался на месте', () {
      final readiness = assess(_change(liveStatus: 'В работе'));

      expect(readiness.blockers.single.kind,
          HandoffBlockerKind.statusNotReady);
      expect(readiness.statusUnknown, isFalse);
      expect(readiness.readyCount, 0);
    });

    test('живой статус перебивает устаревший кэш', () {
      final readiness = assess(
          _change(cachedStatus: 'В работе', liveStatus: 'Ожидает тестирования'));

      expect(readiness.blockers, isEmpty);
      expect(readiness.readyCount, 1);
    });
  });
}
