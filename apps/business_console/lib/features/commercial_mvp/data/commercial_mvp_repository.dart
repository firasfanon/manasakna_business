import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/commercial_mvp_models.dart';

abstract interface class CommercialMvpRepository {
  Future<PipelineSummary> pipelineSummary(String tenantId);
  Future<List<CommercialBookingSummary>> listBookings(String tenantId);
  Future<CommercialJourneyContext> journeyContext({
    required String tenantId,
    required String bookingId,
  });
}

class SupabaseCommercialMvpRepository implements CommercialMvpRepository {
  SupabaseCommercialMvpRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<PipelineSummary> pipelineSummary(String tenantId) async {
    final response = await _client.rpc(
      'rpc_business_pipeline_summary_v1',
      params: {'p_tenant_id': tenantId},
    );
    if (response is! Map) {
      throw const FormatException('INVALID_PIPELINE_SUMMARY_RESPONSE');
    }
    return PipelineSummary.fromJson(
      response.map((key, value) => MapEntry(key.toString(), value)),
    );
  }

  @override
  Future<List<CommercialBookingSummary>> listBookings(String tenantId) async {
    final response = await _client.rpc(
      'rpc_business_list_bookings_v1',
      params: {'p_tenant_id': tenantId},
    );
    if (response is! List) {
      throw const FormatException('INVALID_BOOKING_LIST_RESPONSE');
    }
    return response
        .whereType<Map>()
        .map(
          (item) => CommercialBookingSummary.fromJson(
            item.map((key, value) => MapEntry(key.toString(), value)),
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<CommercialJourneyContext> journeyContext({
    required String tenantId,
    required String bookingId,
  }) async {
    final response = await _client.rpc(
      'rpc_business_umrah_journey_context_v1',
      params: {'p_tenant_id': tenantId, 'p_booking_id': bookingId},
    );
    if (response is! Map) {
      throw const FormatException('INVALID_COMMERCIAL_JOURNEY_CONTEXT');
    }
    final context = CommercialJourneyContext.fromJson(
      response.map((key, value) => MapEntry(key.toString(), value)),
    );
    if (!context.isCommercialUmrah) {
      throw const FormatException('INVALID_COMMERCIAL_UMRAH_AUTHORITY');
    }
    return context;
  }
}
