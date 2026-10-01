import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'l10n/app_localizations.dart';
import 'ui/core/theme.dart';
import 'ui/features/home/view_models/home_view_model.dart';
import 'ui/features/home/views/home_view.dart';

void main() {
  runApp(const MibuApp());
}

class MibuApp extends StatelessWidget {
  const MibuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      theme: AppTheme.light,
      locale: const Locale('id', 'ID'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: HomeView(viewModel: HomeViewModel()),
    );
  }
}
