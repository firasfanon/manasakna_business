import 'package:manasakna_business_console/features/product_experience/presentation/business_product_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget app(double width) => MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(size: Size(width, 844)),
      child: const Directionality(
        textDirection: TextDirection.rtl,
        child: BusinessProductShell(),
      ),
    ),
  );

  testWidgets('Phase13 desktop exposes operator product navigation', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1440, 1000));
    await tester.pumpWidget(app(1440));
    await tester.pumpAndSettle();
    expect(find.text('لوحة العمليات'), findsOneWidget);
    expect(find.text('CRM والعملاء'), findsOneWidget);
    expect(find.text('الحجوزات'), findsOneWidget);
    expect(find.text('المالية'), findsOneWidget);
    expect(find.text('التقارير'), findsOneWidget);
    expect(find.textContaining('حوكمة'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Phase13 390px uses responsive product shell', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.pumpWidget(app(390));
    await tester.pumpAndSettle();
    expect(find.text('صباح الخير — عمليات اليوم'), findsOneWidget);
    expect(find.text('مناسكنا'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
