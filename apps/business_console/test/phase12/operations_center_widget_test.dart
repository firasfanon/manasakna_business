import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manasakna_business_console/features/commercial_mvp/presentation/commercial_operations_center.dart';

Widget _testApp() => const MaterialApp(
  home: Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: CommercialOperationsSyntheticOverview(),
      ),
    ),
  ),
);

void main() {
  testWidgets('full synthetic operations page is stable at 390px', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(home: CommercialOperationsSyntheticPage()),
    );
    await tester.pumpAndSettle();

    expect(find.text('مناسكنا للأعمال — بيئة اختبار داخلية'), findsOneWidget);
    expect(find.text('الوحدات التشغيلية'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('productized operations center is stable at 390px', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_testApp());
    await tester.pumpAndSettle();

    expect(find.text('CRM'), findsOneWidget);
    expect(find.text('الحجوزات'), findsWidgets);
    expect(find.text('فتح مساحة الوحدة'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('productized operations center is stable on desktop', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_testApp());
    await tester.pumpAndSettle();

    expect(find.text('الموردون'), findsOneWidget);
    expect(find.text('Journey Context'), findsOneWidget);
    expect(find.text('حالة التكاملات الخارجية'), findsOneWidget);
    expect(find.text('متحقق — غير إنتاجي'), findsOneWidget);
    expect(find.text('مؤجل'), findsNWidgets(4));

    await tester.tap(find.text('فتح مساحة الوحدة').first);
    await tester.pumpAndSettle();
    expect(
      find.text('مساحة تشغيل داخلية غير إنتاجية — بيانات اصطناعية فقط.'),
      findsOneWidget,
    );
    expect(find.text('إضافة سجل تجريبي'), findsOneWidget);

    await tester.tap(find.text('إضافة سجل تجريبي'));
    await tester.pumpAndSettle();
    expect(find.text('سجل اختبار جديد'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
