import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manasakna_business_console/features/product_experience/data/business_product_repository.dart';
import 'package:manasakna_business_console/features/product_experience/presentation/business_admin_page.dart';
import 'package:manasakna_business_console/features/product_experience/presentation/public_home_page.dart';
import 'package:manasakna_business_console/features/product_experience/presentation/traveler_portal_page.dart';

void main() {
  late InMemoryBusinessProductRepository repository;

  setUp(() {
    repository = InMemoryBusinessProductRepository();
  });

  Widget app(Widget home) => MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: home,
        ),
      );

  testWidgets('public home exposes visitor, traveler and business entry points',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 1100));
    await tester.pumpWidget(
      app(
        ManasaknaPublicHomePage(
          repository: repository,
          tenantId: 'synthetic-tenant',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('رحلتك تبدأ بتنظيم أفضل'), findsOneWidget);
    expect(find.text('ابدأ طلب رحلتك'), findsOneWidget);
    expect(find.text('متابعة حجز قائم'), findsOneWidget);
    expect(find.byTooltip('بوابة المسافر'), findsOneWidget);
    expect(find.byTooltip('دخول لوحة الأعمال'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('public home is stable at 390px', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.pumpWidget(
      app(
        ManasaknaPublicHomePage(
          repository: repository,
          tenantId: 'synthetic-tenant',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('رحلتك تبدأ بتنظيم أفضل'), findsOneWidget);
    expect(find.byTooltip('دخول لوحة الأعمال'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('traveler portal renders journey and governed readiness',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.pumpWidget(
      app(
        TravelerPortalPage(
          repository: repository,
          tenantId: 'synthetic-tenant',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('بوابة المسافر'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('مسار الرحلة'),
      220,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('مسار الرحلة'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('الدفعات'),
      260,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('المستندات'), findsWidgets);
    expect(find.text('الدفعات'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('admin surface exposes branding branches and staff',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    await tester.pumpWidget(
      app(
        BusinessAdminPage(
          repository: repository,
          tenantId: 'synthetic-tenant',
          tenantName: 'شركة العمرة التجريبية',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('إدارة مساحة العمل'), findsOneWidget);
    expect(find.text('الهوية وإعدادات المكتب'), findsOneWidget);
    expect(find.text('الفروع'), findsOneWidget);
    expect(find.text('المستخدمون والأدوار'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
