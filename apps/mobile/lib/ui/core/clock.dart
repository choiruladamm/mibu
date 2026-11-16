import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Overridable clock; tests pin it. Read it when you need "now" at that
/// moment (e.g. stamping a saved entry).
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

/// Current day for queries and screens; refresh at midnight and on resume.
final nowProvider = Provider<DateTime>((ref) {
  final now = ref.watch(clockProvider)();
  final midnight = DateTime(now.year, now.month, now.day + 1);
  final timer = Timer(midnight.difference(now), ref.invalidateSelf);
  ref.onDispose(timer.cancel);
  return now;
});
