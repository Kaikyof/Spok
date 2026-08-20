import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:window_manager/window_manager.dart';

import 'core/resources/app_dimens.dart';
import 'core/theme/app_theme.dart';
import 'data/repositories/platform_repository_impl.dart';
import 'domain/repositories/platform_repository.dart';
import 'l10n/gen/app_localizations.dart';
import 'presentation/bloc/console_bloc.dart';
import 'presentation/bloc/sessions_bloc.dart';
import 'presentation/shell.dart';

final getIt = GetIt.instance;

Future<void> setupDi() async {
  final repository = await PlatformRepositoryImpl.create();
  getIt.registerSingleton<PlatformRepository>(repository);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();
  // Бриф §9: окно изменяемого размера, минимум ~1100×700.
  await windowManager.waitUntilReadyToShow(
    const WindowOptions(
      minimumSize: AppDimens.minWindowSize,
      size: AppDimens.defaultWindowSize,
      title: 'Platform Console',
      titleBarStyle: TitleBarStyle.normal,
    ),
    () async => windowManager.show(),
  );
  await setupDi();
  runApp(const ConsoleApp());
}

class ConsoleApp extends StatelessWidget {
  const ConsoleApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Platform Console',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ru'),
        home: MultiBlocProvider(
          providers: [
            BlocProvider(
                create: (_) => ConsoleBloc(getIt<PlatformRepository>())),
            BlocProvider(
                create: (_) => SessionsBloc(getIt<PlatformRepository>())),
          ],
          child: const Shell(),
        ),
      );
}
