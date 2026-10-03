import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../ui/core/finance_providers.dart';
import '../ui/core/tokens.dart';
import '../ui/core/widgets/tab_bar.dart';
import '../ui/features/add_entry/views/add_entry_view.dart';
import '../ui/features/home/views/home_view.dart';
import '../ui/features/onboarding/views/onboarding_view.dart';
import '../ui/features/pockets/views/pockets_view.dart';
import '../ui/features/settings/views/settings_view.dart';
import '../ui/features/search/views/search_view.dart';
import '../ui/features/setup/views/setup_view.dart';
import '../ui/features/stats/views/stats_view.dart';
import '../domain/models/finance.dart';
import '../ui/features/transactions/view_models/transactions_view_model.dart';
import '../ui/features/transactions/views/edit_entry_view.dart';
import '../ui/features/transactions/views/transaction_detail_view.dart';
import '../ui/features/transactions/views/transactions_view.dart';

/// How /catat opens when it isn't blank.
enum AddEntryStart { salary }

abstract final class Routes {
  static const onboarding = '/onboarding';
  static const setup = '/atur-awal';
  static const home = '/';
  static const pockets = '/kantong';
  static String pocketsAt(String id) => '$pockets?pocket=$id';
  static const stats = '/statistik';
  static const settings = '/pengaturan';
  static const search = '/cari';
  static String searchIn(DateTime month, {String? q}) => Uri(
    path: search,
    queryParameters: {
      'month': '${month.year}-${month.month.toString().padLeft(2, '0')}',
      'q': ?q,
    },
  ).toString();

  /// 04.2 on this month, opened by tapping a tag chip on a TxRow (00.4b).
  static String searchFor(String q) =>
      Uri(path: search, queryParameters: {'q': q}).toString();
  static const addEntry = '/catat';
  static const transactions = '/transaksi';
  static String transactionsIn(DateTime month) =>
      '$transactions?month=${month.year}-${month.month.toString().padLeft(2, '0')}';

  /// 04.2 "liat N lagi": 04.1 in [month] narrowed to the search.
  static String transactionsFound(
    DateTime month,
    String q, {
    TxFilter filter = TxFilter.all,
    int? day,
  }) => Uri(
    path: transactions,
    queryParameters: {
      'month': '${month.year}-${month.month.toString().padLeft(2, '0')}',
      'q': q,
      if (filter != TxFilter.all) 'filter': filter.name,
      'day': ?day?.toString(),
    },
  ).toString();
  static String transaction(String id) => '$transactions/$id';
  static String editEntry(String id) => '$transactions/$id/edit';
}

/// Tab bar → tab route.
// ponytail: plain go() between tabs (state resets); StatefulShellRoute in M5.
void goTab(BuildContext context, AppTab tab) {
  final path = switch (tab) {
    AppTab.home => Routes.home,
    AppTab.pockets => Routes.pockets,
    AppTab.settings => Routes.settings,
    AppTab.stats => Routes.stats,
  };
  context.go(path);
}

/// `extra` for [Routes.home] when arriving from onboarding: fade in.
const _fadeIn = 'fade-in';

DateTime? _monthParam(String? s) {
  final m = RegExp(r'^(\d{4})-(\d{2})$').firstMatch(s ?? '');
  if (m == null) return null;
  return DateTime(int.parse(m[1]!), int.parse(m[2]!));
}

final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    // First run until 01.4 atur awal is done; main() loads the profile
    // before the router exists.
    initialLocation: ref.read(profileProvider).value?.onboarded ?? false
        ? Routes.home
        : Routes.onboarding,
    routes: [
      GoRoute(
        path: Routes.onboarding,
        // TODO: onDone → 01.2 masuk once login is sliced.
        builder: (context, _) =>
            OnboardingView(onDone: () => context.go(Routes.setup)),
      ),
      GoRoute(
        path: Routes.setup,
        builder: (context, _) =>
            SetupView(onDone: () => context.go(Routes.home, extra: _fadeIn)),
      ),
      GoRoute(
        path: Routes.home,
        // Tabs swap in place, no slide; only the arrival from onboarding fades.
        pageBuilder: (_, state) => state.extra == _fadeIn
            ? CustomTransitionPage(
                key: state.pageKey,
                transitionDuration: AppMotion.sheet,
                transitionsBuilder: (_, animation, _, child) =>
                    FadeTransition(opacity: animation, child: child),
                child: const HomeView(),
              )
            : NoTransitionPage(key: state.pageKey, child: const HomeView()),
      ),
      GoRoute(
        path: Routes.pockets,
        pageBuilder: (_, state) => NoTransitionPage(
          key: state.pageKey,
          // ?pocket=<id> from 02.1 pills; unknown id falls back to default.
          child: PocketsView(initial: state.uri.queryParameters['pocket']),
        ),
      ),
      GoRoute(
        path: Routes.stats,
        pageBuilder: (_, state) =>
            NoTransitionPage(key: state.pageKey, child: const StatsView()),
      ),
      GoRoute(
        path: Routes.settings,
        pageBuilder: (_, state) =>
            NoTransitionPage(key: state.pageKey, child: const SettingsView()),
      ),
      GoRoute(
        path: Routes.search,
        // ?month=2026-09 from 04.1: search the month being viewed.
        // &q=%23kantor from a TxRow tag chip: opens already searched.
        builder: (_, state) => SearchView(
          month: _monthParam(state.uri.queryParameters['month']),
          initialQuery: state.uri.queryParameters['q'],
        ),
      ),
      GoRoute(
        path: Routes.addEntry,
        // extra: an entry to "catat lagi" from (04.3), or
        // [AddEntryStart.salary] from the beranda chip.
        builder: (_, state) => AddEntryView(
          again: state.extra is Transaction ? state.extra as Transaction : null,
          salary: state.extra == AddEntryStart.salary,
        ),
      ),
      GoRoute(
        path: Routes.transactions,
        builder: (context, state) => ProviderScope(
          // ?month=2026-09 from 02.1 "liat semua di september";
          // &q=kopi&filter=expenses&day=13 from 04.2 "liat N lagi".
          overrides: [
            txMonthProvider.overrideWith(
              () => TxMonth(_monthParam(state.uri.queryParameters['month'])),
            ),
            txFilterProvider.overrideWith(
              () => TxFilterNotifier(
                TxFilter.values
                        .asNameMap()[state.uri.queryParameters['filter']] ??
                    TxFilter.all,
              ),
            ),
            if (state.uri.queryParameters['q'] case final q?)
              txSearchProvider.overrideWithValue((
                q: q,
                day: int.tryParse(state.uri.queryParameters['day'] ?? ''),
              )),
          ],
          child: TransactionsView(
            onOpen: (t) => context.push(Routes.transaction(t.id)),
            onSearch: (m) => context.push(Routes.searchIn(m)),
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
  // Peeking at hidden amounts ends on any navigation.
  // The delegate also notifies while the first frame builds, where a provider
  // can't change: only act when peeking, and after the build.
  void endPeek() {
    if (ref.read(peekProvider)) {
      Future.microtask(ref.read(peekProvider.notifier).reset);
    }
  }

  router.routerDelegate.addListener(endPeek);
  ref.onDispose(() {
    router.routerDelegate.removeListener(endPeek);
    router.dispose();
  });
  return router;
});
