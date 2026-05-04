import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pruebaflutter/app/bootstrap/bootstrap.dart';

void main() {
  testWidgets('App boots and shows a Material shell', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1080, 2200));

    await tester.pumpWidget(const ProviderScope(child: App()));
    await tester.pumpAndSettle();

    expect(find.byType(ProviderScope), findsOneWidget);
    expect(find.byType(App), findsOneWidget);

    await tester.binding.setSurfaceSize(null);
  });
}
