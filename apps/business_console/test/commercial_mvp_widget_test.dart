import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manasakna_business_console/features/commercial_mvp/presentation/commercial_mvp_page.dart';

Widget testApp() {
  return const MaterialApp(
    home: Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: CommercialMvpOverviewPreview(),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('Phase 7 preview is stable on narrow RTL viewport', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(testApp());
    await tester.pumpAndSettle();

    expect(find.text('CRM'), findsOneWidget);
    expect(find.text('Journey Context'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Phase 7 preview is stable on desktop RTL viewport', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(testApp());
    await tester.pumpAndSettle();

    expect(find.text('الحجوزات'), findsWidgets);
    expect(find.text('الموردون'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
