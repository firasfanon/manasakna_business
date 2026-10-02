enum UmrahOfficeStage {
  lead,
  quote,
  approved,
  booking,
  travelers,
  documents,
  visa,
  program,
  accommodation,
  air,
  transport,
  payments,
  departureReadiness,
  departed,
  inTrip,
  returned,
  closed,
}

class UmrahOfficeWorkflow {
  const UmrahOfficeWorkflow(this.stage);
  final UmrahOfficeStage stage;

  static const ordered = UmrahOfficeStage.values;

  UmrahOfficeStage? get next {
    final index = ordered.indexOf(stage);
    return index < ordered.length - 1 ? ordered[index + 1] : null;
  }

  bool canAdvanceTo(UmrahOfficeStage target) => target == next;

  UmrahOfficeWorkflow advance(UmrahOfficeStage target) {
    if (!canAdvanceTo(target)) {
      throw StateError('INVALID_UMRAH_WORKFLOW_TRANSITION');
    }
    return UmrahOfficeWorkflow(target);
  }

  bool get isClosed => stage == UmrahOfficeStage.closed;
}
