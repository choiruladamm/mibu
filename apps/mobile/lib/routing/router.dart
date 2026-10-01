import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../ui/features/add_entry/views/add_entry_view.dart';
import '../ui/features/home/views/home_view.dart';
import '../ui/features/onboarding/views/onboarding_view.dart';

abstract final class Routes {
  static const onboarding = '/onboarding';
  static const home = '/';
  static const addEntry = '/catat';
}

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
      GoRoute(path: Routes.home, builder: (_, _) => const HomeView()),
      GoRoute(path: Routes.addEntry, builder: (_, _) => const AddEntryView()),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
