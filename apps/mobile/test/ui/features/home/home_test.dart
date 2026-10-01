import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mibu/ui/features/home/view_models/home_view_model.dart';
import 'package:mibu/ui/features/home/views/home_view.dart';

void main() {
  test('HomeViewModel.increment bumps counter and notifies', () {
    final vm = HomeViewModel();
    var notified = 0;
    vm.addListener(() => notified++);

    vm.increment();

    expect(vm.counter, 1);
    expect(notified, 1);
  });

  testWidgets('HomeView renders counter and increments on tap', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: HomeView(viewModel: HomeViewModel())),
    );
    expect(find.text('0'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    expect(find.text('1'), findsOneWidget);
  });
}
