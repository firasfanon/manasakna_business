import 'package:flutter_test/flutter_test.dart';
import 'package:manasakna_business_console/features/product_experience/domain/umrah_office_workflow.dart';

void main() {
  test('Umrah office workflow covers the full Phase13 operational chain', () {
    var workflow = const UmrahOfficeWorkflow(UmrahOfficeStage.lead);
    for (final target in UmrahOfficeStage.values.skip(1)) {
      expect(workflow.canAdvanceTo(target), isTrue);
      workflow = workflow.advance(target);
    }
    expect(workflow.isClosed, isTrue);
  });

  test('Umrah workflow fails closed on skipped or backward transition', () {
    const workflow = UmrahOfficeWorkflow(UmrahOfficeStage.quote);
    expect(
      () => workflow.advance(UmrahOfficeStage.booking),
      throwsA(isA<StateError>()),
    );
    expect(
      () => workflow.advance(UmrahOfficeStage.lead),
      throwsA(isA<StateError>()),
    );
  });

  test('closed workflow cannot advance', () {
    const workflow = UmrahOfficeWorkflow(UmrahOfficeStage.closed);
    expect(workflow.next, isNull);
    expect(
      () => workflow.advance(UmrahOfficeStage.lead),
      throwsA(isA<StateError>()),
    );
  });
}
