import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../finance_providers.dart';

/// Wraps a hero amount: with "sembunyiin nominal" on, a tap shows every
/// amount until the next navigation (or another tap). No-op otherwise.
class PeekTap extends ConsumerWidget {
  const PeekTap({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: ref.read(peekProvider.notifier).toggle,
    child: child,
  );
}
