import 'package:flutter_test/flutter_test.dart';
import 'package:manasakna_business_console/features/commercial_mvp/domain/commercial_mvp_models.dart';

void main() {
  test('pipeline summary parses numeric values safely', () {
    final summary = PipelineSummary.fromJson({
      'leads': 3,
      'quotes': '2',
      'bookings': 1,
      'travelers': 4,
      'departures': 1,
      'open_support': 2,
      'open_tasks': 5,
    });

    expect(summary.leads, 3);
    expect(summary.quotes, 2);
    expect(summary.bookings, 1);
    expect(summary.openTasks, 5);
  });

  test('commercial journey context preserves Umrah authority boundary', () {
    final context = CommercialJourneyContext.fromJson({
      'schema_version': 'commercial-umrah-journey-context-v1',
      'journey_id': 'booking-1',
      'journey_type': 'umrah',
      'source_authority': 'commercialCompany',
      'organization_context': {'tenant_name': 'شركة تجريبية'},
      'booking': {'booking_code': 'B-001'},
      'package': {'name': 'عمرة تجريبية'},
      'travelers': [
        {'id': 'traveler-1'},
      ],
      'flights': [
        {'flight_number': 'SYN700'},
      ],
      'accommodation': {'room_label': 'SYN-101'},
      'freshness': 'fresh',
    });

    expect(context.isCommercialUmrah, isTrue);
    expect(context.travelerCount, 1);
    expect(context.flightCount, 1);
    expect(context.roomLabel, 'SYN-101');
  });

  test('Hajj authority can never be treated as commercial Umrah context', () {
    final context = CommercialJourneyContext.fromJson({
      'schema_version': 'commercial-umrah-journey-context-v1',
      'journey_id': 'x',
      'journey_type': 'hajj',
      'source_authority': 'government',
    });

    expect(context.isCommercialUmrah, isFalse);
  });

  test('Phase 7 module map covers the governed MVP chain', () {
    final labels = commercialMvpModules.map((item) => item.label).toSet();

    expect(
      labels,
      containsAll(<String>{
        'CRM',
        'العروض',
        'الحجوزات',
        'الوثائق والتأشيرة',
        'المالية التشغيلية',
        'البرامج والمغادرات',
        'الإقامة والغرف',
        'الطيران والنقل',
        'الموردون',
        'المجموعات والمشرفون',
        'الدعم',
        'Journey Context',
      }),
    );
  });
}
