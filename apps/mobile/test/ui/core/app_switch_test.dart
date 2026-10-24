import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mibu/ui/core/theme.dart';
import 'package:mibu/ui/core/widgets/app_switch.dart';

void main() {
  testWidgets('tap flips it, and it says what it is for screen readers', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    var on = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: StatefulBuilder(
            builder: (_, setState) => AppSwitch(
              value: on,
              label: 'kunci mibu',
              onChanged: (v) => setState(() => on = v),
            ),
          ),
        ),
      ),
    );
    expect(
      tester.getSemantics(find.byType(AppSwitch)),
      matchesSemantics(
        label: 'kunci mibu',
        hasToggledState: true,
        isToggled: false,
        hasTapAction: true,
      ),
    );

    await tester.tap(find.byType(AppSwitch));
    await tester.pumpAndSettle();
    expect(on, isTrue);
    expect(
      tester.getSemantics(find.byType(AppSwitch)),
      matchesSemantics(
        label: 'kunci mibu',
        hasToggledState: true,
        isToggled: true,
        hasTapAction: true,
      ),
    );

    await tester.tap(find.byType(AppSwitch));
    await tester.pumpAndSettle();
    expect(on, isFalse);
    handle.dispose();
  });
}
