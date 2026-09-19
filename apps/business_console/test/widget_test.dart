import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manasakna_business_console/app.dart';

void main() {
  testWidgets('unconfigured console fails closed', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: ManasaknaBusinessApp()));

    expect(
      find.text(
        'مناسكنا للأعمال يعمل Fail-Closed.\n'
        'لم يتم ربط مشروع Supabase تجاري بعد.\n'
        'Phase 6 لا يستخدم بيانات حقيقية أو صلاحيات حج سيادية.',
      ),
      findsOneWidget,
    );
  });
}
