import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Fase 0 siklus gajian: period copy ("bulan ini") lives in app_id.arb only,
/// so a payday-cycle mode can change it in one place. Comments are fine.
void main() {
  test('no "bulan ini" string literal in lib/ui', () {
    final offenders = [
      for (final f in Directory('lib/ui').listSync(recursive: true))
        if (f is File && f.path.endsWith('.dart'))
          for (final (i, line) in f.readAsLinesSync().indexed)
            if (!line.trimLeft().startsWith('//') &&
                RegExp(r'''['"][^'"]*bulan ini''').hasMatch(line))
              '${f.path}:${i + 1}',
    ];
    expect(offenders, isEmpty, reason: 'move these strings to app_id.arb');
  });
}
