import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../ui/core/widgets/tab_bar.dart';
import '../ui/features/add_entry/views/add_entry_view.dart';
import '../ui/features/home/views/home_view.dart';
import '../ui/features/onboarding/views/onboarding_view.dart';
import '../ui/features/pockets/views/pockets_view.dart';
import '../ui/features/transactions/views/transactions_view.dart';

abstract final class Routes {
  static const onboarding = '/onboarding';
  static const home = '/';
  static const pockets = '/kantong';
  static const addEntry = '/catat';
  static const transactions = '/transaksi';
}

/// Tab bar → tab route. Stats / settings land in M6.
// ponytail: plain go() between tabs (state resets); StatefulShellRoute in M5.
void goTab(BuildContext context, AppTab tab) {
  final path = switch (tab) {
    AppTab.home => Routes.home,
    AppTab.pockets => Routes.pockets,
    AppTab.stats || AppTab.settings => null,
  };
  if (path != null) context.go(path);
}

/// Tabs swap in place, no slide.
GoRoute _tab(String path, Widget child) => GoRoute(
  path: path,
  pageBuilder: (_, state) => NoTransitionPage(key: state.pageKey, child: child),
);

final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    // ponytail: always starts at onboarding; redirect on a "seen onboarding"
    // flag once login (01.2) exists.
    initialLocation: Routes.onboarding,
    routes: [
      GoRoute(
        path: Routes.onboarding,
        // TODO: onDone → 01.2 masuk once login is sliced.
        builder: (context, _) =>
            OnboardingView(onDone: () => context.go(Routes.home)),
      ),
      _tab(Routes.home, const HomeView()),
      _tab(Routes.pockets, const PocketsView()),
      GoRoute(path: Routes.addEntry, builder: (_, _) => const AddEntryView()),
      GoRoute(
        path: Routes.transactions,
        builder: (_, _) => const TransactionsView(),
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
