import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'l10n/app_localizations.dart';
import 'routing/router.dart';
import 'ui/core/theme.dart';
import 'ui/core/widgets/tap_outside_unfocus.dart';

void main() {
  runApp(const ProviderScope(child: MibuApp()));
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
