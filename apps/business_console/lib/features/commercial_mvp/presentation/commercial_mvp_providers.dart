import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/commercial_mvp_repository.dart';
import '../domain/commercial_mvp_models.dart';

final commercialMvpRepositoryProvider = Provider<CommercialMvpRepository>((
  ref,
) {
  return SupabaseCommercialMvpRepository(Supabase.instance.client);
});

final commercialPipelineProvider =
    FutureProvider.family<PipelineSummary, String>((ref, tenantId) {
      return ref
          .watch(commercialMvpRepositoryProvider)
          .pipelineSummary(tenantId);
    });

final commercialBookingsProvider =
    FutureProvider.family<List<CommercialBookingSummary>, String>((
      ref,
      tenantId,
    ) {
      return ref.watch(commercialMvpRepositoryProvider).listBookings(tenantId);
    });

typedef JourneyContextRequest = ({String tenantId, String bookingId});

final commercialJourneyContextProvider =
    FutureProvider.family<CommercialJourneyContext, JourneyContextRequest>((
      ref,
      request,
    ) {
      return ref
          .watch(commercialMvpRepositoryProvider)
          .journeyContext(
            tenantId: request.tenantId,
            bookingId: request.bookingId,
          );
    });

final selectedCommercialBookingProvider = StateProvider.family<String?, String>(
  (ref, tenantId) => null,
);
