import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mibu/ui/core/widgets/tap_outside_unfocus.dart';

void main() {
  testWidgets(
    'tap outside a field closes the keyboard',
    (tester) async {
      final focus = FocusNode();
      addTearDown(focus.dispose);
      await tester.pumpWidget(
        TapOutsideUnfocus(
          child: MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  TextField(focusNode: focus),
                  const SizedBox(height: 300, child: Text('outside')),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byType(TextField));
      await tester.pump();
      expect(focus.hasFocus, isTrue);

      await tester.tap(find.text('outside'));
      await tester.pump();
      expect(focus.hasFocus, isFalse);
    },
    variant: const TargetPlatformVariant({
      TargetPlatform.iOS,
      TargetPlatform.android,
    }),
  );
}
