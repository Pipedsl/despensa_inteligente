import 'package:despensa_inteligente/app/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('DespensaTheme dark expone el accent #cde600', (tester) async {
    final theme = DespensaTheme.dark();
    expect(theme.colorScheme.primary, DespensaTheme.accent);
    expect(theme.scaffoldBackgroundColor, Colors.black);
  });
}
