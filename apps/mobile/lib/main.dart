import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;

import 'domain/models/finance.dart';
import 'l10n/app_localizations.dart';
import 'routing/router.dart';
import 'ui/core/clock.dart';
import 'ui/core/dates.dart';
import 'ui/core/finance_providers.dart';
import 'ui/core/money.dart';
import 'ui/features/home/view_models/home_view_model.dart';
import 'ui/core/theme.dart';
import 'ui/core/widgets/app_emoji.dart';
import 'ui/core/widgets/tap_outside_unfocus.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  registerEmojiLicense();
  final container = await bootstrap();
  runApp(
    UncontrolledProviderScope(container: container, child: const MibuApp()),
  );
}

/// Riverpod 3 pauses providers nobody listens to — a bare `read` neither
/// warms them up nor lets `.future` complete — so these listen.
Future<ProviderContainer> bootstrap({
  List<Override> overrides = const [],
}) async {
  final container = ProviderContainer(overrides: overrides);
  // Open (and, in debug, seed) the database and load beranda while the user
  // is still on onboarding, so "mulai" lands on a ready screen.
  container.listen(homeProvider, (_, _) {});
  // The router picks onboarding vs beranda from it (native splash still up).
  container.listen(profileProvider, (_, _) {});
  await container.read(profileProvider.future);
  return container;
}

class MibuApp extends ConsumerStatefulWidget {
  const MibuApp({super.key});

  @override
  ConsumerState<MibuApp> createState() => _MibuAppState();
}

class _MibuAppState extends ConsumerState<MibuApp> {
  late final _lifecycle = AppLifecycleListener(onResume: _refreshNow);

  /// The app can outlive a day (and a period): re-read "now" on resume, only
  /// when the date moved so queries don't re-subscribe for nothing.
  void _refreshNow() {
    final today = dateOnly(ref.read(clockProvider)());
    if (today != dateOnly(ref.read(nowProvider))) ref.invalidate(nowProvider);
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TapOutsideUnfocus(
      child: MaterialApp.router(
        onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
        theme: AppTheme.light,
        routerConfig: ref.watch(routerProvider),
        builder: (_, child) => AmountMask(
          hide:
              ref.watch(profileProvider).value?.hideAmounts ?? HideAmounts.none,
          peek: ref.watch(peekProvider),
          child: child!,
        ),
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
