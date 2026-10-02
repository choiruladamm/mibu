import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../ui/core/widgets/tab_bar.dart';
import '../ui/features/add_entry/views/add_entry_view.dart';
import '../ui/features/home/views/home_view.dart';
import '../ui/features/onboarding/views/onboarding_view.dart';
import '../ui/features/pockets/views/pockets_view.dart';
import '../domain/models/finance.dart';
import '../ui/features/transactions/view_models/transactions_view_model.dart';
import '../ui/features/transactions/views/edit_entry_view.dart';
import '../ui/features/transactions/views/transaction_detail_view.dart';
import '../ui/features/transactions/views/transactions_view.dart';

abstract final class Routes {
  static const onboarding = '/onboarding';
  static const home = '/';
  static const pockets = '/kantong';
  static String pocketsAt(String id) => '$pockets?pocket=$id';
  static const addEntry = '/catat';
  static const transactions = '/transaksi';
  static String transactionsIn(DateTime month) =>
      '$transactions?month=${month.year}-${month.month.toString().padLeft(2, '0')}';
  static String transaction(String id) => '$transactions/$id';
  static String editEntry(String id) => '$transactions/$id/edit';
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

DateTime? _monthParam(String? s) {
  final m = RegExp(r'^(\d{4})-(\d{2})$').firstMatch(s ?? '');
  if (m == null) return null;
  return DateTime(int.parse(m[1]!), int.parse(m[2]!));
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
      _tab(Routes.home, const HomeView()),
      GoRoute(
        path: Routes.pockets,
        pageBuilder: (_, state) => NoTransitionPage(
          key: state.pageKey,
          // ?pocket=<id> from 02.1 pills; unknown id falls back to default.
          child: PocketsView(initial: state.uri.queryParameters['pocket']),
        ),
      ),
      GoRoute(
        path: Routes.addEntry,
        // extra: an entry to "catat lagi" from (04.3).
        builder: (_, state) => AddEntryView(again: state.extra as Transaction?),
      ),
      GoRoute(
        path: Routes.transactions,
        builder: (context, state) => ProviderScope(
          // ?month=2026-09 from 02.1 "liat semua di september".
          overrides: [
            txMonthProvider.overrideWith(
              () => TxMonth(_monthParam(state.uri.queryParameters['month'])),
            ),
          ],
          child: TransactionsView(
            onOpen: (t) => context.push(Routes.transaction(t.id)),
          ),
        ),
        routes: [
          GoRoute(
            path: ':id',
            builder: (_, state) =>
                TransactionDetailView(id: state.pathParameters['id']!),
            routes: [
              GoRoute(
                path: 'edit',
                builder: (_, state) =>
                    EditEntryView(id: state.pathParameters['id']!),
              ),
            ],
          ),
        ],
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
