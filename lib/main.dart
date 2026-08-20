import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:window_manager/window_manager.dart';

import 'core/theme.dart';
import 'data/repositories/platform_repository_impl.dart';
import 'data/sources/platform_files_source.dart';
import 'domain/repositories/platform_repository.dart';
import 'presentation/bloc/console_bloc.dart';
import 'presentation/shell.dart';

final getIt = GetIt.instance;

void setupDi() {
  getIt.registerLazySingleton<PlatformRepository>(
      () => PlatformRepositoryImpl(PlatformFilesSource.locate()));
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();
  // Бриф §9: окно изменяемого размера, минимум ~1100×700.
  await windowManager.waitUntilReadyToShow(
    const WindowOptions(
      minimumSize: Size(1100, 700),
      size: Size(1280, 800),
      title: 'Platform Console',
      titleBarStyle: TitleBarStyle.normal,
    ),
    () async => windowManager.show(),
  );
  setupDi();
  runApp(const ConsoleApp());
}

class ConsoleApp extends StatelessWidget {
  const ConsoleApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Platform Console',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        home: BlocProvider(
          create: (_) => ConsoleBloc(getIt<PlatformRepository>()),
          child: const Shell(),
        ),
      );
}
