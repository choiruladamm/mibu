import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Overridable clock; tests pin it. Read it when you need "now" at that
/// moment (e.g. stamping a saved entry).
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

/// "Now" as of app start, for queries and screens.
// ponytail: not refreshed past midnight; tick it if the app lives that long.
final nowProvider = Provider<DateTime>((ref) => ref.watch(clockProvider)());
