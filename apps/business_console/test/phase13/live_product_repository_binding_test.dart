import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manasakna_business_console/features/product_experience/data/business_product_repository.dart';
import 'package:manasakna_business_console/features/product_experience/presentation/business_product_shell.dart';

class FakeProductRepository implements BusinessProductRepository {
  int dashboardCalls = 0;
  int customerListCalls = 0;
  Map<String, dynamic>? savedCustomer;

  @override
  Future<Map<String, dynamic>> dashboard(String tenantId) async {
    dashboardCalls++;
    return {'active_bookings': 4, 'outstanding_amount': 1250};
  }

  @override
  Future<List<Map<String, dynamic>>> list(
    String tenantId,
    String resource, {
    int limit = 100,
  }) async {
    if (resource == 'customers') customerListCalls++;
    if (resource == 'customers') {
      return [
        {
          'id': 'customer-1',
          'tenant_id': tenantId,
          'full_name': 'عميل اختبار حي',
          'phone': '0000',
          'status': 'active',
        },
      ];
    }
    return const [];
  }

  @override
  Future<Map<String, dynamic>> saveCustomer(
    String tenantId, {
    String? id,
    required Map<String, dynamic> payload,
  }) async {
    savedCustomer = Map<String, dynamic>.from(payload);
    return {'id': id ?? 'customer-new', ...payload};
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget app(FakeProductRepository repo) => MaterialApp(
  home: MediaQuery(
    data: const MediaQueryData(size: Size(1440, 1000)),
    child: Directionality(
      textDirection: TextDirection.rtl,
      child: BusinessProductShell(
        tenantId: 'tenant-live',
        tenantName: 'مكتب اختبار',
        repository: repo,
      ),
    ),
  ),
);

void main() {
  testWidgets('Phase13 live dashboard is repository-backed', (tester) async {
    final repo = FakeProductRepository();
    await tester.binding.setSurfaceSize(const Size(1440, 1000));
    await tester.pumpWidget(app(repo));
    await tester.pumpAndSettle();

    expect(repo.dashboardCalls, 1);
    expect(find.text('4'), findsOneWidget);
    expect(find.text('1250'), findsOneWidget);
  });
  testWidgets('Phase13 customer form persists through repository', (
    tester,
  ) async {
    final repo = FakeProductRepository();
    await tester.binding.setSurfaceSize(const Size(1440, 1000));
    await tester.pumpWidget(app(repo));
    await tester.pumpAndSettle();

    await tester.tap(find.text('CRM والعملاء'));
    await tester.pumpAndSettle();
    expect(find.text('عميل اختبار حي'), findsOneWidget);

    await tester.tap(find.text('عميل جديد'));
    await tester.pumpAndSettle();
    final fields = find.byType(TextField);
    expect(fields, findsWidgets);
    await tester.enterText(fields.at(1), 'عميل محفوظ');
    await tester.tap(find.text('حفظ'));
    await tester.pumpAndSettle();

    expect(repo.savedCustomer?['full_name'], 'عميل محفوظ');
    expect(repo.savedCustomer?['data_classification'], 'synthetic');
    expect(repo.customerListCalls, greaterThanOrEqualTo(2));
  });
}
