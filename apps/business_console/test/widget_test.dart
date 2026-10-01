import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manasakna_business_console/app.dart';

void main() {
  testWidgets('unconfigured console fails closed', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: ManasaknaBusinessApp()));

    expect(find.textContaining('مناسكنا للأعمال يعمل Fail-Closed.'), findsOneWidget);
    expect(find.textContaining('لم يتم ربط مشروع Supabase تجاري بعد.'), findsOneWidget);
    expect(
      find.textContaining('لا توجد بيانات حقيقية أو صلاحيات حج سيادية.'),
      findsOneWidget,
    );
  });
}
