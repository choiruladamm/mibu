import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'l10n/app_localizations.dart';
import 'routing/router.dart';
import 'ui/core/finance_providers.dart';
import 'ui/features/home/view_models/home_view_model.dart';
import 'ui/core/theme.dart';
import 'ui/core/widgets/tap_outside_unfocus.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final container = ProviderContainer();
  // Open (and, in debug, seed) the database and load beranda while the user
  // is still on onboarding, so "mulai" lands on a ready screen.
  container.read(homeProvider);
  // The router picks onboarding vs beranda from it (native splash still up).
  await container.read(profileProvider.future);
  runApp(
    UncontrolledProviderScope(container: container, child: const MibuApp()),
  );
}

class MibuApp extends ConsumerWidget {
  const MibuApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TapOutsideUnfocus(
      child: MaterialApp.router(
        onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
        theme: AppTheme.light,
        routerConfig: ref.watch(routerProvider),
        locale: const Locale('id', 'ID'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
      ),
    );
  }
}
