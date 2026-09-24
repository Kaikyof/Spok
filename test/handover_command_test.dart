import 'package:flutter_test/flutter_test.dart';
import 'package:spok/domain/entities/slash_command.dart';
import 'package:spok/domain/usecases/build_handover_command.dart';

void main() {
  const build = BuildHandoverCommand();

  test('команда собирается по сигнатуре самой спеки, а не по образцу avtoto',
      () {
    const command = SlashCommand(
      id: 'opsx-sprint',
      description: '',
      argumentHint: '[sprint] [status|build|handover|finish] [--stack ios|android]',
    );

    expect(build(command, groupId: 'sp-12', stack: 'android'),
        '/opsx-sprint sp-12 handover --stack android');
  });

  test('без стеков флага в команде нет', () {
    const command = SlashCommand(
      id: 'opsx-sprint',
      description: '',
      argumentHint: '[sprint] [status|handover] [--stack ios|android]',
    );

    expect(build(command, groupId: 'sp-12'), '/opsx-sprint sp-12 handover');
  });

  test('имя команды чужой спеки не подменяется нашим', () {
    const command = SlashCommand(
      id: 'release-handover',
      description: '',
      argumentHint: '[group]',
    );

    expect(build(command, groupId: 'block-3', stack: 'backend'),
        '/release-handover block-3');
  });

  test('скрипт вызывается своей строкой запуска, а не как слэш-команда', () {
    const command = SlashCommand(
      id: 'handover',
      description: '',
      argumentHint: '[group]',
      source: CommandSource.packageScript,
      runLine: 'pnpm run handover',
    );

    expect(build(command, groupId: 'sp-1'), 'pnpm run handover sp-1');
  });
}
