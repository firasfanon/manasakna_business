class PipelineSummary {
  const PipelineSummary({
    required this.leads,
    required this.quotes,
    required this.bookings,
    required this.travelers,
    required this.departures,
    required this.openSupport,
    required this.openTasks,
  });

  final int leads;
  final int quotes;
  final int bookings;
  final int travelers;
  final int departures;
  final int openSupport;
  final int openTasks;

  factory PipelineSummary.empty() => const PipelineSummary(
    leads: 0,
    quotes: 0,
    bookings: 0,
    travelers: 0,
    departures: 0,
    openSupport: 0,
    openTasks: 0,
  );

  factory PipelineSummary.fromJson(Map<String, dynamic> json) {
    int asInt(Object? value) {
      if (value is int) return value;
      return int.tryParse(value?.toString() ?? '') ?? 0;
    }

    return PipelineSummary(
      leads: asInt(json['leads']),
      quotes: asInt(json['quotes']),
      bookings: asInt(json['bookings']),
      travelers: asInt(json['travelers']),
      departures: asInt(json['departures']),
      openSupport: asInt(json['open_support']),
      openTasks: asInt(json['open_tasks']),
    );
  }
}

class CommercialBookingSummary {
  const CommercialBookingSummary({
    required this.id,
    required this.bookingCode,
    required this.status,
    required this.customerName,
    required this.packageName,
    required this.departureStart,
  });

  final String id;
  final String bookingCode;
  final String status;
  final String customerName;
  final String packageName;
  final String departureStart;

  factory CommercialBookingSummary.fromJson(Map<String, dynamic> json) {
    return CommercialBookingSummary(
      id: json['id']?.toString() ?? '',
      bookingCode: json['booking_code']?.toString() ?? '',
      status: json['status']?.toString() ?? 'unknown',
      customerName: json['customer_name']?.toString() ?? '—',
      packageName: json['package_name']?.toString() ?? '—',
      departureStart: json['departure_start']?.toString() ?? '—',
    );
  }
}

class CommercialJourneyContext {
  const CommercialJourneyContext({
    required this.schemaVersion,
    required this.journeyId,
    required this.journeyType,
    required this.sourceAuthority,
    required this.tenantName,
    required this.bookingCode,
    required this.packageName,
    required this.travelerCount,
    required this.flightCount,
    required this.roomLabel,
    required this.freshness,
  });

  final String schemaVersion;
  final String journeyId;
  final String journeyType;
  final String sourceAuthority;
  final String tenantName;
  final String bookingCode;
  final String packageName;
  final int travelerCount;
  final int flightCount;
  final String roomLabel;
  final String freshness;

  bool get isCommercialUmrah =>
      journeyType == 'umrah' &&
      sourceAuthority == 'commercialCompany' &&
      schemaVersion == 'commercial-umrah-journey-context-v1';

  factory CommercialJourneyContext.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> mapOf(Object? value) {
      if (value is Map) {
        return value.map((key, value) => MapEntry(key.toString(), value));
      }
      return const <String, dynamic>{};
    }

    List<dynamic> listOf(Object? value) =>
        value is List ? value : const <dynamic>[];

    final organization = mapOf(json['organization_context']);
    final booking = mapOf(json['booking']);
    final package = mapOf(json['package']);
    final accommodation = mapOf(json['accommodation']);

    return CommercialJourneyContext(
      schemaVersion: json['schema_version']?.toString() ?? '',
      journeyId: json['journey_id']?.toString() ?? '',
      journeyType: json['journey_type']?.toString() ?? '',
      sourceAuthority: json['source_authority']?.toString() ?? '',
      tenantName: organization['tenant_name']?.toString() ?? '—',
      bookingCode: booking['booking_code']?.toString() ?? '—',
      packageName: package['name']?.toString() ?? '—',
      travelerCount: listOf(json['travelers']).length,
      flightCount: listOf(json['flights']).length,
      roomLabel: accommodation['room_label']?.toString() ?? '—',
      freshness: json['freshness']?.toString() ?? 'unknown',
    );
  }
}

enum CommercialModuleState { preproductionReady, syntheticOnly, deferred }

class CommercialModule {
  const CommercialModule(this.label, this.description, {required this.state});

  final String label;
  final String description;
  final CommercialModuleState state;
}

const commercialMvpModules = <CommercialModule>[
  CommercialModule(
    'CRM',
    'العملاء المحتملون وسجل العميل',
    state: CommercialModuleState.syntheticOnly,
  ),
  CommercialModule(
    'العروض',
    'عرض سعر مع لقطة سعر غير قابلة للتغيير',
    state: CommercialModuleState.syntheticOnly,
  ),
  CommercialModule(
    'الحجوزات',
    'الحجز وربط المسافرين',
    state: CommercialModuleState.preproductionReady,
  ),
  CommercialModule(
    'الوثائق والتأشيرة',
    'حالة الوثائق ومسار التأشيرة',
    state: CommercialModuleState.syntheticOnly,
  ),
  CommercialModule(
    'المالية التشغيلية',
    'ذمم وقبض واسترداد دون محاسبة عامة',
    state: CommercialModuleState.syntheticOnly,
  ),
  CommercialModule(
    'البرامج والمغادرات',
    'الباقة والمغادرة والطاقة الاستيعابية',
    state: CommercialModuleState.syntheticOnly,
  ),
  CommercialModule(
    'الإقامة والغرف',
    'الفندق والغرفة والتسكين',
    state: CommercialModuleState.syntheticOnly,
  ),
  CommercialModule(
    'الطيران والنقل',
    'مقاطع الرحلة والنقل الأرضي',
    state: CommercialModuleState.syntheticOnly,
  ),
  CommercialModule(
    'الموردون',
    'عقود ومصاريف تشغيلية',
    state: CommercialModuleState.syntheticOnly,
  ),
  CommercialModule(
    'المجموعات والمشرفون',
    'تجميع الحجز والإشراف',
    state: CommercialModuleState.syntheticOnly,
  ),
  CommercialModule(
    'الدعم',
    'حالات الدعم التشغيلي',
    state: CommercialModuleState.syntheticOnly,
  ),
  CommercialModule(
    'Journey Context',
    'سياق عمرة تجاري موثق المصدر',
    state: CommercialModuleState.preproductionReady,
  ),
];
